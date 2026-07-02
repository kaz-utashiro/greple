use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

##
## Tests for block slicing in the output routine.
##

# overlapping matches with -o are merged into a single region
is(run('--color=never -o -e "quick brown" -e "brown fox" t/SAMPLE.txt')->stdout,
   "quick brown fox\n", "-o with overlapping patterns");

# adjacent matches with -o
is(run('--color=never -o -e quick -e brown t/SAMPLE.txt')->stdout,
   "quick\nbrown\n", "-o with adjacent patterns");

# line numbers over multiple blocks
is(run('--color=never -n -e "fox|dog|いろは" t/SAMPLE.txt')->stdout,
   "2:The quick brown fox\n" .
   "3:jumps over the lazy dog.\n" .
   "6:いろはにほへと　ちりぬるを\n", "-n line numbers");

# context lines do not disturb line numbers
is(run('--color=never -n -A1 -e fox t/SAMPLE.txt')->stdout,
   "2:The quick brown fox\n" .
   "3:jumps over the lazy dog.\n" .
   "--\n", "-n with -A1");

# whole line output with Japanese text
is(run('--color=never -e 色は t/SAMPLE.txt')->stdout,
   "色は匂へど　散りぬるを\n", "Japanese block");

done_testing;
