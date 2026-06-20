use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use GitCommitReport::Analyzer qw(analyze);
use GitCommitReport::Utils qw(default_classification);

sub make_commit {
    my (%args) = @_;
    my @files = @{ $args{files} || [] };
    my ($insertions, $deletions) = (0, 0);
    for my $file (@files) {
        $insertions += $file->{added}   // 0;
        $deletions  += $file->{deleted} // 0;
    }
    return {
        hash          => $args{hash}    || 'x' x 40,
        short         => $args{short}   || 'xxxxxxx',
        author        => $args{author}  || 'Alice',
        email         => $args{email}   || 'alice@example.com',
        date          => $args{date}    || '2026-01-15T10:00:00-08:00',
        subject       => $args{subject} || 'Some commit',
        files         => \@files,
        files_changed => scalar @files,
        insertions    => $insertions,
        deletions     => $deletions,
    };
}

my @commits = (
    make_commit(author => 'Alice', subject => 'Add new login feature',
        files => [ { path => 'src/auth.pm', added => 10, deleted => 2 } ]),
    make_commit(author => 'Alice', subject => 'Fix login bug',
        files => [ { path => 'src/auth.pm', added => 1, deleted => 1 }, { path => 'src/utils.pm', added => 2, deleted => 0 } ]),
    make_commit(author => 'Bob', subject => 'Refactor parser module',
        files => [ map { { path => "src/file$_.pm", added => 1, deleted => 0 } } (1 .. 30) ]),
    make_commit(author => 'Bob', subject => 'Improve unit test coverage',
        files => [ { path => 't/parser.t', added => 20, deleted => 0 } ]),
    make_commit(author => 'Carol', subject => 'Update README docs',
        files => [ { path => 'README.md', added => 5, deleted => 1 } ]),
    make_commit(author => 'Carol', subject => 'Bump build version',
        files => [ { path => 'Makefile.PL', added => 1, deleted => 1 } ]),
    make_commit(author => 'Carol', subject => 'Tidy up whitespace',
        files => [ { path => 'src/auth.pm', added => 0, deleted => 0 } ]),
);

my $classification = default_classification();
my $report = analyze(\@commits, top => 3, risky_threshold => 25, classification => $classification);

subtest 'summary_stats' => sub {
    is($report->{summary}{total_commits}, 7, 'total commits counted');
    is($report->{summary}{total_authors}, 3, 'distinct authors counted');
};

subtest 'commits_by_author' => sub {
    my %counts = map { $_->{author} => $_->{count} } @{ $report->{by_author} };
    is($counts{Alice}, 2, 'Alice has 2 commits');
    is($counts{Bob},   2, 'Bob has 2 commits');
    is($counts{Carol}, 3, 'Carol has 3 commits');
    is($report->{by_author}[0]{author}, 'Carol', 'sorted desc by count, Carol first');
};

subtest 'files_by_directory' => sub {
    my %counts = map { $_->{directory} => $_->{count} } @{ $report->{by_directory} };
    is($counts{src}, 34, 'src directory aggregated across commits');
    is($counts{t}, 1, 't directory counted');
    is($counts{'.'}, 2, 'root-level files counted under "."');
};

subtest 'largest_commits respects top' => sub {
    is(scalar @{ $report->{largest_commits} }, 3, 'truncated to top 3');
    is($report->{largest_commits}[0]{author}, 'Bob', 'largest commit (30 files) is Bob\'s refactor');
};

subtest 'risky_commits boundary semantics' => sub {
    my $exact = analyze(\@commits, top => 10, risky_threshold => 30, classification => $classification);
    is(scalar @{ $exact->{risky_commits} }, 0, 'commit with files_changed == threshold is not risky');

    my $over = analyze(\@commits, top => 10, risky_threshold => 29, classification => $classification);
    is(scalar @{ $over->{risky_commits} }, 1, 'commit with files_changed > threshold is risky');
    is($over->{risky_commits}[0]{author}, 'Bob', 'Bob\'s 30-file commit flagged as risky');
};

subtest 'classify_commits' => sub {
    my $types = $report->{commit_types};
    is($types->{feature}, 1, 'one feature commit ("Add new login feature")');
    is($types->{bugfix}, 1, 'one bugfix commit ("Fix login bug")');
    is($types->{refactor}, 1, 'one refactor commit');
    is($types->{test}, 1, 'one test commit (multi-word "unit test" keyword)');
    is($types->{documentation}, 1, 'one documentation commit');
    is($types->{build}, 1, 'one build commit');
    is($types->{other}, 1, 'one uncategorized commit ("Tidy up whitespace")');
};

subtest 'most_frequent_files' => sub {
    my ($top_file) = @{ $report->{most_frequent_files} };
    is($top_file->{path}, 'src/auth.pm', 'src/auth.pm changed most often');
    is($top_file->{count}, 3, 'changed in 3 commits');
};

done_testing();
