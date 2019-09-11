use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8', ':std';

use lib '.';
use t::Util;

like(greple('--if "cat -n" -e "fox" t/SAMPLE.txt')->result,
     qr/\A\s*2\b/, "--if");

like(greple('--of "cat -n" -e "fox" t/SAMPLE.txt t/SAMPLE.txt')->result,
     qr/\A(\s*1\b.*\n){2}\z/, "--of");

like(greple('--pf "cat -n" -e "fox" t/SAMPLE.txt t/SAMPLE.txt')->result,
     qr/\A(\s*1\b.*\n)(\s*2\b.*\n)\z/, "--pf");

done_testing;
