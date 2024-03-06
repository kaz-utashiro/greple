use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

my $sample = 't/SAMPLE.txt';

like(run('-e fox t/SAMPLE.txt')->stdout,
    qr/\AThe/, "normal");

like(run('-e fox -n t/SAMPLE.txt')->stdout,
    qr/\A2:The/, "-n");

like(run('-e fox -n --linestyle=separate t/SAMPLE.txt')->stdout,
    qr/\A2:$/m, "-n --ls=separate");

like(run('-e fox -H t/SAMPLE.txt')->stdout,
    qr/\A$sample\:The/, "-H");

like(run('-e fox -H --filestyle=separate t/SAMPLE.txt')->stdout,
    qr/\A$sample\:$/m, "-H --fs=seprate");

like(run('-e fox -nH t/SAMPLE.txt')->stdout,
    qr/\A$sample\:2:The/, "-nH");

like(run('-e fox -nH --separate t/SAMPLE.txt')->stdout,
    qr/\A$sample\:2:$/m, "-nH --seprate");

done_testing;
