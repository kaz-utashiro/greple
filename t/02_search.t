use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

like(run('-e "fox" t/SAMPLE.txt')->stdout,
     line(1), "simple");

like(run('-e "fox\\\\n" t/SAMPLE.txt')->stdout,
     line(1), "end with newline");

like(run('--re "^The.*\\\\n\\\\Kjumps" t/SAMPLE.txt')->stdout,
     line(1), "\\K");

like(run('-e "fox jumps" t/SAMPLE.txt')->stdout,
     line(2), "multi-line");

like(run('-e ^ t/SAMPLE.txt')->stdout,
     line(28), "-e ^");

is(run('-e "^" /dev/null')->stdout,
     '', "-e ^ /dev/null");

is(run('-e "\\\\z" t/SAMPLE.txt')->stdout,
     '', "-e \\z");

is(run('-e ^ --color=never t/SAMPLE.txt')->stdout,
     `cat t/SAMPLE.txt`, "-e ^ --color=never");

# --or

like(run('--or dog --or fox t/SAMPLE.txt')->stdout,
     line(2), "--or");

# --and

like(run('-i --and the --and fox t/SAMPLE.txt')->stdout,
     line(1), "--and");

# --must

like(run('-i --must the --and fox t/SAMPLE.txt')->stdout,
     line(2), "--must");

# -o / --all

like(run('--and fox --and dog t/SAMPLE.txt')->stdout,
     line(0), "fox and dog");

# -o does not change matching behabior
like(run('--and fox --and dog -o t/SAMPLE.txt')->stdout,
     line(0), "fox and dog with -o");

# --all does not change matching behabior
like(run('--and fox --and dog --all t/SAMPLE.txt')->stdout,
     line(0), "fox and dog with --all");

like(run('--and fox --and dog --border "\A" -o t/SAMPLE.txt')->stdout,
     line(2), "fox and dog with --border \"\\A\" -o");

done_testing;
