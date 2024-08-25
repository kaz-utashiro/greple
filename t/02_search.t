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

# --and

like(run('--and brown --and fox t/SAMPLE.txt')->stdout,
     line(1), "--and (match)");

like(run('--and brown --and dog t/SAMPLE.txt')->stdout,
     line(0), "--and (not match)");

# --not / -v

like(run('-e "fox|dog" t/SAMPLE.txt')->stdout,
     line(2), "-e brown|fox");

like(run('-e "fox|dog" -v lazy t/SAMPLE.txt')->stdout,
     line(1), "-e brown|fox -v lazy");

like(run('"fox|dog" -v lazy t/SAMPLE.txt')->stdout,
     line(1), "brown|fox -v lazy");

# --must

like(run('-o --must brown --and fox t/SAMPLE.txt')->stdout,
     line(2), "--must (match)");

like(run('-o --must brown --and dog t/SAMPLE.txt')->stdout,
     line(1), "--must (not match)");

like(run('-o --le "+brown fox" t/SAMPLE.txt')->stdout,
     line(2), "+brown fox (match)");

like(run('-o --le "+brown dog" t/SAMPLE.txt')->stdout,
     line(1), "+brown dog (not match)");

like(run('--le "+quick brown dog" --need 2 t/SAMPLE.txt')->stdout,
     line(1), "\"+quick brown dog\" --need 2 (MUST and --need)");

# --may

like(run('-o --and brown --may fox t/SAMPLE.txt')->stdout,
     line(2), "--may (match)");

like(run('-o --and brown --may dog t/SAMPLE.txt')->stdout,
     line(1), "--may (not match)");

like(run('-o --le "brown ?fox" t/SAMPLE.txt')->stdout,
     line(2), "brown ?fox");

like(run('-o --le "brown ?dog" t/SAMPLE.txt')->stdout,
     line(1), "brown ?dog");

like(run('brown --may fox t/SAMPLE.txt')->stdout,
     line(1), "bare pattern + --may");

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

# --file
like(run('--file t/SEARCH.txt t/SAMPLE.txt')->stdout,
     line(2), "--file t/SEARCH.txt");

like(run('--file t/SEARCH_x.txt t/SAMPLE.txt')->stdout,
     line(3), "--file t/SEARCH_x.txt");

like(run('--file t/SEARCH_m.txt t/SAMPLE.txt')->stdout,
     line(1), "--file t/SEARCH_m.txt");

# --stretch

like(run('-o --and brown --and fox t/SAMPLE.txt')->stdout,
     line(2), "brown and fox with -o");

like(run('-So --and brown --and fox t/SAMPLE.txt')->stdout,
     line(1), "brown and fox with -So");

# -G

like(run('-G "(quick).*(fox)" t/SAMPLE.txt')->stdout,
     line(1), "-G");

like(run('-Go "(quick).*(fox)" t/SAMPLE.txt')->stdout,
     line(2), "-Go");

like(run('-Go "(?:quick|(fast)).*(?:fox|(weasel))" t/SAMPLE.txt')->stdout,
     line(1), "-Go with unmatched group");

done_testing;
