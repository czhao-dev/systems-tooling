#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long qw(GetOptions);

use GitCommitReport::Parser   qw(parse_commits);
use GitCommitReport::Analyzer qw(analyze);
use GitCommitReport::Formatter qw(format_report);
use GitCommitReport::Utils    qw(default_config load_config merge_config);

my @VALID_FORMATS = qw(text markdown csv json);

my %opt;
GetOptions(\%opt,
    'since=s', 'until=s', 'author=s', 'branch=s', 'path=s',
    'format=s', 'output=s', 'top=i', 'risky-threshold=i',
    'config=s', 'help|h',
) or die usage();

if ($opt{help}) {
    print usage();
    exit 0;
}

eval {
    run(%opt);
    1;
} or do {
    my $err = $@ || 'Unknown error';
    print STDERR "Error: $err";
    exit 1;
};

exit 0;

sub run {
    my %opt = @_;

    my $defaults = default_config();
    my $file_cfg = $opt{config} ? load_config($opt{config}) : {};
    my %cli_opts;
    $cli_opts{default_format}              = $opt{format}            if defined $opt{format};
    $cli_opts{risky_commit_file_threshold} = $opt{'risky-threshold'} if defined $opt{'risky-threshold'};
    $cli_opts{top_results}                 = $opt{top}                if defined $opt{top};
    my $config = merge_config($defaults, $file_cfg, \%cli_opts);

    my $format = $config->{default_format};
    die "Invalid --format '$format' (expected one of: " . join(', ', @VALID_FORMATS) . ")\n"
        unless grep { $_ eq $format } @VALID_FORMATS;

    my $commits = parse_commits(
        since   => $opt{since},
        until   => $opt{until},
        author  => $opt{author},
        branch  => $opt{branch},
        path    => $opt{path},
    );

    my $report = analyze($commits,
        top             => $config->{top_results},
        risky_threshold => $config->{risky_commit_file_threshold},
        classification  => $config->{classification},
        meta            => build_meta(%opt, top => $config->{top_results}),
    );

    my $output = format_report($report, $format);

    if ($opt{output}) {
        open(my $fh, '>', $opt{output}) or die "Failed to write '$opt{output}': $!\n";
        print $fh $output;
        close($fh);
    }
    else {
        print $output;
    }

    return 1;
}

sub build_meta {
    my %opt = @_;

    my $toplevel = _git_capture('rev-parse', '--show-toplevel');
    my ($repository) = $toplevel =~ m{([^/]+)/?$};

    my $branch = $opt{branch} // _git_capture('rev-parse', '--abbrev-ref', 'HEAD');

    return {
        repository => $repository // '(unknown)',
        branch     => $branch     // '(unknown)',
        since      => $opt{since} // '(beginning)',
        until      => $opt{until} // '(now)',
        top        => $opt{top},
    };
}

sub _git_capture {
    my (@args) = @_;
    open(my $fh, '-|', 'git', @args) or return undef;
    my $out = do { local $/; <$fh> };
    close($fh);
    return undef if $? != 0;
    chomp $out if defined $out;
    return $out;
}

sub usage {
    return <<'USAGE';
Usage: git_commit_report.pl [options]

Options:
  --since <date>          Start date for commit analysis
  --until <date>          End date for commit analysis
  --author <name>         Filter commits by author
  --branch <branch>       Analyze a specific Git branch
  --path <path>           Analyze changes under a specific file or directory
  --format <type>         Output format: text, markdown, csv, or json
  --output <file>         Write report to a file
  --top <N>               Show top N results for ranked sections
  --risky-threshold <N>   Mark commits touching more than N files as risky
  --config <file>         Load a YAML configuration file
  --help                  Show this help message
USAGE
}
