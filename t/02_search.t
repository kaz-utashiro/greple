use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

like(greple('-e "fox" t/SAMPLE.txt')->result,
     qr/\A(.*\n){1}\z/, "simple");

like(greple('-e "fox\\\\n" t/SAMPLE.txt')->result,
     qr/\A(.*\n){1}\z/, "end with newline");

like(greple('--re "^The.*\\\\n\\\\Kjumps" t/SAMPLE.txt')->result,
     qr/\A(.*\n){1}\z/, "\\K");

like(greple('-e "fox jumps" t/SAMPLE.txt')->result,
     qr/\A(.*\n){2}\z/, "multi-line");

like(greple('-e ^ t/SAMPLE.txt')->result,
     qr/\A(.*\n){28}\z/, "-e ^");

is(greple('-e ^ --color=never t/SAMPLE.txt')->result,
     `cat t/SAMPLE.txt`, "-e ^ --color=never");

done_testing;
