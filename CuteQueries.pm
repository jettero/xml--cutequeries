
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

our %VALID_OPTS = (map {$_=>1} qw(nostrict recurse_text nofilter_nontags notrim));

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

    my @c;
    my $attr_query;
    if( not $rt ) {
        if( $query =~ m/^\S/ and $query =~ s/\/?\@([\w\d]+|\*)\z// ) {
            $attr_query = $1;
            @c = $root unless $query;
        }
    }

    unless(@c) {
        @c = eval { $re ? grep {$_->gi =~ $query } $root->children : $root->get_xpath($query) };

        $this->_query_error("while executing \"$query\": $@") if $@;
        @c = grep {$_->gi !~ m/^#/} @c unless $opts->{nofilter_nontags};
    }

    $this->_data_error($rt, "match failed for \"$query\"") unless @c or $opts->{nostrict};
    return unless @c;

    if( not $rt ) {
        # XXX: This is in some serious need of DRY ...
        # (it's like this to avoid perl's heavy subcall() expense, but it sucks pretty bad like this)

        if( $attr_query ) {
            if( $attr_query eq "*" ) {
                if( $context == LIST ) {
                    my @r = map { values %{$_->{att}} } @c;
                    unless($opts->{notrim}) {
                        for(@r) {
                            unless( m/\n/ ) {
                                s/^\s+//;
                                s/\s+$//;
                            }
                        }
                    }
                    return @r;

                } elsif( $context == KLIST ) {
                    my %r = map { %{$_->{att}} } @c;
                    unless($opts->{notrim}) {
                        for(values %r) {
                            unless( m/\n/ ) {
                                s/^\s+//;
                                s/\s+$//;
                            }
                        }
                    }
                    return %r;
                }

                my @v = map { values %{$_->{att}} } @c;
                $this->_data_error($rt, "expected single match for \"$query\", got " . @v) unless $opts->{nostrict} or @v==1;
                unless($opts->{notrim}) {
                    unless( $v[0] =~ m/\n/ ) {
                        $v[0] =~ s/^\s+//;
                        $v[0] =~ s/\s+$//;
                    }
                }
                return $v[0];
            }

            if( $context == LIST ) {
                my @r = map { $_->{att}{$attr_query} } @c;
                    unless($opts->{notrim}) {
                        for(@r) {
                            unless( m/\n/ ) {
                                s/^\s+//;
                                s/\s+$//;
                            }
                        }
                    }
                return @r;

            } elsif( $context == KLIST ) {
                my %r = map { $attr_query => $_->{att}{$attr_query} } @c;
                unless($opts->{notrim}) {
                    for(values %r) {
                        unless( m/\n/ ) {
                            s/^\s+//;
                            s/\s+$//;
                        }
                    }
                }
                return %r;
            }

            my @v = map { $_->{att}{$attr_query} } @c;
            $this->_data_error($rt, "expected single match for \"$query\", got " . @v) unless $opts->{nostrict} or @v==1;
            unless($opts->{notrim}) {
                unless( $v[0] =~ m/\n/ ) {
                    $v[0] =~ s/^\s+//;
                    $v[0] =~ s/\s+$//;
                }
            }
            return $v[0];
        }

        if( $context == LIST ) {
            return map { $_->text      } @c if $opts->{recurse_text};
            return map { $_->text_only } @c;

        } elsif( $context == KLIST ) {
            return map { $_->gi => $_->text      } @c if $opts->{recurse_text};
            return map { $_->gi => $_->text_only } @c;

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
                $_->gi => {map { $this->_execute_query($c, $opts, $_ => $res_type->{$_}, KLIST) } keys %$res_type}
            } @c;
        }

        $this->_data_error($rt, "expected single match for \"$query\", got " . @c) unless $opts->{nostrict} or @c==1;
        return {
            map { $this->_execute_query($c[0], $opts, $_ => $res_type->{$_}, KLIST) } keys %$res_type
        };

    } elsif( $rt eq "ARRAY" ) {
        my @p;
        while( my ($pat, $res) = splice @$res_type, 0, 2 ) {
            push @p, [$pat, $res];
        }

        if( $context == LIST ) {
            return map { my $c = $_; [ map {$this->_execute_query($c, $opts, @$_, LIST)} @p ] } @c;

        } elsif( $context == KLIST ) {
            return map {my $c = $_; $c->gi => [ map {$this->_execute_query($c, $opts, @$_, LIST)} @p ] } @c;
        }

        $this->_data_error($rt, "expected single match for \"$query\", got " . @c) unless $opts->{nostrict} or @c==1;
        return [ map {$this->_execute_query($c[0], $opts, @$_, LIST)} @p ];
    }

    XML::Twigx::CuteQueries::Error->new(text=>"unexpected condition met")->throw;
    return;
}
# }}}

sub cute_query {
    my $this = shift;
    my $opts = {};
       $opts = shift if ref $_[0] eq "HASH";

    for(keys %$opts) {
        $this->_query_error("no such query option \"$_\"") unless $VALID_OPTS{$_};
    }

    $this->_pre_parse_queries($opts, @_);

    my @result;

    while( my @q = splice @_, 0, 2 ) {
        push @result, scalar $this->_execute_query($this->root, $opts, @q);
    }

    return $result[0] unless wantarray; # we never want the size of the array
    return @result;
}

1;
