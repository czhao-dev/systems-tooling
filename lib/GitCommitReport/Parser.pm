package GitCommitReport::Parser;

use strict;
use warnings;

use Exporter qw(import);
use Time::Piece;

our @EXPORT_OK = qw(parse_commits);

my $FS = "\x1f";

sub parse_commits {
    my %args = @_;

    _check_git_available();
    _check_is_git_repo();

    my @cmd = _build_git_cmd(%args);
    open(my $fh, '-|', @cmd) or die "Failed to run git log: $!\n";
    my $commits = _run_and_parse($fh);
    close($fh);
    if ($? != 0) {
        die "git log failed (possibly invalid --branch, --since, or --until value)\n";
    }

    return $commits;
}

sub _check_git_available {
    open(my $fh, '-|', 'git', '--version') or die "git executable not found in PATH\n";
    my $out = do { local $/; <$fh> };
    close($fh);
    die "git executable not found in PATH\n" if $? != 0;
    return 1;
}

sub _check_is_git_repo {
    open(my $fh, '-|', 'git', 'rev-parse', '--is-inside-work-tree') or die "Not a git repository (or any of the parent directories)\n";
    my $out = do { local $/; <$fh> };
    close($fh);
    die "Not a git repository (or any of the parent directories)\n" if $? != 0;
    return 1;
}

sub _build_git_cmd {
    my %args = @_;

    my @cmd = ('git', 'log');
    push @cmd, $args{branch} if defined $args{branch};
    push @cmd, "--since=$args{since}" if defined $args{since};
    push @cmd, "--until=$args{until}" if defined $args{until};
    push @cmd, "--author=$args{author}" if defined $args{author};
    push @cmd, '--numstat', "--pretty=format:COMMIT_START%n%H${FS}%an${FS}%ae${FS}%aI${FS}%s";
    if (defined $args{path}) {
        push @cmd, '--', $args{path};
    }

    return @cmd;
}

# Parses the line-oriented output of the git log command built by
# _build_git_cmd. Kept separate from parse_commits so tests can feed
# this a fixture filehandle without shelling out to git.
sub _run_and_parse {
    my ($fh) = @_;

    my @commits;
    my $current;
    my $state = 'NONE'; # NONE | EXPECT_META | IN_FILES

    while (my $line = <$fh>) {
        chomp $line;

        if ($line eq 'COMMIT_START') {
            push @commits, _finalize_commit($current) if $current;
            $current = { files => [] };
            $state = 'EXPECT_META';
            next;
        }

        if ($state eq 'EXPECT_META') {
            if ($line eq '') {
                next; # tolerate stray blank lines before metadata
            }
            my ($hash, $author, $email, $date, $subject) = split(/\Q$FS\E/, $line, 5);
            $current->{hash}    = $hash;
            $current->{author}  = $author;
            $current->{email}   = $email;
            $current->{date}    = $date;
            $current->{subject} = $subject;
            $state = 'IN_FILES';
            next;
        }

        if ($state eq 'IN_FILES') {
            next if $line eq ''; # separator blank line
            my $file = _parse_numstat_line($line);
            push @{ $current->{files} }, $file if $file;
            next;
        }
    }

    push @commits, _finalize_commit($current) if $current;

    return \@commits;
}

sub _finalize_commit {
    my ($commit) = @_;

    my $insertions = 0;
    my $deletions  = 0;
    for my $file (@{ $commit->{files} }) {
        $insertions += $file->{added}   // 0;
        $deletions  += $file->{deleted} // 0;
    }

    $commit->{short}         = substr($commit->{hash}, 0, 7);
    $commit->{files_changed} = scalar @{ $commit->{files} };
    $commit->{insertions}    = $insertions;
    $commit->{deletions}     = $deletions;
    (my $date_for_epoch = $commit->{date} // '') =~ s/([+-]\d{2}):(\d{2})$/$1$2/;
    $commit->{epoch}         = eval { Time::Piece->strptime($date_for_epoch, '%Y-%m-%dT%T%z')->epoch };

    return $commit;
}

# Parses a single --numstat line: "added\tdeleted\tpath".
# Handles binary files ('-') and both rename syntaxes.
sub _parse_numstat_line {
    my ($line) = @_;

    my ($added, $deleted, $path) = split(/\t/, $line, 3);
    return undef unless defined $path;

    my $is_binary = 0;
    if ($added eq '-' || $deleted eq '-') {
        $is_binary = 1;
        $added = undef;
        $deleted = undef;
    }

    my $resolved_path = _resolve_rename_path($path);

    return {
        path      => $resolved_path,
        added     => $is_binary ? undef : $added + 0,
        deleted   => $is_binary ? undef : $deleted + 0,
        is_binary => $is_binary,
    };
}

# Resolves git's rename notation to the new path:
#   "src/sub/{file.txt => renamed.txt}"  -> "src/sub/renamed.txt"
#   "{src/sub => other}/renamed.txt"     -> "other/renamed.txt"
#   "f.txt => g.md"                      -> "g.md"
sub _resolve_rename_path {
    my ($path) = @_;

    if ($path =~ /^(.*)\{(.*) => (.*)\}(.*)$/) {
        my ($prefix, $old, $new, $suffix) = ($1, $2, $3, $4);
        return "$prefix$new$suffix";
    }
    if ($path =~ /^(.*) => (.*)$/) {
        return $2;
    }
    return $path;
}

1;
