use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'GitCommitReport',
    VERSION       => '0.01',
    ABSTRACT      => 'Generate Git commit activity reports from a local repository',
    AUTHOR        => 'Charles Zhao',
    LICENSE       => 'mit',
    EXE_FILES     => ['bin/git_commit_report.pl'],
    PREREQ_PM     => {
        'Getopt::Long' => 0,
        'File::Find'   => 0,
        'Time::Piece'  => 0,
        'JSON::PP'     => 0,
        'Text::CSV'    => '2.00',
        'YAML::Tiny'   => '1.70',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    test          => { TESTS => 't/*.t' },
);
