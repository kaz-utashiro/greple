use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8', ':std';

use lib '.';
use t::Util;

my $sample = 't/SAMPLE.txt';
my $content = do { local @ARGV = $sample; local $/; <> };

# --filter without pattern: output entire file
is(run("--filter --color=never $sample")->stdout,
    $content, "--filter without pattern");

# -F short option
is(run("-F --color=never $sample")->stdout,
    $content, "-F short option");

# --filter with matching pattern: output entire file with highlights
like(run("--filter -e fox $sample")->stdout,
     line(28), "--filter with matching pattern");

# --filter with non-matching pattern: still output entire file
is(run("--filter -e NOMATCH --color=never $sample")->stdout,
    $content, "--filter with non-matching pattern");

# --filter exit status is 0
is(run("--filter --color=never $sample")->status,
    0, "--filter exit status 0");

# --filter with non-matching pattern: exit status is still 0
is(run("--filter -e NOMATCH --color=never $sample")->status,
    0, "--filter with non-matching pattern exit status 0");

done_testing;
