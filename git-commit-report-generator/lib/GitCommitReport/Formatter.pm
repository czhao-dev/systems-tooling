package GitCommitReport::Formatter;

use strict;
use warnings;

use Exporter qw(import);
use JSON::PP ();
use Text::CSV ();

use GitCommitReport::Utils qw(format_number);

our @EXPORT_OK = qw(format_report to_text to_markdown to_csv to_json);

my @CATEGORY_ORDER = (
    [feature       => 'Feature'],
    [bugfix        => 'Bug Fix'],
    [refactor      => 'Refactor'],
    [test          => 'Test'],
    [documentation => 'Documentation'],
    [build         => 'Build'],
    [other         => 'Other'],
);

my %DISPATCH = (
    text     => \&to_text,
    markdown => \&to_markdown,
    csv      => \&to_csv,
    json     => \&to_json,
);

sub format_report {
    my ($report, $format) = @_;
    my $fn = $DISPATCH{$format}
        or die "Unknown format '$format' (expected: text, markdown, csv, json)\n";
    return $fn->($report);
}

# ---------------------------------------------------------------------------
# Shared row-building helpers (data only, no rendering syntax)
# ---------------------------------------------------------------------------

sub _summary_rows {
    my ($report) = @_;
    my $s = $report->{summary};
    return [
        ['Total commits', format_number($s->{total_commits})],
        ['Total authors', format_number($s->{total_authors})],
        ['Files changed', format_number($s->{files_changed})],
        ['Lines added',   format_number($s->{insertions})],
        ['Lines deleted', format_number($s->{deletions})],
    ];
}

sub _commit_type_rows {
    my ($report) = @_;
    my $types = $report->{commit_types} || {};
    return [ map { [ $_->[1], format_number($types->{ $_->[0] } || 0) ] } @CATEGORY_ORDER ];
}

sub _author_rows {
    my ($report, $top) = @_;
    my @rows = @{ $report->{by_author} || [] };
    splice(@rows, $top) if $top && @rows > $top;
    return [ map { [ $_->{author}, format_number($_->{count}) ] } @rows ];
}

sub _date_rows {
    my ($report) = @_;
    return [ map { [ $_->{period}, format_number($_->{count}) ] } @{ $report->{by_date} || [] } ];
}

sub _directory_rows {
    my ($report, $top) = @_;
    my @rows = @{ $report->{by_directory} || [] };
    splice(@rows, $top) if $top && @rows > $top;
    return [ map { [ ($_->{directory} eq '.' ? '(root)' : "$_->{directory}/"), format_number($_->{count}) ] } @rows ];
}

sub _extension_rows {
    my ($report, $top) = @_;
    my @rows = @{ $report->{by_extension} || [] };
    splice(@rows, $top) if $top && @rows > $top;
    return [ map { [ ($_->{extension} eq '(no ext)' ? $_->{extension} : ".$_->{extension}"), format_number($_->{count}) ] } @rows ];
}

sub _commit_summary_rows {
    my ($commits) = @_;
    return [ map { [ $_->{short}, $_->{author}, format_number($_->{files_changed}), $_->{subject} ] } @$commits ];
}

sub _frequent_file_rows {
    my ($report) = @_;
    return [ map { [ $_->{path}, format_number($_->{count}) ] } @{ $report->{most_frequent_files} || [] } ];
}

# ---------------------------------------------------------------------------
# text
# ---------------------------------------------------------------------------

sub to_text {
    my ($report) = @_;
    my $top  = $report->{meta}{top};
    my @out;

    push @out, 'Git Commit Activity Report', ('=' x 27), '';
    push @out, "Repository: " . ($report->{meta}{repository} // ''),
               "Branch: "     . ($report->{meta}{branch}     // ''),
               "Date Range: " . ($report->{meta}{since} // '?') . " to " . ($report->{meta}{until} // '?'),
               '';

    push @out, _text_kv_section('Summary',            _summary_rows($report));
    push @out, _text_kv_section('Commit Type Summary', _commit_type_rows($report));
    push @out, _text_table_section('Commits by Author',           _author_rows($report, $top), ' commits');
    push @out, _text_table_section('Commits by Date',             _date_rows($report),         ' commits');
    push @out, _text_table_section('Top Changed Directories',     _directory_rows($report, $top), ' files changed');
    push @out, _text_table_section('Files by Extension',          _extension_rows($report, $top), ' files changed');
    push @out, _text_numbered_commits_section('Largest Commits',  $report->{largest_commits} || []);
    push @out, _text_commits_section('Risky Commits',             $report->{risky_commits} || []);
    push @out, _text_table_section('Most Frequently Changed Files', _frequent_file_rows($report), ' changes');

    return join("\n", @out) . "\n";
}

sub _text_kv_section {
    my ($title, $rows) = @_;
    my @lines = ($title, ('-' x length($title)));
    my $width = 0;
    for my $row (@$rows) { $width = length($row->[0]) if length($row->[0]) > $width; }
    for my $row (@$rows) {
        push @lines, sprintf('%-' . ($width + 2) . 's%s', "$row->[0]:", $row->[1]);
    }
    push @lines, '';
    return @lines;
}

sub _text_table_section {
    my ($title, $rows, $suffix) = @_;
    my @lines = ($title, ('-' x length($title)));
    my $width = 8;
    for my $row (@$rows) { $width = length($row->[0]) if length($row->[0]) > $width; }
    for my $row (@$rows) {
        push @lines, sprintf('%-' . ($width + 4) . 's%s%s', $row->[0], $row->[1], $suffix);
    }
    push @lines, '';
    return @lines;
}

sub _commit_column_widths {
    my ($commits) = @_;
    my ($author_width, $files_width) = (8, 18);
    for my $commit (@$commits) {
        my $author_len = length($commit->{author} // '');
        $author_width = $author_len if $author_len > $author_width;
        my $files_len = length("$commit->{files_changed} files changed");
        $files_width = $files_len if $files_len > $files_width;
    }
    return ($author_width + 4, $files_width + 4);
}

sub _text_numbered_commits_section {
    my ($title, $commits) = @_;
    my @lines = ($title, ('-' x length($title)));
    my ($author_width, $files_width) = _commit_column_widths($commits);
    my $i = 1;
    for my $commit (@$commits) {
        push @lines, sprintf('%d. %-9s%-' . $author_width . 's%-' . $files_width . 's%s',
            $i++, $commit->{short}, $commit->{author}, "$commit->{files_changed} files changed", $commit->{subject});
    }
    push @lines, '';
    return @lines;
}

sub _text_commits_section {
    my ($title, $commits) = @_;
    my @lines = ($title, ('-' x length($title)));
    my ($author_width, $files_width) = _commit_column_widths($commits);
    for my $commit (@$commits) {
        push @lines, sprintf('%-9s%-' . $author_width . 's%-' . $files_width . 's%s',
            $commit->{short}, $commit->{author}, "$commit->{files_changed} files changed", $commit->{subject});
    }
    push @lines, '';
    return @lines;
}

# ---------------------------------------------------------------------------
# markdown
# ---------------------------------------------------------------------------

sub to_markdown {
    my ($report) = @_;
    my $top = $report->{meta}{top};
    my @out;

    push @out, '# Git Commit Activity Report', '';
    push @out, "**Repository:** " . ($report->{meta}{repository} // ''), '',
               "**Branch:** "     . ($report->{meta}{branch}     // ''), '',
               "**Date Range:** " . ($report->{meta}{since} // '?') . ' to ' . ($report->{meta}{until} // '?'), '';

    push @out, _md_table('Summary',            ['Metric', 'Value'],   _summary_rows($report));
    push @out, _md_table('Commit Type Summary', ['Type', 'Count'],    _commit_type_rows($report));
    push @out, _md_table('Commits by Author',   ['Author', 'Commits'], _author_rows($report, $top));
    push @out, _md_table('Commits by Date',     ['Date', 'Commits'],   _date_rows($report));
    push @out, _md_table('Top Changed Directories', ['Directory', 'Files Changed'], _directory_rows($report, $top));
    push @out, _md_table('Files by Extension',  ['Extension', 'Files Changed'], _extension_rows($report, $top));
    push @out, _md_numbered_commits_table('Largest Commits', $report->{largest_commits} || []);
    push @out, _md_commits_table('Risky Commits', $report->{risky_commits} || []);
    push @out, _md_table('Most Frequently Changed Files', ['File', 'Times Changed'], _frequent_file_rows($report));

    return join("\n", @out) . "\n";
}

sub _md_table {
    my ($title, $headers, $rows) = @_;
    my @lines = ("## $title", '');
    push @lines, '| ' . join(' | ', @$headers) . ' |';
    push @lines, '|' . join('|', map { '---' } @$headers) . '|';
    for my $row (@$rows) {
        push @lines, '| ' . join(' | ', @$row) . ' |';
    }
    push @lines, '';
    return @lines;
}

sub _md_numbered_commits_table {
    my ($title, $commits) = @_;
    my @lines = ("## $title", '');
    push @lines, '| # | Hash | Author | Files Changed | Subject |';
    push @lines, '|---|---|---|---|---|';
    my $i = 1;
    for my $commit (@$commits) {
        push @lines, sprintf('| %d | %s | %s | %s | %s |',
            $i++, $commit->{short}, $commit->{author}, $commit->{files_changed}, $commit->{subject});
    }
    push @lines, '';
    return @lines;
}

sub _md_commits_table {
    my ($title, $commits) = @_;
    my @lines = ("## $title", '');
    push @lines, '| Hash | Author | Files Changed | Subject |';
    push @lines, '|---|---|---|---|';
    for my $commit (@$commits) {
        push @lines, sprintf('| %s | %s | %s | %s |',
            $commit->{short}, $commit->{author}, $commit->{files_changed}, $commit->{subject});
    }
    push @lines, '';
    return @lines;
}

# ---------------------------------------------------------------------------
# csv — single combined file, sections delimited by "# Section,<name>" marker
# rows, raw (unformatted) numbers since CSV consumers expect plain numerics.
# ---------------------------------------------------------------------------

sub to_csv {
    my ($report) = @_;
    my $top = $report->{meta}{top};

    my $csv = Text::CSV->new({ binary => 1, eol => "\n" });
    my $out = '';
    open(my $fh, '>', \$out) or die "Failed to open in-memory CSV buffer: $!\n";

    my $section = sub {
        my ($name, $headers, $rows) = @_;
        $csv->print($fh, ['# Section', $name]);
        $csv->print($fh, $headers) if $headers;
        $csv->print($fh, $_) for @$rows;
        $csv->print($fh, []);
    };

    my $s = $report->{summary};
    $section->('Summary', ['Metric', 'Value'], [
        ['Total commits', $s->{total_commits}],
        ['Total authors', $s->{total_authors}],
        ['Files changed', $s->{files_changed}],
        ['Lines added',   $s->{insertions}],
        ['Lines deleted', $s->{deletions}],
    ]);

    my $types = $report->{commit_types} || {};
    $section->('Commit Type Summary', ['Type', 'Count'],
        [ map { [ $_->[1], $types->{ $_->[0] } || 0 ] } @CATEGORY_ORDER ]);

    my @authors = @{ $report->{by_author} || [] };
    splice(@authors, $top) if $top && @authors > $top;
    $section->('Commits by Author', ['Author', 'Commits'],
        [ map { [ $_->{author}, $_->{count} ] } @authors ]);

    $section->('Commits by Date', ['Date', 'Commits'],
        [ map { [ $_->{period}, $_->{count} ] } @{ $report->{by_date} || [] } ]);

    my @dirs = @{ $report->{by_directory} || [] };
    splice(@dirs, $top) if $top && @dirs > $top;
    $section->('Top Changed Directories', ['Directory', 'Files Changed'],
        [ map { [ $_->{directory}, $_->{count} ] } @dirs ]);

    my @exts = @{ $report->{by_extension} || [] };
    splice(@exts, $top) if $top && @exts > $top;
    $section->('Files by Extension', ['Extension', 'Files Changed'],
        [ map { [ $_->{extension}, $_->{count} ] } @exts ]);

    $section->('Largest Commits', ['Hash', 'Author', 'FilesChanged', 'Subject'],
        [ map { [ $_->{short}, $_->{author}, $_->{files_changed}, $_->{subject} ] } @{ $report->{largest_commits} || [] } ]);

    $section->('Risky Commits', ['Hash', 'Author', 'FilesChanged', 'Subject'],
        [ map { [ $_->{short}, $_->{author}, $_->{files_changed}, $_->{subject} ] } @{ $report->{risky_commits} || [] } ]);

    $section->('Most Frequently Changed Files', ['File', 'Count'],
        [ map { [ $_->{path}, $_->{count} ] } @{ $report->{most_frequent_files} || [] } ]);

    close($fh);
    return $out;
}

# ---------------------------------------------------------------------------
# json — the analyzer's aggregate struct, with ranked commit lists
# projected to a stable field subset (no per-file diff dump).
# ---------------------------------------------------------------------------

sub to_json {
    my ($report) = @_;

    my %projected = %$report;
    for my $key (qw(largest_commits risky_commits)) {
        $projected{$key} = [ map { _project_commit($_) } @{ $report->{$key} || [] } ];
    }

    return JSON::PP->new->utf8->canonical->pretty->encode(\%projected);
}

sub _project_commit {
    my ($commit) = @_;
    return {
        hash          => $commit->{hash},
        short         => $commit->{short},
        author        => $commit->{author},
        date          => $commit->{date},
        subject       => $commit->{subject},
        files_changed => $commit->{files_changed},
        insertions    => $commit->{insertions},
        deletions     => $commit->{deletions},
    };
}

1;
