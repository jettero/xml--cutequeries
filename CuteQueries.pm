
package XML::Twigx::CuteQueries;

use strict;
use warnings;
use Scalar::Util qw(reftype blessed);
use XML::Twigx::CuteQueries::Error;
use base 'XML::Twig';

use constant SCALAR => 0;
use constant LIST   => 1;
use constant KLIST  => 2;

our $VERSION = '0.5000';

# _data_error {{{
sub _data_error {
    my $this = shift;
    my $desc = shift || "single-value";
       $desc = shift() . " [$desc result request]";

    XML::Twigx::CuteQueries::Error->new(
        type => XML::Twigx::CuteQueries::Error::DATA_ERROR(),
        text => $desc,
    )->throw;

    return; # technically unreachable, but critic won't notice
}
# }}}
# _query_error {{{
sub _query_error {
    my $this = shift;
    my $err  = shift;

    my $f = __FILE__;
    $err =~ s/\s+at\s+\Q$f\E\s+line\s+\d+//;

    XML::Twigx::CuteQueries::Error->new(
        type => XML::Twigx::CuteQueries::Error::QUERY_ERROR(),
        text => $err,
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
    my ($this, $root, $opts, $query, $res_type, $context) = @_;
    $context = SCALAR unless defined $context and caller eq __PACKAGE__;

    my $rt = (defined $res_type and reftype $res_type) || '';
    my $re = ref($query) eq "Regexp";

    if( $context == KLIST ) {
        if( $query =~ m/^\(\?[\w-]+:.+\)\z/ ) {
            # NOTE: the key of a has can never actually be a blessed Regexp, so re-bless if we find one

            $query = qr($query);
            $re = 1;

            # NOTE: should we always do this instead of only during KLIST?
        }
    }

    my @c  = eval { $re ? grep {$_->gi() =~ $query } $root->children : $root->children($query) };
    $this->_query_error("while executing \"$query\": $@") if $@;

    # warn "\@c=".@c."; rt: $rt; query: $query; context: $context\n";

    $this->_data_error($rt, "match failed for \"$query\"") unless $opts->{nostrict} or @c;
    return unless @c;

    if( not $rt ) {
        if( $context == LIST ) {
            return map { $_->text      } @c if $opts->{recurse_text};
            return map { $_->text_only } @c;

        } elsif( $context == KLIST ) {
            return map { $_->gi() => $_->text      } @c if $opts->{recurse_text};
            return map { $_->gi() => $_->text_only } @c;

        }

        $this->_data_error($rt, "expected single match for \"$query\", got " . @c) unless $opts->{nostrict} or @c==1;

        my $result = $opts->{recurse_text} ? $c[0]->text : $c[0]->text_only;
        return $result;

    } elsif( $rt eq "HASH" ) {
        if( $context == LIST ) {
            return map {
                my $c = $_;
                scalar # I don't think I should need this word here, but I clearly do
                {map {$this->_execute_query($c, $opts, $_ => $res_type->{$_}, KLIST)} keys %$res_type};
            } @c;

        } elsif( $context == KLIST ) {
            return map {
                my $c = $_;
                $_->gi() => {map { $this->_execute_query($c, $opts, $_ => $res_type->{$_}, KLIST) } keys %$res_type}
            } @c;
        }

        $this->_data_error($rt, "expected single match for \"$query\", got " . @c) unless $opts->{nostrict} or @c==1;
        return {
            map { $this->_execute_query($c[0], $opts, $_ => $res_type->{$_}, KLIST) } keys %$res_type
        };

    } elsif( $rt eq "ARRAY" ) {
        my ($pat, $res) = @$res_type;

        if( $context == LIST ) {
            return map { [$this->_execute_query($_, $opts, $pat => $res, LIST)] } @c;

        } elsif( $context == KLIST ) {
            return map { $_->gi() => [$this->_execute_query($_, $opts, $pat => $res, LIST)] } @c;
        }

        $this->_data_error($rt, "expected single match for \"$query\", got " . @c) unless $opts->{nostrict} or @c==1;
        return [ $this->_execute_query($c[0], $opts, $pat => $res, LIST) ];
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

    return $result[0] unless wantarray; # we never want the size of the array
    return @result;
}

1;
