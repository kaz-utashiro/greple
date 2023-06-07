use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

is(run(q[--need=1 -e fox t/SAMPLE.txt -o --callback 'sub{"1:".+{@_}->{match}}'])->stdout,
   "1:fox\n",
   "--callback");

is(run(q[--need=1 -e dog -e fox t/SAMPLE.txt -o --callback 'sub{"1:".+{@_}->{match}}' --callback 'sub{"2:".+{@_}->{match}}'])->stdout,
   "2:fox\n1:dog\n",
   "multiple --callback");

done_testing;
