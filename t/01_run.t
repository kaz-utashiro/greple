use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';
use Text::ParseWords;

use lib '.';
use t::Util;

my $lib    = File::Spec->rel2abs('lib');
my $greple = File::Spec->rel2abs('script/greple');

is(run()->status, 2, "command syntax error");
is(run('fox t/SAMPLE.txt')->status, 0, "normal exit");
is(run('-e "fox jumps" t/SAMPLE.txt')->status, 0, "-e option normal");
is(run('-e "raccoon jumps" t/SAMPLE.txt')->status, 1, "not found");
is(run('-e "raccoon jumps" --exit=0 t/SAMPLE.txt')->status, 0, "--exit=0");
is(run('-e "raccoon jumps" --exit=255 t/SAMPLE.txt')->status, 255, "--exit=255");
ok(run('-e "(" t/SAMPLE.txt')->status > 1, "regexe error");
ok(run('-e "(" t/SAMPLE.txt --exit=0')->status > 1, "regexe error with --exit=0");

done_testing;
