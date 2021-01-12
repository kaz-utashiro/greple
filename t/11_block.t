use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8', ':std';

use lib '.';
use t::Util;

like(greple(qw{ ox --block ^.*\P{ASCII}.* --color=never t/SAMPLE.txt })->result,
     qr/\A(.*\n){1}--\n\z/, "--block");

like(greple(qw{ ox --block ^.*\P{ASCII}.* --color=never -C1 t/SAMPLE.txt })->result,
     qr/\A(?:(?:.*\n){1}--\n){3}\z/, "--block -C1");

like(greple(qw{ fox --block .* -C1 --color=never t/SAMPLE.txt })->result,
     qr/\A(?:(?:.*\n){1}--\n){2}\z/, "--block -C1 (block 0)");

like(greple(qw{ tocaba --block .* -C1 --color=never t/SAMPLE.txt })->result,
     qr/\A(?:(?:.*\n){1}--\n){2}\z/, "--block -C1 (last block)");

like(greple(qw{ -e イーハトーヴォ -e モリーオ --color=never --block (?:.+\\n)+ t/JA.txt })->result,
     qr/\A(.*\n){4}--\n\z/, "--block with Japanese");

done_testing;
