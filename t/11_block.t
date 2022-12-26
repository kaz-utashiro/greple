use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8', ':std';

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

like(run(qw{ ox --block ^.*\P{ASCII}.* t/SAMPLE.txt })->stdout,
     qr/\A(.*\n){1}--\n\z/, "--block");

like(run(qw{ ox --block ^.*\P{ASCII}.* -C1 t/SAMPLE.txt })->stdout,
     qr/\A(?:(?:.*\n){1}--\n){3}\z/, "--block -C1");

like(run(qw{ fox --block .* -C1 t/SAMPLE.txt })->stdout,
     qr/\A(?:(?:.*\n){1}--\n){2}\z/, "--block -C1 (block 0)");

like(run(qw{ tocaba --block .* -C1 t/SAMPLE.txt })->stdout,
     qr/\A(?:(?:.*\n){1}--\n){2}\z/, "--block -C1 (last block)");

is(run(qw{ -e fox --block . --blockend= t/SAMPLE.txt })->stdout,
     "f\no\nx\n", "--block . (shorter block)");

is(run(qw{ -e いろは --block .. --blockend= t/SAMPLE.txt --cs "[$_]" })->stdout,
     "[いろ]\n[は]に\n", "--block .. (overflowed shorter block)");

like(run(qw{ -e イーハトーヴォ -e モリーオ --block (?:.+\\n)+ t/JA.txt })->stdout,
     qr/\A(.*\n){4}--\n\z/, "--block with Japanese");

like(run(qw{ -i the --blockend=-- --join-blocks t/SAMPLE.txt })->stdout,
     qr/\A.*the.*\n.*the.*\n--\n/i, "--join-blocks");

done_testing;
