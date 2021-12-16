use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

like(run('-e o --matchcount=7 t/SAMPLE.txt')->stdout,
     line(1), "--matchcount 7");

like(run('-e o --matchcount=5, t/SAMPLE.txt')->stdout,
     line(1), "--matchcount 5,");

like(run('-e o --matchcount=3,4 t/SAMPLE.txt')->stdout,
     line(2), "--matchcount 3,4");

like(run('-e o --matchcount=,1 t/SAMPLE.txt')->stdout,
     line(1), "--matchcount ,1");

like(run('-e o --matchcount=1,1,3,4 t/SAMPLE.txt')->stdout,
     line(3), "--matchcount 1,1,3,4");

like(run('-e o --matchcount=1,1,3, t/SAMPLE.txt')->stdout,
     line(4), "--matchcount 1,1,3,");

like(run('-e o --matchcount=1,1,3 t/SAMPLE.txt')->stdout,
     line(4), "--matchcount 1,1,3");

like(run('-e g --matchcount=2,2 t/SAMPLE.txt --inside .+')->stdout,
     line(2), "--matchcount with --inside");

# error case

isnt(run('-e o --matchcount=3:4 t/SAMPLE.txt')->status,
     0, "--matchcount 3:4");

done_testing;
