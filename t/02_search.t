use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

like(run('-e "fox" t/SAMPLE.txt')->stdout,
     qr/\A(.*\n){1}\z/, "simple");

like(run('-e "fox\\\\n" t/SAMPLE.txt')->stdout,
     qr/\A(.*\n){1}\z/, "end with newline");

like(run('--re "^The.*\\\\n\\\\Kjumps" t/SAMPLE.txt')->stdout,
     qr/\A(.*\n){1}\z/, "\\K");

like(run('-e "fox jumps" t/SAMPLE.txt')->stdout,
     qr/\A(.*\n){2}\z/, "multi-line");

like(run('-e ^ t/SAMPLE.txt')->stdout,
     qr/\A(.*\n){28}\z/, "-e ^");

is(run('-e "^" /dev/null')->stdout,
     '', "-e ^ /dev/null");

is(run('-e "\\\\z" t/SAMPLE.txt')->stdout,
     '', "-e \\z");

is(run('-e ^ --color=never t/SAMPLE.txt')->stdout,
     `cat t/SAMPLE.txt`, "-e ^ --color=never");

done_testing;
