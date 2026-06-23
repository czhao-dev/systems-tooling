use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use GitCommitReport::Parser;

my $FS = "\x1f";

sub fixture {
    my (@lines) = @_;
    my $text = join("\n", @lines) . "\n";
    open(my $fh, '<', \$text) or die "Failed to open fixture: $!\n";
    return $fh;
}

subtest 'normal commit with multiple files' => sub {
    my $fh = fixture(
        'COMMIT_START',
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa${FS}Alice${FS}alice\@example.com${FS}2026-01-15T10:22:03-08:00${FS}Add new feature",
        "12\t4\tsrc/parser.pm",
        "3\t0\tsrc/utils.pm",
        '',
    );
    my $commits = GitCommitReport::Parser::_run_and_parse($fh);
    is(scalar @$commits, 1, 'one commit parsed');
    my $c = $commits->[0];
    is($c->{hash}, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'hash parsed');
    is($c->{short}, 'aaaaaaa', 'short hash derived');
    is($c->{author}, 'Alice', 'author parsed');
    is($c->{email}, 'alice@example.com', 'email parsed');
    is($c->{subject}, 'Add new feature', 'subject parsed');
    is($c->{files_changed}, 2, 'files_changed counted');
    is($c->{insertions}, 15, 'insertions summed');
    is($c->{deletions}, 4, 'deletions summed');
    is($c->{files}[0]{path}, 'src/parser.pm', 'first file path');
    is($c->{files}[1]{path}, 'src/utils.pm', 'second file path');
};

subtest 'binary file' => sub {
    my $fh = fixture(
        'COMMIT_START',
        "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb${FS}Bob${FS}bob\@example.com${FS}2026-01-16T09:00:00-08:00${FS}Add logo",
        "-\t-\tassets/logo.png",
        '',
    );
    my $commits = GitCommitReport::Parser::_run_and_parse($fh);
    my $file = $commits->[0]{files}[0];
    is($file->{path}, 'assets/logo.png', 'binary file path parsed');
    is($file->{is_binary}, 1, 'flagged as binary');
    is($file->{added}, undef, 'added is undef for binary');
    is($file->{deleted}, undef, 'deleted is undef for binary');
    is($commits->[0]{insertions}, 0, 'binary file excluded from insertions sum');
};

subtest 'rename with common-prefix brace syntax' => sub {
    my $fh = fixture(
        'COMMIT_START',
        "cccccccccccccccccccccccccccccccccccccccc${FS}Carol${FS}carol\@example.com${FS}2026-01-17T09:00:00-08:00${FS}Rename file",
        "1\t0\tsrc/sub/{file.txt => renamed.txt}",
        '',
    );
    my $commits = GitCommitReport::Parser::_run_and_parse($fh);
    is($commits->[0]{files}[0]{path}, 'src/sub/renamed.txt', 'rename with brace syntax resolved to new path');
};

subtest 'rename across directories with brace syntax' => sub {
    my $fh = fixture(
        'COMMIT_START',
        "dddddddddddddddddddddddddddddddddddddddd${FS}Dave${FS}dave\@example.com${FS}2026-01-18T09:00:00-08:00${FS}Move file",
        "0\t0\t{src/sub => other}/renamed.txt",
        '',
    );
    my $commits = GitCommitReport::Parser::_run_and_parse($fh);
    is($commits->[0]{files}[0]{path}, 'other/renamed.txt', 'rename across dirs resolved to new path');
};

subtest 'rename with no common prefix' => sub {
    my $fh = fixture(
        'COMMIT_START',
        "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee${FS}Eve${FS}eve\@example.com${FS}2026-01-19T09:00:00-08:00${FS}Rename top-level file",
        "0\t0\tf.txt => g.md",
        '',
    );
    my $commits = GitCommitReport::Parser::_run_and_parse($fh);
    is($commits->[0]{files}[0]{path}, 'g.md', 'plain rename resolved to new path');
};

subtest 'merge commit with zero files' => sub {
    my $fh = fixture(
        'COMMIT_START',
        "ffffffffffffffffffffffffffffffffffffffff${FS}Frank${FS}frank\@example.com${FS}2026-01-20T09:00:00-08:00${FS}Merge branch 'feature'",
        'COMMIT_START',
        "1111111111111111111111111111111111111111${FS}Grace${FS}grace\@example.com${FS}2026-01-21T09:00:00-08:00${FS}Normal commit",
        "5\t2\tREADME.md",
        '',
    );
    my $commits = GitCommitReport::Parser::_run_and_parse($fh);
    is(scalar @$commits, 2, 'both commits parsed despite no blank line after merge commit');
    is($commits->[0]{files_changed}, 0, 'merge commit has zero files');
    is($commits->[1]{files_changed}, 1, 'subsequent commit parsed correctly');
};

subtest 'preflight checks against the real repo' => sub {
    ok(GitCommitReport::Parser::_check_git_available(), 'git is available in PATH');
    ok(GitCommitReport::Parser::_check_is_git_repo(), 'this directory is a git repository');
};

done_testing();
