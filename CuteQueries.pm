
package XML::Twigx::CuteQueries;

use strict;
use warnings;
use XML::Twigx::CuteQueries::Error;
use base 'XML::Twig';

our $VERSION = '0.5000';

sub _pre_parse_queries {
    my $this = shift;
    my $opts = shift;

    if( @_ % 2 ) {
        XML::Twigx::CuteQueries::Error->new(
            type => XML::Twigx::CuteQueries::Error::QUERY_ERROR(),
            text => "odd number of arguments, queries are hashes and therefore should be a series of key/value pairs.",
        )->throw;
    }

    return 1;
}

sub cute_query {
    my $this = shift;
    my $opts = {};
       $opts = shift if ref $_[0] eq "HASH";

    $this->_pre_parse_queries($opts, @_);

    my @result;

    for my $q (@_) {
    }

    return @result;
}

1;
