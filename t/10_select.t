use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

like(greple(q(-f t/JA.txt t/JA.txt))->stdout,
     qr/\A(?:.*\n){12}\z/, "-f");

like(greple(q(-f t/JA.txt --select 1 t/JA.txt))->stdout,
     qr/\A(?:.*\n){1}\z/, "-f and --select 1");

like(greple(q(-f t/JA.txt --select 1,3:5 t/JA.txt))->stdout,
     qr/\A(?:.*\n){4}\z/, "-f and --select 1,3:5");

like(greple(q(-f t/JA.txt[1,3:5] t/JA.txt))->stdout,
     qr/\A(?:.*\n){4}\z/, "-f and --select 1,3:5");


like(greple(q(-f t/JA.txt --select :5 t/JA.txt))->stdout,
     qr/\A(?:.*\n){5}\z/, "-f and --select :5");

like(greple(q(-f t/JA.txt --select 5: t/JA.txt))->stdout,
     qr/\A(?:.*\n){8}\z/, "-f and --select 5:");

done_testing;
