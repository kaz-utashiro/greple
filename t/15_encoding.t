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

like(run(q(--icode guess いろは t/SAMPLE_euc-jp.txt))->stdout,
     qr/いろは/, "guess euc");

like(run(q(--icode shift-jis いろは t/SAMPLE_sjis.txt))->stdout,
     qr/いろは/, "shift-jis");

like(run(q(--icode +shift-jis いろは t/SAMPLE_sjis.txt))->stdout,
     qr/いろは/, "guess shift-jis");

done_testing;
