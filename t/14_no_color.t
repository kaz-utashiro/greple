use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

my $color   = greple(q(イーハトーヴォ t/JA.txt))->result;
my $nocolor = greple(q(イーハトーヴォ t/JA.txt --nocolor))->result;

is(greple(q(イーハトーヴォ t/JA.txt))->result, $color, "default");

$ENV{NO_COLOR} = 1;

is(greple(q(イーハトーヴォ t/JA.txt))->result, $nocolor, "NO_COLOR");

$ENV{GETOPTEX_NO_NO_COLOR} = 1;

is(greple(q(イーハトーヴォ t/JA.txt))->result, $color, "NO_COLOR with NO_NO_COLOR");

done_testing;
