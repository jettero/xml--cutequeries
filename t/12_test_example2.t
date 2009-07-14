
use strict;
use Test;
use XML::CuteQueries;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new->parsefile("example2.xml");

plan tests => 1;

my @fields = map { ("field-of-interest$_" => "data") } (1 .. 8, 10 .. 14);

WITHOUT_RE: {
    my %result   = $CQ->hash_query( '<nre>field-of-interest(?:9|15)' => '' );
    my $exemplar = { result => "OK", @fields };

    ok( Dumper($exemplar), Dumper(\%result) );
}

