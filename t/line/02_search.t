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

like(run('--norc -Mline -n -L 2 t/SAMPLE.txt')->stdout,
     lines(2), "-L 2");

like(run('--norc -Mline -n -L 2,4 t/SAMPLE.txt')->stdout,
     lines(2,4), "-L 2,4");

like(run('--norc -Mline -n -L 2 -L 4 --need 1 t/SAMPLE.txt')->stdout,
     lines(2,4), "-L 2 -L 4 --need 1");

like(run('--norc -Mline -n -L 2:4 t/SAMPLE.txt')->stdout,
     lines(2..4), "-L 2:4");

like(run('--norc -Mline -n -L 2:+2 t/SAMPLE.txt')->stdout,
     lines(2..4), "-L 2:+2");

like(run('--norc -Mline -n -L -26:4 t/SAMPLE.txt')->stdout,
     lines(2..4), "-L -26:4");

like(run('--norc -Mline -n -L -26:+2 t/SAMPLE.txt')->stdout,
     lines(2..4), "-L -26:+2");

like(run('--norc -Mline -n -L :: t/SAMPLE.txt')->stdout,
     lines(1..28), "-L ::");

like(run('--norc -Mline -n -L ::2 t/SAMPLE.txt')->stdout,
     lines(map $_ * 2 - 1, 1..14), "-L ::2");

like(run('--norc -Mline -n -L 2::2 t/SAMPLE.txt')->stdout,
     lines(map $_ * 2, 1..14), "-L 2::2");

like(run('--norc -Mline -n --inside L=2:4 a t/SAMPLE.txt')->stdout,
     lines(3), "--inside L=2:4");

like(run('--norc -Mline 2::2 -n t/SAMPLE.txt')->stdout,
     lines(map $_ * 2, 1..14), "-Mline 2::2");

like(run('--norc -Mline --offload "seq 2 4" -n t/SAMPLE.txt')->stdout,
     lines(2..4), '-Mline --offload "seq 2 4"');

done_testing;
