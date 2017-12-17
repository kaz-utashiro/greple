use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use t::Util;

like(greple(q(イーハトーヴォ t/JA.txt))->result,
     qr/(?s:.*イーハトーヴォ){2}/, "Japanese");

like(greple(q("イーハトーヴォ 五月"  t/JA.txt))->result,
     qr/\Aしずかに.*\n\z/, "lexical AND");

like(greple(q("イーハトーヴォ -五月" t/JA.txt))->result,
     qr/\Aあの.*\n\z/, "lexical NOT");

TODO: {
    local $TODO = "blank line at the top is included in paragraph.";
    like(greple(q("イーハトーヴォ モリーオ" -p t/JA.txt))->result,
	 qr/\A(.*\n){4}--\n\z/, "lexical AND with -p");
}

like(greple(q("ファゼーロ ロザーロ" -p t/JA.txt))->result,
     qr/\A(.*\n){6}--\n\z/, "lexical AND with -p");

like(greple(q("イーハトーヴォ -モリーオ" -p t/JA.txt))->result,
     qr/\A(.*\n){2}--\n\z/, "lexical NOT with -p");

like(greple(q(イーハトーヴォ --paragraph t/JA.txt))->result,
     qr/(^.*\n){4}--\n(^.*\n){2}--\n/m, "paragraph mode");

like(greple(q(-e "青いそら、 うつくしい森" t/JA.txt))->result,
     qr/\A(.*\n){2}\z/, "multi-line");

like(greple(q(-e "青いそら、 うつくしい森" --join t/JA.txt))->result,
     qr/青いそら、うつくしい森/, "--join");

is(greple(q(-e "青いそら" --only --color=never t/JA.txt))->result,
     "青いそら\n", "--only");

is(greple(q(-e "イーハトーヴォ" --only --color=never t/JA.txt))->result,
     "イーハトーヴォ\n" x 2, "--only (2)");

is(greple(q(-e "イーハトーヴォ" --only --color=never --max 1 t/JA.txt))->result,
     "イーハトーヴォ\n", "--max 1");

like(greple(q(-e "山猫博士" --context --color=never t/JA.txt))->result,
     qr/\A(.*\n){5}--\n\z/, "--context");

like(greple(q(-e "山猫博士" --after=1 --color=never t/JA.txt))->result,
     qr/\A(山猫博士.*\n)(.*\n)--\n\z/, "--after=1");

like(greple(q(-e "山猫博士" --before=1 --color=never t/JA.txt))->result,
     qr/\A(.*\n)(山猫博士.*\n)--\n\z/, "--before=1");

done_testing;
