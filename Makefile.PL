# vi:set syntax=perl:

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'XML::Twigx::CuteQueries',
    'VERSION_FROM'  => 'CuteQueries.pm',

    'PREREQ_PM'     => { 
        'XML::Twig' => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006,
            META_MERGE => {
                keywords => [qw(xml twig)],
                resources=> {
                    repository => 'http://github.com/jettero/xml--twigx--cutequeries',
                },
            },

        LICENSE	=> 'LGPL',
    ) : ()),

);
