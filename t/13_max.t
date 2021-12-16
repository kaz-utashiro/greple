use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

is(run('-e ^ -m 10 t/SAMPLE.txt')->stdout,
   run('-Mline --no-n -L 1:10 t/SAMPLE.txt')->stdout,
   "-m 10");

is(run('-e ^ -m 0,10 t/SAMPLE.txt')->stdout,
   run('-Mline --no-n -L 11: t/SAMPLE.txt')->stdout,
   "-m 0,10");

is(run('-e ^ -m -10 t/SAMPLE.txt')->stdout,
   run('-Mline --no-n -L 1:-10 t/SAMPLE.txt')->stdout,
   "-m -10");

is(run('-e ^ -m 0,10,10 t/SAMPLE.txt')->stdout,
   run('-Mline --no-n -L 11:20 t/SAMPLE.txt')->stdout,
   "-m 0,10,10");

is(run('-e ^ -m 20,,,-10 t/SAMPLE.txt')->stdout,
   run('-Mline --no-n -L 11:20 t/SAMPLE.txt')->stdout,
   "-m 20,,,-10");

done_testing;
