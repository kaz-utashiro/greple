use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

like(greple(q(イーハトーヴォ t/JA.txt))->stdout,
     qr/(?s:.*イーハトーヴォ){2}/, "Japanese");

like(greple(q("イーハトーヴォ 五月"  t/JA.txt))->stdout,
     qr/\Aしずかに.*\n\z/, "lexical AND");

like(greple(q("イーハトーヴォ -五月" t/JA.txt))->stdout,
     qr/\Aあの.*\n\z/, "lexical NOT");

like(greple(q("イーハトーヴォ モリーオ" -p t/JA.txt))->stdout,
     qr/\A(.*\n){4}--\n\z/, "lexical AND with -p with single blank line");

like(greple(q("ファゼーロ ロザーロ" -p t/JA.txt))->stdout,
     qr/\A(.*\n){6}--\n\z/, "lexical AND with -p");

like(greple(q("イーハトーヴォ -モリーオ" -p t/JA.txt))->stdout,
     qr/\A(.*\n){2}--\n\z/, "lexical NOT with -p");

like(greple(q(イーハトーヴォ --paragraph t/JA.txt))->stdout,
     qr/(^.*\n){4}--\n(^.*\n){2}--\n/m, "paragraph mode");

like(greple(q(-e "青いそら、 うつくしい森" t/JA.txt))->stdout,
     qr/\A(.*\n){2}\z/, "multi-line");

like(greple(q(-e "青いそら、 うつくしい森" --join t/JA.txt))->stdout,
     qr/青いそら、うつくしい森/, "--join");

is(greple(q(-e "青いそら" --only t/JA.txt))->stdout,
     "青いそら\n", "--only");

is(greple(q(-e "イーハトーヴォ" --only t/JA.txt))->stdout,
     "イーハトーヴォ\n" x 2, "--only (2)");

is(greple(q(-e "イーハトーヴォ" --only --max 1 t/JA.txt))->stdout,
     "イーハトーヴォ\n", "--max 1");

like(greple(q(-e "山猫博士" --context t/JA.txt))->stdout,
     qr/\A(.*\n){5}--\n\z/, "--context");

like(greple(q(-e "山猫博士" --after=1 t/JA.txt))->stdout,
     qr/\A(山猫博士.*\n)(.*\n)--\n\z/, "--after=1");

like(greple(q(-e "山猫博士" --before=1 t/JA.txt))->stdout,
     qr/\A(.*\n)(山猫博士.*\n)--\n\z/, "--before=1");

done_testing;
