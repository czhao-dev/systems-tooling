package GitCommitReport::Analyzer;

use strict;
use warnings;

use Exporter qw(import);
use Time::Piece;

use GitCommitReport::Utils qw(dir_of ext_of);

our @EXPORT_OK = qw(analyze);

# Fixed priority order: first keyword match wins, keeping classification
# a strict partition of commits into exactly one bucket (plus 'other').
my @CATEGORY_ORDER = qw(feature bugfix refactor test documentation build);

sub analyze {
    my ($commits, %opts) = @_;

    my $top             = $opts{top} || 10;
    my $risky_threshold = defined $opts{risky_threshold} ? $opts{risky_threshold} : 25;
    my $classification   = $opts{classification} || {};
    my $meta             = $opts{meta} || {};

    return {
        meta                => $meta,
        summary             => summary_stats($commits),
        by_author           => commits_by_author($commits),
        by_date             => commits_by_date($commits, 'day'),
        by_directory        => files_by_directory($commits),
        by_extension        => files_by_extension($commits),
        largest_commits     => largest_commits($commits, $top),
        risky_commits       => risky_commits($commits, $risky_threshold),
        most_frequent_files => most_frequent_files($commits, $top),
        commit_types        => classify_commits($commits, $classification),
    };
}

sub summary_stats {
    my ($commits) = @_;

    my %authors;
    my ($files_changed, $insertions, $deletions) = (0, 0, 0);
    for my $commit (@$commits) {
        $authors{ $commit->{author} } = 1;
        $files_changed += $commit->{files_changed} // 0;
        $insertions    += $commit->{insertions}    // 0;
        $deletions     += $commit->{deletions}     // 0;
    }

    return {
        total_commits => scalar(@$commits),
        total_authors => scalar(keys %authors),
        files_changed => $files_changed,
        insertions    => $insertions,
        deletions     => $deletions,
    };
}

sub commits_by_author {
    my ($commits) = @_;

    my %counts;
    $counts{ $_->{author} }++ for @$commits;

    return [
        map { { author => $_, count => $counts{$_} } }
        sort { $counts{$b} <=> $counts{$a} || $a cmp $b }
        keys %counts
    ];
}

sub commits_by_date {
    my ($commits, $granularity) = @_;
    $granularity ||= 'day';

    my %counts;
    for my $commit (@$commits) {
        # Use the calendar date embedded in the commit's own ISO-8601
        # author date string (its local timezone), not an epoch/gmtime
        # conversion, which would shift the date across timezone offsets.
        my ($y, $m, $d) = ($commit->{date} || '') =~ /^(\d{4})-(\d{2})-(\d{2})/;
        next unless defined $y;

        my $period;
        if ($granularity eq 'month') {
            $period = "$y-$m";
        }
        elsif ($granularity eq 'week') {
            my $t = Time::Piece->strptime("$y-$m-$d", '%Y-%m-%d');
            $period = $t->strftime('%Y-W%V');
        }
        else {
            $period = "$y-$m-$d";
        }
        $counts{$period}++;
    }

    return [
        map { { period => $_, count => $counts{$_} } }
        sort keys %counts
    ];
}

sub files_by_directory {
    my ($commits) = @_;

    my %counts;
    for my $commit (@$commits) {
        $counts{ dir_of($_->{path}) }++ for @{ $commit->{files} };
    }

    return [
        map { { directory => $_, count => $counts{$_} } }
        sort { $counts{$b} <=> $counts{$a} || $a cmp $b }
        keys %counts
    ];
}

sub files_by_extension {
    my ($commits) = @_;

    my %counts;
    for my $commit (@$commits) {
        $counts{ ext_of($_->{path}) }++ for @{ $commit->{files} };
    }

    return [
        map { { extension => $_, count => $counts{$_} } }
        sort { $counts{$b} <=> $counts{$a} || $a cmp $b }
        keys %counts
    ];
}

sub largest_commits {
    my ($commits, $top) = @_;

    my @sorted = sort { ($b->{files_changed} // 0) <=> ($a->{files_changed} // 0) } @$commits;
    splice(@sorted, $top) if $top && @sorted > $top;

    return \@sorted;
}

sub risky_commits {
    my ($commits, $threshold) = @_;

    my @risky = grep { ($_->{files_changed} // 0) > $threshold } @$commits;
    return [ sort { ($b->{files_changed} // 0) <=> ($a->{files_changed} // 0) } @risky ];
}

sub most_frequent_files {
    my ($commits, $top) = @_;

    my %counts;
    for my $commit (@$commits) {
        $counts{ $_->{path} }++ for @{ $commit->{files} };
    }

    my @ranked =
        map { { path => $_, count => $counts{$_} } }
        sort { $counts{$b} <=> $counts{$a} || $a cmp $b }
        keys %counts;
    splice(@ranked, $top) if $top && @ranked > $top;

    return \@ranked;
}

sub classify_commits {
    my ($commits, $classification) = @_;

    my %totals = (map { $_ => 0 } @CATEGORY_ORDER, 'other');
    for my $commit (@$commits) {
        my $category = _classify_subject($commit->{subject}, $classification);
        $totals{$category}++;
    }

    return \%totals;
}

sub _classify_subject {
    my ($subject, $classification) = @_;
    return 'other' unless defined $subject;

    my $subject_lc = lc($subject);
    for my $category (@CATEGORY_ORDER) {
        my $keywords = $classification->{$category} || [];
        for my $keyword (@$keywords) {
            return $category if $subject_lc =~ /\b\Q$keyword\E\b/;
        }
    }

    return 'other';
}

1;
