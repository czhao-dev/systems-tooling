package GitCommitReport::Utils;

use strict;
use warnings;

use Exporter qw(import);
use Time::Piece;
use YAML::Tiny;

our @EXPORT_OK = qw(
    format_number
    ext_of
    dir_of
    parse_date
    load_config
    default_config
    default_classification
    merge_config
);

# 12450 -> "12,450"; undef -> "0"
sub format_number {
    my ($n) = @_;
    return '0' unless defined $n;
    my $sign = $n < 0 ? '-' : '';
    my $int = sprintf('%d', abs($n));
    1 while $int =~ s/(\d)(\d{3})(?!\d)/$1,$2/;
    return "$sign$int";
}

# "src/foo.pm" -> "pm"; "Makefile" -> "(no ext)"
sub ext_of {
    my ($path) = @_;
    my ($basename) = $path =~ m{([^/]+)$};
    $basename = $path unless defined $basename;
    return '(no ext)' unless $basename =~ /\.([^.\/]+)$/;
    return lc($1);
}

# "src/sub/file.txt" -> "src"; "file.txt" -> "."
sub dir_of {
    my ($path) = @_;
    return '.' unless $path =~ m{/};
    my ($top) = $path =~ m{^([^/]+)/};
    return $top;
}

# Validates "YYYY-MM-DD"; dies with a clear message on bad format
sub parse_date {
    my ($str) = @_;
    return undef unless defined $str;
    my $t = eval { Time::Piece->strptime($str, '%Y-%m-%d') };
    die "Invalid date '$str': expected format YYYY-MM-DD\n" unless $t;
    return $str;
}

sub default_classification {
    return {
        feature       => ['add', 'implement', 'support', 'enable'],
        bugfix        => ['fix', 'bug', 'issue', 'correct'],
        refactor      => ['refactor', 'cleanup', 'simplify'],
        test          => ['test', 'coverage', 'unit test'],
        documentation => ['doc', 'readme', 'comment'],
        build         => ['build', 'cmake', 'makefile', 'ci'],
    };
}

sub default_config {
    return {
        default_format               => 'text',
        risky_commit_file_threshold  => 25,
        top_results                  => 10,
        classification                => default_classification(),
    };
}

# Reads a YAML config file. Dies with file/parse error context.
sub load_config {
    my ($path) = @_;
    die "Config file not found: $path\n" unless -e $path;
    my $yaml = YAML::Tiny->read($path)
        or die "Failed to parse config file '$path': " . YAML::Tiny->errstr . "\n";
    return $yaml->[0] || {};
}

# 3-way merge: defaults -> file_cfg -> cli_opts (last wins).
# classification is merged per-category so a partial override doesn't
# erase unspecified built-in categories.
sub merge_config {
    my ($defaults, $file_cfg, $cli_opts) = @_;
    $file_cfg ||= {};
    $cli_opts ||= {};

    my %merged = %$defaults;

    for my $key (qw(default_format risky_commit_file_threshold top_results)) {
        $merged{$key} = $file_cfg->{$key} if defined $file_cfg->{$key};
        $merged{$key} = $cli_opts->{$key} if defined $cli_opts->{$key};
    }

    my %classification = %{ $defaults->{classification} || {} };
    if (my $file_class = $file_cfg->{classification}) {
        for my $category (keys %$file_class) {
            $classification{$category} = $file_class->{$category};
        }
    }
    if (my $cli_class = $cli_opts->{classification}) {
        for my $category (keys %$cli_class) {
            $classification{$category} = $cli_class->{$category};
        }
    }
    $merged{classification} = \%classification;

    return \%merged;
}

1;
