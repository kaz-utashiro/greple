=head1 NAME

line - Greple module to produce result by line numbers

=head1 SYNOPSIS

greple -Mline

=head1 DESCRIPTION

This module allows you to use line numbers to specify patterns or
regions which can be used in B<greple> options.

=over 7

=item B<-L>=I<line numbers>

Simply, next command will show 200th line with before/after 10 lines
of the file:

    greple -Mline -L 200 -C10 file

If you don't like lines displayed with color, use B<--nocolor> option
or set colormap to something invalid like B<--cm=0>.

Multiple lines can be specified by joining with comma:

    greple -Mline -L 10,20,30

It is ok to use B<-L> option multiple times, like:

    greple -Mline -L 10 -L 20 -L 30

But this command produce nothing, because each line definitions are
taken as a different pattern, and B<greple> prints lines only when all
pattern match is succeeded.  You can use B<--need 1> option in such
case, then you will get expected result.  Note that next example will
display 10th, 20th and 30th lines in different colors.

    greple -Mline -L 10 -L 20 -L 30 --need 1

Range can be specified by colon:

    greple -Mline -L 10:20

You can also specify the step with range.  Next command will print
all even lines between 10th and 20th:

    greple -Mline -L 10:20:2

Any of them can be omitted.  Next commands print all, odd and even
lines.

    greple -Mline -L ::		# all lines
    greple -Mline -L ::2	# odd lines
    greple -Mline -L 2::2	# even lines

If start and end number is negative, they are subtracted from the
maxmum line number.  If the end number is prefixed by plus (`+') sign,
it is summed with start number.  Next commands print top and last 10
lines respectively.

    greple -Mline -L :+9	# top 10 lines
    greple -Mline -L -9:	# last 10 lines

Next example print all lines of the file, each line in four different
colors.

    greple -Mline -L=1::4 -L=2::4 -L=3::4 -L=4::4 --need 1

=back

=cut

package App::Greple::line;

use strict;
use warnings;

use Carp;

use Data::Dumper;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&line &search_line);
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = qw();
}
our @EXPORT_OK;

END { }

my $target = -1;
my @lines;
my $sep = qr/[:]/;

sub expand_line {
    local $_ = shift;
    if (/^\d+$/) {
	$_ <= $#lines ? ($_) : ();
    }
    elsif (/^ ([-+]?\d*) $sep ([-+]?\d*) (?: $sep (\d*))? $/x) {
	my($start, $end, $step) = ($1 || 1, $2 || $#lines, $3 || 1);

	$start += $#lines if $start < 0;
	$end += $#lines if $end < 0;
	$end += $start if $end =~ s/^\+//;

	$end = $#lines if $end > $#lines;
	my @l;
	for (my $i = $start; $i <= $end; $i += $step) {
	    push @l, $i;
	}
	@l;
    }
    else {
	warn "Line format error: $_\n";
	();
    }
}

sub line {
    my %arg = @_ ;
    my $file = delete $arg{main::FILELABEL} or die;

    if ($target != \$_) {
	@lines = ([0,0]);
	my $off = 0;
	while (/^((.*\n|\z))/mg) {
	    push @lines, [ $off, $off + length $2 ];
	    $off += length $1;
	}
	$target = \$_ ;
    }

    my %seen;
    my @result = do {
	grep { defined }
	map  { $lines[$_] }
	grep { not $seen{$_}++ }
	sort { $a <=> $b }
	map  { expand_line $_ }
	keys %arg;
    };
}

1;

__DATA__

option default -n

option L &line=$<shift>
help   L Region spec by line number

option -L --le L=$<shift>
help   -L Line number (1 10,20-30,40 -100 500- 1:1000:100 1::2)
