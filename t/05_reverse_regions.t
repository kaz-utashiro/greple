use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use Data::Dumper;
use App::Greple::Regions;

my @region;

for my $p (
    [
     [],
     [ [ 0, 100 ] ],
     "empty"
    ],

    [
     [ [ 0, 0 ] ],
     [        [ 0, 100 ] ],
     "empty 2",
    ],

    [
     [ [ 0, 10 ] ],
     [         [10, 100] ],
     "edge: head",
    ],

    [
     [         [ 90, 100 ] ],
     [ [ 0, 90 ] ],
     "edge: end",
    ],

    [
     [         [ 10, 20 ] ],
     [ [ 0, 10 ],       [20, 100] ],
     "seg 1 ",
    ],

    [
     [ [ 0, 100 ] ],
     [ ],
     "all",
    ],

    [
     [ [ 0, 10 ],     [ 20, 30 ] ],
     [         [10, 20],       [ 30, 100 ] ],
     "edge: seg 2",
    ],

    [
     [ [ 0, 10 ], [ 10, 30 ] ],
     [                     [ 30, 100 ] ],
     "continuous seg 2",
    ],

    [
     [         [ 10, 20 ], [ 20, 30 ] ],
     [ [ 0, 10 ],                   [ 30, 100 ] ],
     "continuous seg 2",
     ],

    ## leave_empty

    [
     [         [ 10, 20 ],       [ 20, 30 ] ],
     [ [ 0, 10 ],       [ 20, 20 ],       [ 30, 100 ] ],
     "leave_empty",
    ],

    [
     [        [ 0, 10 ],       [ 10, 30 ] ],
     [ [ 0, 0 ],      [ 10, 10 ],       [ 30, 100 ] ],
     "leave_empty: edge head",
    ],

    [
     [         [ 10, 20 ],       [ 90, 100 ] ],
     [ [ 0, 10 ],       [ 20, 90 ],        [ 100, 100 ] ],
     "leave_empty: edge end",
    ],

    ) {
    my($region, $reverse, $comment, $opt) = @$p;
    $opt //= {};
    $opt->{leave_empty} = 1 if $comment =~ /leave_empty/;
    is_deeply ( [ reverse_regions $opt, $region, 100 ], $reverse, $comment );
}

done_testing;
