
use strict;
use Test;
use XML::CuteQueries;

my $CQ = XML::CuteQueries
    ->new->parse("<r><p>Slow <em>down</em> there dude.</p></r>");

plan tests => 2;

ok( $CQ->cute_query(p=>''), "Slow  there dude." );
ok( $CQ->cute_query({recurse_text=>1}, p=>''), "Slow down there dude." );

