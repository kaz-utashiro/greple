use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

like(run(q(-f t/JA.txt t/JA.txt))->stdout,
     qr/\A(?:.*\n){12}\z/, "-f");

like(run(q(-f t/JA.txt --select 2 t/JA.txt))->stdout,
     qr/\A(?:.*\n){1}\z/, "-f and --select 2");

like(run(q(-f t/JA.txt --select 2,7:9 t/JA.txt))->stdout,
     qr/\A(?:.*\n){4}\z/, "-f and --select 2,7:9");

like(run(q(-f t/JA.txt[2,7:9] t/JA.txt))->stdout,
     qr/\A(?:.*\n){4}\z/, "-f and --select 2,7:9");


like(run(q(-f t/JA.txt --select :7 t/JA.txt))->stdout,
     qr/\A(?:.*\n){5}\z/, "-f and --select :7");

like(run(q(-f t/JA.txt --select 7: t/JA.txt))->stdout,
     qr/\A(?:.*\n){8}\z/, "-f and --select 7:");

done_testing;
