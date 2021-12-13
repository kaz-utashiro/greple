use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

my $color   = greple(q(イーハトーヴォ t/JA.txt --color=always))->stdout;
my $nocolor = greple(q(イーハトーヴォ t/JA.txt --nocolor))->stdout;
my $sub_cm  = greple(q(イーハトーヴォ t/JA.txt --cm 'sub{"[$_]"}'))->stdout;

if (-t STDOUT) {
    is(greple(q(イーハトーヴォ t/JA.txt))->stdout,
       $color,
       "default (tty)");
}

$ENV{NO_COLOR} = 1;

is(greple(q(イーハトーヴォ t/JA.txt))->stdout, $nocolor, "NO_COLOR");

is(greple(q(イーハトーヴォ t/JA.txt --cm 'sub{"[$_]"}'))->stdout,
   $sub_cm , "functional colormap still works");

$ENV{GETOPTEX_NO_NO_COLOR} = 1;

if (-t STDOUT) {
    is(greple(q(イーハトーヴォ t/JA.txt))->stdout,
       $color,
       "NO_COLOR with NO_NO_COLOR (tty)");
}

done_testing;
