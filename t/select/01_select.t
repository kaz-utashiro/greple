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

done_testing;
