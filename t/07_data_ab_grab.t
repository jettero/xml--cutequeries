
use Test;
use XML::Twigx::CuteQueries;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::Twigx::CuteQueries->new;
   $CQ->parsefile("example.xml");

my $exemplar1 = Dumper([ 
    "this'll be hard to fetch I think",
    'I may need special handlers for @queries',
]);

my $exemplar2 = Dumper({ 
    a => "this'll be hard to fetch I think",
    b => 'I may need special handlers for @queries',
});

my $actual1 = $CQ->cute_query(data=>['@a'=>'', '@b'=>'']);
my $actual2 = $CQ->cute_query(data=>{'@*'=>''});

plan tests => 2;

ok( $actual1, $exemplar1 );
ok( $actual2, $exemplar2 );
