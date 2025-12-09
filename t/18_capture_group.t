use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

# Test -G (capture-group) option
is(run(q[-G --need=1 -o -e '(fox)' t/SAMPLE.txt])->stdout,
   "fox\n",
   "-G with single group");

is(run(q[-G --need=1 -o -e '(quick).*(fox)' t/SAMPLE.txt])->stdout,
   "quick\nfox\n",
   "-G with multiple groups");

# Test --ci=G (sequential index across patterns)
is(run(q[-G --ci=G --need=1 -o -e '(quick).*(brown)' -e '(fox)' t/SAMPLE.txt])->stdout,
   "quick\nbrown\nfox\n",
   "--ci=G with multiple patterns");

# Test --ci=GP (index reset per pattern)
# Using same patterns, GP should produce same output since we're not checking index directly
is(run(q[-G --ci=GP --need=1 -o -e '(quick).*(brown)' -e '(fox)' t/SAMPLE.txt])->stdout,
   "quick\nbrown\nfox\n",
   "--ci=GP with multiple patterns");

# Test --ci=G with non-matching pattern in between
# Pattern 2 "(xxx).*(yyy)" doesn't match, but should still consume index 2,3
# So "lazy" should get index 4, not 2
is(run(q[-G --ci=G --need=1 -o -e '(quick).*(brown)' -e '(xxx).*(yyy)' -e '(lazy)' t/SAMPLE.txt])->stdout,
   "quick\nbrown\nlazy\n",
   "--ci=G with non-matching pattern updates offset");

done_testing;
