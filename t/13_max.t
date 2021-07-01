use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

is(greple('--nocolor -e ^ -m 10 t/SAMPLE.txt')->result,
   greple('-Mline --nocolor --no-n -L 1:10 t/SAMPLE.txt')->result,
   "-m 10");

is(greple('--nocolor -e ^ -m 0,10 t/SAMPLE.txt')->result,
   greple('-Mline --nocolor --no-n -L 11: t/SAMPLE.txt')->result,
   "-m 0,10");

is(greple('--nocolor -e ^ -m -10 t/SAMPLE.txt')->result,
   greple('-Mline --nocolor --no-n -L 1:-10 t/SAMPLE.txt')->result,
   "-m -10");

is(greple('--nocolor -e ^ -m 0,10,10 t/SAMPLE.txt')->result,
   greple('-Mline --nocolor --no-n -L 11:20 t/SAMPLE.txt')->result,
   "-m 0,10,10");

is(greple('--nocolor -e ^ -m 20,,,-10 t/SAMPLE.txt')->result,
   greple('-Mline --nocolor --no-n -L 11:20 t/SAMPLE.txt')->result,
   "-m 20,,,-10");

done_testing;
