
use Test;
use XML::Twigx::CuteQueries;

plan tests => 4;

my $CQ = XML::Twigx::CuteQueries->new;
 # $CQ->parse("something.xml");

eval { $CQ->cute_query(1,2,3) };

ok( $@ !~ m/UNKNOWN/i ) or warn " \e[1;33m$@\e[m"; 
ok( $@, qr/QUERY ERROR.*odd/ );
ok( $@->type, XML::Twigx::CuteQueries::Error::QUERY_ERROR );
ok( $@->query_error );
