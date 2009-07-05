use Test;
use XML::Twigx::CuteQueries;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::Twigx::CuteQueries->new->parse("<r> <x> 7</x> <x>\n  7  \n</x></r>");

plan tests => 2;

ok( Dumper($CQ->cute_query({notrim=>1}, '.'=>[x=>''])), Dumper([' 7', "\n  7  \n"]) );
ok( Dumper($CQ->cute_query('.'=>[x=>''])), Dumper([' 7', "\n  7  \n"]) );
