use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';
use t::Util;

use Text::ParseWords;

my $lib    = File::Spec->rel2abs('lib');
my $greple = File::Spec->rel2abs('script/greple');

is(greple()->status, 2);
is(greple('fox t/SAMPLE.txt')->status, 0);
is(greple('-e "fox jumps" t/SAMPLE.txt')->status, 0);
is(greple('-e "raccoon jumps" t/SAMPLE.txt')->status, 1);

done_testing;
