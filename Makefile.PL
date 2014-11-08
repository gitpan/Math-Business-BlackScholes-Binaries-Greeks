use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Math::Business::BlackScholes::Binaries::Greeks',
    AUTHOR           => q{binary.com <perl@binary.com>},
    VERSION_FROM     => 'lib/Math/Business/BlackScholes/Binaries/Greeks.pm',
    ABSTRACT         => 'Sensitivity of the price of binary options',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Most' => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'Math::CDF' => 0,
        'Math::Business::BlackScholes::Binaries' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Math-Business-BlackScholes-Binaries-Greeks-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    url => 'https://github.com/binary-com/perl-Math-Business-Blackscholes-Binaries-Greeks.git',
                    web => 'https://github.com/binary-com/perl-Math-Business-Blackscholes-Binaries-Greeks',
                },
              }
          } )
     : ()
    ),
);
