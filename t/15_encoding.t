use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

like(run(q(--icode euc-jp いろは t/SAMPLE_euc-jp.txt))->stdout,
     qr/いろは/, "euc-jp");

done_testing;
