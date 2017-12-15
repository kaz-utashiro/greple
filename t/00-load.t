use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Greple' ) || print "Bail out!\n";
}

diag( "Testing App::Greple $App::Greple::VERSION, Perl $], $^X" );
