
use Test;
use XML::Twigx::CuteQueries;

my $CQ = XML::Twigx::CuteQueries->new;
   $CQ->parsefile("example.xml");

plan tests => 1;

ok( $CQ->cute_query(result=>''), 'OK' );
