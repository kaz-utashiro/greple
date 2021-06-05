use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

like(greple('-e "thorn" t/Checker.pm')->result,
     qr/^SKIP/, "w/o --persist");

like(greple('-e "thorn" --persist t/Checker.pm')->result,
     qr/thorn/, "w/ --persist");

done_testing;
