
package XML::CuteQueries;

use strict;
use warnings;
use Scalar::Util qw(reftype blessed);
use XML::CuteQueries::Error;
use base 'XML::Twig';

use constant LIST   => 1;
use constant KLIST  => 2;

our $VERSION = '0.6001';

our %VALID_OPTS = (map {$_=>1} qw(nostrict nofilter_nontags notrim klist));

# _data_error {{{
sub _data_error {
    my $this = shift;
    my $desc = shift || "single-value";
       $desc = shift() . " [$desc result request]";

    XML::CuteQueries::Error->new(
        type => XML::CuteQueries::Error::DATA_ERROR(),
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

    XML::CuteQueries::Error->new(
        type => XML::CuteQueries::Error::QUERY_ERROR(),
        text => $err,
    )->throw;

    return; # technically unreachable, but critic won't notice
}
# }}}

# _pre_parse_queries {{{
sub _pre_parse_queries {
    my $this = shift;
    my $opts = shift;

    if( @_ % 2 ) {
        $this->_query_error("odd number of arguments, queries are hashes and therefore should be a series of key/value pairs.");
    }

    return 1;
}
# }}}
# _execute_query {{{
sub _execute_query {
    my ($this, $root, $opts, $query, $res_type, $context) = @_;

    XML::CuteQueries::Error->new(text=>"\$context specification error")->throw
        if not defined $context or $context<1 or $context>2;

    my $mt = 0; # magic restype (restype scalar sub-type)
    my $rt = 0; # processed reftype (false for scalars)

    if( $res_type ||= 0 ) {
        unless( $rt = reftype $res_type ) {
            if( $res_type =~ m/^(?:x|xml|xml\(\))\z/ ) { # xml()
                $mt = "x";

            } elsif( $res_type =~ m/^(?:t|twig|twig\(\))\z/ ) { # twig()
                $mt = "t";

            } elsif( $res_type =~ m/^(?:r|a|recurse|all)(?:_text(?:\(\))?)?/ ) { # recurse_text() all_text()
                $mt = "r";

            } else {
                $this->_query_error("unknown scalar query sub-type: $res_type");
            }

            $res_type = undef;
        }
    }

    my ($re, $nre) = (0,0);

    if( my ($type, $code) = $query =~ m/^<([!Nn]?[Rr][Ee])>(.+?)(?:<\/\1>)?\z/ ) {
        if( lc($type) eq "re" ) {
            $re  = 1;

        } else {
            $re = $nre = 1;
        }

        $query = qr($code);
    }

    my @c;
    my $attr_query;
    if( not $rt ) {
        if( $query =~ m/^\S/ and $query =~ s/\/?\@([\w\d]+|\*)\z// ) {
            $attr_query = $1;
            @c = $root unless $query;
        }
    }

    # @c is only true when it's a root-attr query
    unless(@c) {
        @c = eval {
            if( $re ) {
                return grep {$_->gi !~ $query } $root->children if $nre;
                return grep {$_->gi =~ $query } $root->children;
            }

            return $root->get_xpath($query)
        };

        $this->_query_error("while executing \"$query\": $@") if $@;
        @c = grep {$_->gi !~ m/^#/} @c unless $opts->{nofilter_nontags};
    }

    $this->_data_error($rt, "match failed for \"$query\"") unless @c or $opts->{nostrict};
    return unless @c;

    my $_trimlist;
    my $_trimhash;

    if( $opts->{notrim} ) {
        $_trimlist = $_trimhash = sub {@_};

    } else {
        $_trimlist = sub { for(@_) { unless( m/\n/ ) { s/^\s+//; s/\s+$// }}; @_ };
        $_trimhash = sub { my %h=@_; for(grep {defined $_} values %h) { unless( m/\n/ ) { s/^\s+//; s/\s+$// }}; %h };
    }

    if( not $rt ) {
        if( $attr_query ) {
            if( $attr_query eq "*" ) {
                if( $context == KLIST ) {
                    return $_trimhash->( map { %{$_->{att}} } @c );
                }

                return $_trimlist->( map { values %{$_->{att}} } @c );
            }

            if( $context == KLIST ) {
                return $_trimhash->( map { $attr_query => $_->{att}{$attr_query} } @c );
            }

            return $_trimlist->( map { $_->{att}{$attr_query} } @c );
        }

        if( $context == KLIST ) {
            return map { $_->gi => $_ } @c if $mt eq "t";
            return $_trimhash->( map { $_->gi => $_->xml_string } @c ) if $mt eq "x";
            return $_trimhash->( map { $_->gi => $_->text       } @c ) if $mt eq "r";
            return $_trimhash->( map { $_->gi => $_->text_only  } @c );
        }

        return @c if $mt eq "t";
        return $_trimlist->( map { $_->xml_string } @c ) if $mt eq "x";
        return $_trimlist->( map { $_->text       } @c ) if $mt eq "r";
        return $_trimlist->( map { $_->text_only  } @c );

    } elsif( $rt eq "HASH" ) {
        if( $context == KLIST ) {
            return map {
                my $c = $_;
                $_->gi => {map { $this->_execute_query($c, $opts, $_ => $res_type->{$_}, KLIST) } keys %$res_type}
            } @c;
        }

        return map {
            my $c = $_;
            scalar # I don't think I should need this word here, but I clearly do
            {map {$this->_execute_query($c, $opts, $_ => $res_type->{$_}, KLIST)} keys %$res_type};
        } @c;

    } elsif( $rt eq "ARRAY" ) {
        my @p;
        while( my ($pat, $res) = splice @$res_type, 0, 2 ) {
            push @p, [$pat, $res];
        }

        if( $context == KLIST ) {
            return map {my $c = $_; $c->gi => [ map {$this->_execute_query($c, $opts, @$_, LIST)} @p ] } @c;
        }

        return map { my $c = $_; [ map {$this->_execute_query($c, $opts, @$_, LIST)} @p ] } @c;
    }

    XML::CuteQueries::Error->new(text=>"unexpected condition met")->throw;
    return;
}
# }}}

# cute_query {{{
sub cute_query {
    my $this = shift;
    my $opts = {};
       $opts = shift if ref $_[0] eq "HASH";

    for(keys %$opts) {
        $this->_query_error("no such query option \"$_\"") unless $VALID_OPTS{$_};
    }

    my $context = LIST;
       $context = KLIST if delete $opts->{klist};

    $this->_pre_parse_queries($opts, @_);

    my @result;
    my ($query, $res_type) = @_; # used in error below

    while( my @q = splice @_, 0, 2 ) {
        push @result, $this->_execute_query($this->root, $opts, @q, $context);
    }

    unless( wantarray ) {

        unless( $opts->{nostrict} or @result==1 ) {
            my $rt = (defined $res_type and reftype $res_type) || '';
            $this->_data_error($rt, "expected exactly one match for \"$query\", got " . @result)
        }

        return $result[0]; # we never want the size of the array, preferring the first match
    }

    return @result;
}
# }}}

# hash_query {{{
sub hash_query {
    my $this = shift;
    my $opts = {};
       $opts = shift if ref($_[0]) eq "HASH";

    $opts->{klist} = 1;
    return $this->cute_query($opts, @_);
}
*klist_query = \&hash_query;
# }}}

1;
