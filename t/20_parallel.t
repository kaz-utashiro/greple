use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

# Force parallel matching even for small test files.
$ENV{GREPLE_PARALLEL_THRESHOLD} = 0;

# Compare output of sequential and parallel execution.
sub compare {
    my($option, $comment) = @_;
    my $seq = run($option);
    my $par = run("--parallel 4 $option");
    is($par->stdout, $seq->stdout, "$comment (stdout)");
    is($par->status, $seq->status, "$comment (status)");
}

compare('-e fox -e dog t/SAMPLE.txt', 'multiple OR patterns');

# -P without value (defaults to the number of CPU cores)
{
    my $seq = run('-e fox -e dog t/SAMPLE.txt');
    my $par = run('-P -e fox -e dog t/SAMPLE.txt');
    is($par->stdout, $seq->stdout, "bare -P (stdout)");
    is($par->status, $seq->status, "bare -P (status)");
}

compare('--and fox --and dog t/SAMPLE.txt', 'AND patterns');

compare('--and fox --and dog --and cat t/SAMPLE.txt', 'AND patterns (no match)');

compare('-e fox --not lazy t/SAMPLE.txt', 'negative pattern');

compare('--must fox -e dog -e cow t/SAMPLE.txt', 'must pattern');

compare('-e 風 -e 森 t/JA.txt', 'Japanese patterns');

compare('-e いろは -e 色は t/SAMPLE.txt', 'Japanese patterns (SAMPLE)');

compare('-e fox -e dog --inside "^T.*" t/SAMPLE.txt', 'with --inside region');

compare('-p -e fox -e dog t/SAMPLE.txt', 'paragraph mode');

compare('-c -e fox -e dog t/SAMPLE.txt', 'count mode');

compare('-o -e "(\w+) fox" -e "(\w+) dog" --ci=G t/SAMPLE.txt', 'capture group');

compare('-A1 -B1 -e fox -e dog t/SAMPLE.txt', 'context lines (-A/-B)');

compare('--border "^\\\\w" -e fox -e dog t/SAMPLE.txt', 'custom border');

# single pattern: pattern-parallel is no-op but async borders still works
compare('-e fox t/SAMPLE.txt', 'single pattern');

compare('-e nomatchpattern t/SAMPLE.txt', 'single pattern (no match)');

done_testing;
