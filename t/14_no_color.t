use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

my $color   = run(q(イーハトーヴォ t/JA.txt --color=always))->stdout;
my $nocolor = run(q(イーハトーヴォ t/JA.txt --nocolor))->stdout;
my $sub_cm  = run(q(イーハトーヴォ t/JA.txt --cm 'sub{"[$_]"}'))->stdout;

SKIP: {
    skip 'STDOUT is not a tty.', 1 unless -t STDOUT;
    is(run(q(イーハトーヴォ t/JA.txt))->stdout,
       $color,
       "default (tty)");
}

$ENV{NO_COLOR} = 1;

is(run(q(イーハトーヴォ t/JA.txt))->stdout, $nocolor, "NO_COLOR");

is(run(q(イーハトーヴォ t/JA.txt --cm 'sub{"[$_]"}'))->stdout,
   $sub_cm , "functional colormap still works");

$ENV{GETOPTEX_NO_NO_COLOR} = 1;

SKIP: {
    skip 'STDOUT is not a tty.', 1 unless -t STDOUT;
    is(run(q(イーハトーヴォ t/JA.txt))->stdout,
       $color,
       "NO_COLOR with NO_NO_COLOR (tty)");
}

done_testing;
