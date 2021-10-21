use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

like(greple('-e o --matchcount=5 t/SAMPLE.txt')->stdout,
     qr/\A(.*\n){1}\z/, "--matchcount 5");

like(greple('-e o --matchcount=5, t/SAMPLE.txt')->stdout,
     qr/\A(.*\n){1}\z/, "--matchcount 5,");

like(greple('-e o --matchcount=3,4 t/SAMPLE.txt')->stdout,
     qr/\A(.*\n){2}\z/, "--matchcount 3,4");

like(greple('-e o --matchcount=,1 t/SAMPLE.txt')->stdout,
     qr/\A(.*\n){1}\z/, "--matchcount ,1");

done_testing;
