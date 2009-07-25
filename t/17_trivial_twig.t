
use strict;
use Test;
use XML::CuteQueries;

plan tests=>1;

my @a = map {$_->gi . $_->xml_string} XML::CuteQueries->new->parse("<r><x>1</x><y>2</y></r>")->cute_query('*'=>'t');
ok( "@a", "x1 y2" );
