use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::Greple',
    AUTHOR           => q{Kazumasa Utashiro <kaz@utashiro.com>},
    VERSION_FROM     => 'bin/greple',
    ABSTRACT         => q{grep type command with ritch context},
    EXE_FILES        => [
        'bin/greple',
    ],
    LICENSE          => '',
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Test::More'   => 0,
        'version'      => 0,
        'Term/ReadKey' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-Greple-*' },
);
