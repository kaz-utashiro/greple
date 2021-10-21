use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8', ':std';

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

is(greple('-Mselect -e l -wall=0 --suffix=txt --glob t/*')->stdout,
   greple(         '-e l -wall=0              --glob t/*.txt')->stdout,
   "--suffix=txt");

is(greple('-Mselect -e ^use -m1 -wall=0 --select-data="\\\\A.*strict" --glob t/*.t')->stdout,
   greple(         '-wall=0 --re="\\\\A.*strict" --glob t/*.t')->stdout,
   "--select-data");

is(greple('-Mselect -wall=0 -l --glob t/*.{t}        ^')->stdout,
   greple('-Mselect -wall=0 -l --glob t/*.{pm,t,txt} ^ --select-data Test::More')->stdout,
   "--select-data");

is(greple('-Mselect -wall=0 -l --glob t/*.{pm,txt}   ^')->stdout,
   greple('-Mselect -wall=0 -l --glob t/*.{pm,t,txt} ^ --x-select-data Test::More')->stdout,
   "--x-select-data");

is(greple('-Mselect -wall=0 -l --glob t/*.{pm,t,txt} ^ --suffix=pm')->stdout,
   greple('-Mselect -wall=0 -l --glob t/*.{pm,t,txt} ^ --suffix=pm,t --x-suffix t')->stdout,
   "--suffix & --x-suffix");

done_testing;
