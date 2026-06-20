use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use JSON::PP ();
use Text::CSV ();

use GitCommitReport::Formatter qw(format_report);

my $report = {
    meta => {
        repository => 'example-project',
        branch     => 'main',
        since      => '2026-01-01',
        until      => '2026-01-31',
        top        => 10,
    },
    summary => {
        total_commits => 128,
        total_authors  => 6,
        files_changed  => 342,
        insertions     => 12450,
        deletions      => 7820,
    },
    by_author => [
        { author => 'Alice', count => 42 },
        { author => 'Bob',   count => 31 },
    ],
    by_date => [
        { period => '2026-01-01', count => 5 },
    ],
    by_directory => [
        { directory => 'src',  count => 156 },
        { directory => '.',    count => 4 },
    ],
    by_extension => [
        { extension => 'pm',       count => 90 },
        { extension => '(no ext)', count => 3 },
    ],
    largest_commits => [
        { short => 'a1b2c3d', author => 'Alice', files_changed => 48, subject => 'Refactor parser module',
          hash => 'a1b2c3d' x 6, date => '2026-01-05T10:00:00-08:00', insertions => 100, deletions => 50 },
    ],
    risky_commits => [
        { short => 'a1b2c3d', author => 'Alice', files_changed => 48, subject => 'Refactor parser module',
          hash => 'a1b2c3d' x 6, date => '2026-01-05T10:00:00-08:00', insertions => 100, deletions => 50 },
    ],
    most_frequent_files => [
        { path => 'src/parser.pm', count => 12 },
    ],
    commit_types => {
        feature => 20, bugfix => 28, refactor => 17, test => 22,
        documentation => 9, build => 6, other => 11,
    },
};

subtest 'to_text' => sub {
    my $text = format_report($report, 'text');
    like($text, qr/Total commits:\s+128/, 'summary total commits rendered');
    like($text, qr/Lines added:\s+12,450/, 'numbers comma-formatted');
    like($text, qr/Alice\s+42 commits/, 'author row rendered');
    like($text, qr/Bug Fix:\s+28/, 'classification label "Bug Fix" rendered, not internal key "bugfix"');
    like($text, qr/1\. a1b2c3d\s+Alice\s+48 files changed\s+Refactor parser module/, 'largest commit numbered');
    like($text, qr/^a1b2c3d\s+Alice\s+48 files changed\s+Refactor parser module/m, 'risky commit rendered without numbering');
};

subtest 'to_markdown' => sub {
    my $md = format_report($report, 'markdown');
    like($md, qr/^# Git Commit Activity Report/m, 'h1 header present');
    like($md, qr/\| Alice \| 42 \|/, 'author table row rendered');
    like($md, qr/## Commit Type Summary/, 'commit type summary section present');
    like($md, qr/\| Bug Fix \| 28 \|/, 'bugfix rendered with display label');
};

subtest 'to_json round-trips and projects ranked commits' => sub {
    my $json_text = format_report($report, 'json');
    my $decoded = JSON::PP::decode_json($json_text);
    is($decoded->{summary}{total_commits}, 128, 'summary preserved');
    is($decoded->{by_author}[0]{author}, 'Alice', 'by_author preserved');
    my $largest = $decoded->{largest_commits}[0];
    is($largest->{short}, 'a1b2c3d', 'largest commit short hash preserved');
    is($largest->{files_changed}, 48, 'largest commit files_changed preserved');
    ok(!exists $largest->{files}, 'per-file diff array is not dumped into JSON projection');
};

subtest 'to_csv produces parseable sections' => sub {
    my $csv_text = format_report($report, 'csv');
    my $csv = Text::CSV->new({ binary => 1 });
    open(my $fh, '<', \$csv_text) or die $!;
    my @rows;
    while (my $row = $csv->getline($fh)) {
        push @rows, $row;
    }
    close($fh);

    my @section_markers = grep { $_->[0] && $_->[0] eq '# Section' } @rows;
    my @section_names = map { $_->[1] } @section_markers;
    is_deeply(\@section_names, [
        'Summary', 'Commit Type Summary', 'Commits by Author', 'Commits by Date',
        'Top Changed Directories', 'Files by Extension', 'Largest Commits',
        'Risky Commits', 'Most Frequently Changed Files',
    ], 'all expected sections present in order');

    my ($alice_row) = grep { $_->[0] && $_->[0] eq 'Alice' } @rows;
    is($alice_row->[1], 42, 'Alice row has raw unformatted count');
};

done_testing();
