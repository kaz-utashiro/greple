use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

sub lines {
    my $re = join('', '\A', map("$_:.*\\n", @_), '\\z');
    qr/$re/;
}

$ENV{NO_COLOR} = 1;

like(greple('--norc -Mline -L 2 t/SAMPLE.txt')->result,
     lines(2), "-L 2");

like(greple('--norc -Mline -L 2,4 t/SAMPLE.txt')->result,
     lines(2,4), "-L 2,4");

like(greple('--norc -Mline -L 2 -L 4 --need 1 t/SAMPLE.txt')->result,
     lines(2,4), "-L 2 -L 4 --need 1");

like(greple('--norc -Mline -L 2:4 t/SAMPLE.txt')->result,
     lines(2..4), "-L 2:4");

like(greple('--norc -Mline -L 2:+2 t/SAMPLE.txt')->result,
     lines(2..4), "-L 2:+2");

like(greple('--norc -Mline -L -26:4 t/SAMPLE.txt')->result,
     lines(2..4), "-L -26:4");

like(greple('--norc -Mline -L -26:+2 t/SAMPLE.txt')->result,
     lines(2..4), "-L -26:+2");

like(greple('--norc -Mline -L :: t/SAMPLE.txt')->result,
     lines(1..28), "-L ::");

like(greple('--norc -Mline -L ::2 t/SAMPLE.txt')->result,
     lines(map $_ * 2 - 1, 1..14), "-L ::2");

like(greple('--norc -Mline -L 2::2 t/SAMPLE.txt')->result,
     lines(map $_ * 2, 1..14), "-L 2::2");


like(greple('--norc -Mline --inside L=2:4 a t/SAMPLE.txt')->result,
     lines(3), "--inside L=2:4");

done_testing;
