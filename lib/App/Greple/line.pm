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
or set colormap to something do nothing like B<--cm=N>.

Multiple lines can be specified by joining with comma:

    greple -Mline -L 10,20,30

It is ok to use B<-L> option multiple times, like:

    greple -Mline -L 10 -L 20 -L 30

But this command produce nothing, because each line definitions are
taken as a different pattern, and B<greple> prints lines only when all
patterns matched.  You can relax the condition by B<--need 1> option
in such case, then you will get expected result.  Note that next
example will display 10th, 20th and 30th lines in different colors.

    greple -Mline -L 10 -L 20 -L 30 --need 1

Range can be specified by colon:

    greple -Mline -L 10:20

You can also specify the step with range.  Next command will print
all even lines from line 10 to 20:

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

If forth parameter is given, it describes how many lines is included
in that step cycle.  For example, next command prints top 3 lines in
every 10 lines.

    greple -Mline -L ::10:3

When step count is omitted, forth value is used if available.  Next
command print every 10 lines in different colors.

    greple -Mline -L :::10 --ci=A /etc/services

=item B<L>=I<line numbers>

This notation just define function spec, which can be used in
patterns, as well as blocks and regions.  Actually, B<-L>=I<line> is
equivalent to B<--le> B<L>=I<line>.

Next command show patterns found in line number 1000-2000 area.

    greple -Mline --inside L=1000:+1000 pattern

Next command prints all 10 line blocks which include the pattern.

    greple -Mline --block L=:::10 pattern

=back

This module implicitly set B<-n> option.  Use B<--no-line-number>
option to disable it.

Using this module, it is impossible to give single C<L> in command
line arguments.  Use like B<--le=L> to search C<L>.  You have a file
named F<L>?  Stop substitution by placing C<--> before target files.

=head1 SEE ALSO

L<Getopt::EX::Numbers>

=cut

package App::Greple::line;

use v5.14;
use warnings;

use Carp;
use List::Util qw(min max);
use Data::Dumper;

use Exporter qw(import);
our @EXPORT = qw(&line);

use App::Greple::Common;
use App::Greple::Regions qw(match_borders borders_to_regions);

sub line {
    my %arg = @_ ;
    my $file = delete $arg{&FILELABEL} or die;
    state $target = -1;
    state @lines;

    if ($target != \$_) {
	@lines = ([0, 0], borders_to_regions match_borders qr/^/m);
	$target = \$_;
    }

    use Getopt::EX::Numbers;
    my $numbers = Getopt::EX::Numbers->new(min => 1, max => $#lines);

    my @result = do {
	map  { [ $lines[$_->[0]]->[0], $lines[$_->[1]]->[1] ] }
	sort { $a->[0] <=> $b->[0] }
	map  { $numbers->parse($_)->range }
	keys %arg;
    };
    @result;
}

1;

__DATA__

option default -n

option L &line=$<shift>
help   L Region spec by line number

option -L --le L=$<shift>
help   -L Line number (1 10,20:30,40 -100 500: 1:1000:100 1::2)
