
package XML::Twigx::CuteQueries;

use strict;
use warnings;
use Scalar::Util qw(reftype blessed);
use XML::Twigx::CuteQueries::Error;
use base 'XML::Twig';

our $VERSION = '0.5000';

# _data_error {{{
sub _data_error {
    my $this = shift;

    XML::Twigx::CuteQueries::Error->new(
        type => XML::Twigx::CuteQueries::Error::DATA_ERROR(),
        text => shift,
    )->throw;

    return; # technically unreachable, but critic won't notice
}
# }}}
# _query_error {{{
sub _query_error {
    my $this = shift;

    XML::Twigx::CuteQueries::Error->new(
        type => XML::Twigx::CuteQueries::Error::QUERY_ERROR(),
        text => shift,
    )->throw;

    return; # technically unreachable, but critic won't notice
}
# }}}

sub _pre_parse_queries {
    my $this = shift;
    my $opts = shift;

    if( @_ % 2 ) {
        $this->_query_error("odd number of arguments, queries are hashes and therefore should be a series of key/value pairs.");
    }

    return 1;
}
sub _execute_query {
    my ($this, $root, $opts, $query, $res_type) = @_;

    my $rt = defined $res_type and reftype $res_type;
    my $re = ref($query) eq "Regexp";
    my @c  = $re ? $root->children($query) : grep { $_ =~ $re } $root->children;

    $this->_data_error("match failed for \"$query\"") unless $opts->{nostrict};
    return unless @c;

    if( not $rt ) {
        $this->_data_error("expected single match for \"$query\", got " . @c) unless $opts->{nostrict} or @c==1;

        return scalar $opts->{recurse_text} ? $c[0]->text : $c[0]->text_only;

    } elsif( $rt eq "HASH" ) {
        return { map {1} @c } if $opts->{recurse_text};
        return { map {1} @c };

    } elsif( $rt eq "ARRAY" ) {
    }

    XML::Twigx::CuteQueries::Error->new(text=>"unexpected condition met")->throw;
    return;
}

sub cute_query {
    my $this = shift;
    my $opts = {};
       $opts = shift if ref $_[0] eq "HASH";

    $this->_pre_parse_queries($opts, @_);

    my @result;

    while( my @q = splice @_, 0, 2 ) {
        push @result, scalar $this->_execute_query($this->root, $opts, @q);
    }

    return @result;
}

1;
