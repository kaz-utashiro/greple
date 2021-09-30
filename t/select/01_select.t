use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8', ':std';

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

is(greple('-Mselect -e l -wall=0 --suffix=txt --glob t/*')->result,
   greple(         '-e l -wall=0              --glob t/*.txt')->result,
   "--suffix=txt");

is(greple('-Mselect -e ^use -m1 -wall=0 --select-data="\\\\A.*strict" --glob t/*.t')->result,
   greple(         '-wall=0 --re="\\\\A.*strict" --glob t/*.t')->result,
   "--select-data");

is(greple('-Mselect -wall=0 -l --glob t/*.{t}        ^')->result,
   greple('-Mselect -wall=0 -l --glob t/*.{pm,t,txt} ^ --select-data Test::More')->result,
   "--select-data");

is(greple('-Mselect -wall=0 -l --glob t/*.{pm,txt}   ^')->result,
   greple('-Mselect -wall=0 -l --glob t/*.{pm,t,txt} ^ --x-select-data Test::More')->result,
   "--x-select-data");

is(greple('-Mselect -wall=0 -l --glob t/*.{pm,t,txt} ^ --suffix=pm')->result,
   greple('-Mselect -wall=0 -l --glob t/*.{pm,t,txt} ^ --suffix=pm,t --x-suffix t')->result,
   "--suffix & --x-suffix");

done_testing;
