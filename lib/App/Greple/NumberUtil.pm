=head1 NAME

NumberUtil - Perl module to produce number list from spec

=head1 SYNOPSIS

range_list(spec => "start:end:step:length", max => 100);

=head1 DESCRIPTION

=over 4

=item range_list ( spec => "spec", [ min => n, max => m ])

Accept number spec and maximum value, and return number range list:

    ( [ n0, m0 ], [ n1, m1 ], ... )

For example, C<10:20> means numbers from 10 to 20, and produces the
result ( [ 10, 20 ] ).

Third number means step count, and

    10:20:2

produces even numbers from line 10 to 20:

    ( [ 10, 10 ], [ 12, 12 ] ..  [ 20, 20 ] )

Any of them can be omitted.  Next specs means all, odd and even numbers.

    ::     all
    ::2    odd numbers
    2::2   even numbers

If start and end number is negative, they are subtracted from the
maximum number.  If the end number is prefixed by plus (`+') sign, it
is summed to start number.  Next examples produce top and last 10
numbers.

    :+9	   top 10 numbers
    -9:	   last 10 numbers

If the forth parameter is given, it describes how many numbers are
included in that step cycle.  For example,

    ::10:3

produces:

    ( [ 0, 2 ], [ 10, 12 ], [ 20, 22 ], ... )

Minimum number is zero by default, and can be set by `min' parameter.
Maximum number is optional but required in some operations.

=back

=cut

package App::Greple::NumberUtil;

use strict;
use warnings;

use Carp;
use List::Util qw(min max);
use Data::Dumper;

use Exporter qw(import);
our @EXPORT_OK = qw(&range_list &sequence);

sub range_list {
    my %opt = @_;
    my $max = $opt{max};
    my $min = $opt{min} // 0;
    local $_ = $opt{spec} // croak "No spec parameter";

    if (m{^	(?<start> -\d+ | \d* )
		(?:
		  (?: \.\. | : ) (?<end> [-+]\d+ | \d* )
		  (?:
		    : (?<step> \d* )
		    (?:
		      : (?<length> \d* )
		    )?
		  )?
		)?
	$}x) {
	my($start, $end, $step, $length) = @+{qw(start end step length)};

	if (not defined $max) {
	    if ($start =~ /^-\d+$/ or
		(defined $end and $end =~ /^-\d+$/)) {
		carp "$_: max required";	    
		return ();
	    }
	}

	if ($start =~ /\d/ and defined $max and $start > $max) {
	    return ();
	}
	if ($start eq '') {
	    $start = $min;
	}
	elsif ($start =~ /^-\d+$/) {
	    $start = max($min, $start + $max);
	}

	if (not defined $end) {
	    $end = $start;
	}
	elsif ($end eq '') {
	    $end = defined $max ? $max : $start;
	}
	elsif ($end =~ /^-/) {
	    $end = max(0, $end + $max);
	}
	elsif ($end =~ s/^\+//) {
	    $end += $start;
	}
	$end = $max if defined $max and $end > $max;

	$length ||= 1;
	$step ||= $length;

	my @l;
	if ($step == 1) {
	    @l = ([$start, $end]);
	} else {
	    for (my $from = $start; $from <= $end; $from += $step) {
		my $to = $from + $length - 1;
		$to = min($max, $to) if defined $max;
		push @l, [$from, $to ];
	    }
	}
	@l;
    }
    else {
	carp "$_: Line format error";
	();
    }
}

sub sequence {
    map { ref $_ eq 'ARRAY' ? ($_->[0] .. $_->[1]) : $_ }
    range_list spec => @_;
}

1;
