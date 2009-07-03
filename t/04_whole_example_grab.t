
use Test;
use XML::Twigx::CuteQueries;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::Twigx::CuteQueries->new;
   $CQ->parsefile("example.xml");

my $h = Dumper([ 'OK', [
        {f1=> 7, f2=>11, f3=>13},
        {f1=>17, f2=>19, f3=>23},
        {f1=>29, f2=>31, f3=>37},

    ], { row => [qw(503 509)] },
]);

my $j = Dumper([ $CQ->cute_query(
    result       => '',
    data         => [{'*'=>''}],
    'other-data' => {row=>[f1=>'']},
)]);

plan tests => 1;
ok( $j, $h );
