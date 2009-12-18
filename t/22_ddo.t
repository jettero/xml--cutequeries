use strict;
use Test;
use XML::CuteQueries;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new->parsefile("ddo.xml");

plan tests => 1;

ok( $CQ->cute_query( '//feed/@xml:base'=>'' ), "http://www.ddo.com/news" );
