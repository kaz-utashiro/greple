use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8', ':std';

use lib '.';
use t::Util;

is(greple('-Mselect --nocolor -e l -wall=0 --suffix=txt --glob t/*')->result,
   greple(         '--nocolor -e l -wall=0              --glob t/*.txt')->result,
   "--suffix=txt");

is(greple('-Mselect --nocolor -e ^use -m1 -wall=0 --select-data="\\\\A.*strict" --glob t/*.t')->result,
   greple(         '--nocolor -wall=0 --re="\\\\A.*strict" --glob t/*.t')->result,
   "--select-data");

is(greple('-Mselect --nocolor -wall=0 -l --glob t/*.{t}        ^')->result,
   greple('-Mselect --nocolor -wall=0 -l --glob t/*.{pm,t,txt} ^ --select-data Test::More')->result,
   "--select-data");

is(greple('-Mselect --nocolor -wall=0 -l --glob t/*.{pm,txt}   ^')->result,
   greple('-Mselect --nocolor -wall=0 -l --glob t/*.{pm,t,txt} ^ --x-select-data Test::More')->result,
   "--x-select-data");

is(greple('-Mselect --nocolor -wall=0 -l --glob t/*.{pm,t,txt} ^ --suffix=pm')->result,
   greple('-Mselect --nocolor -wall=0 -l --glob t/*.{pm,t,txt} ^ --suffix=pm,t --x-suffix t')->result,
   "--suffix & --x-suffix");

done_testing;
