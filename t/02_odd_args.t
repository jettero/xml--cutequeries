
use Test;
use XML::Twigx::CuteQueries;

plan tests => 2;

my $CQ = XML::Twigx::CuteQueries->new;
 # $CQ->parse("something.xml");

eval { $CQ->cute_query(1,2,3) };

ok( $@, qr/QUERY ERROR.*odd/ );
ok( $@->query_error );
