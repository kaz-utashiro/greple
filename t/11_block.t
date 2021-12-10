use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8', ':std';

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

like(greple(qw{ ox --block ^.*\P{ASCII}.* t/SAMPLE.txt })->stdout,
     qr/\A(.*\n){1}--\n\z/, "--block");

like(greple(qw{ ox --block ^.*\P{ASCII}.* -C1 t/SAMPLE.txt })->stdout,
     qr/\A(?:(?:.*\n){1}--\n){3}\z/, "--block -C1");

like(greple(qw{ fox --block .* -C1 t/SAMPLE.txt })->stdout,
     qr/\A(?:(?:.*\n){1}--\n){2}\z/, "--block -C1 (block 0)");

like(greple(qw{ tocaba --block .* -C1 t/SAMPLE.txt })->stdout,
     qr/\A(?:(?:.*\n){1}--\n){2}\z/, "--block -C1 (last block)");

is(greple(qw{ -e fox --block . --blockend= t/SAMPLE.txt })->stdout,
     "f\no\nx\n", "--block . (shorter block)");

is(greple(qw{ -e いろは --block .. --blockend= t/SAMPLE.txt --cm sub{"[$_]"} })->stdout,
     "[いろ]\n[は]に\n", "--block . (overflowed shorter block)");

like(greple(qw{ -e イーハトーヴォ -e モリーオ --block (?:.+\\n)+ t/JA.txt })->stdout,
     qr/\A(.*\n){4}--\n\z/, "--block with Japanese");

done_testing;
