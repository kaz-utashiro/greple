use 5.014;
use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
    App::Greple
    App::Greple::Common
    App::Greple::Filter
    App::Greple::Grep
    App::Greple::Pattern
    App::Greple::Pattern::Holder
    App::Greple::PgpDecryptor
    App::Greple::Regions
    App::Greple::Util
    App::Greple::colors
    App::Greple::debug
    App::Greple::dig
    App::Greple::find
    App::Greple::perl
    App::Greple::pgp
    App::Greple::select
);

diag( "Testing App::Greple $App::Greple::VERSION, Perl $^V, $^X" );

done_testing;
