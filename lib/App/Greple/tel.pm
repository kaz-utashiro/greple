=head1 NAME

tel - Module to support simple telephone/address data file

=head1 SYNOPSIS

greple -Mtel [ options ]

=head1 SAMPLES

greple -Mtel pattern

=head1 DESCRIPTION

Sample module for B<greple> command supporting simple telephone /
address data file.

=head1 FORMAT

NAME, TEL, ADDRESS fields are separated by tab.

The line start with space is continuous line.

[ keyword1, keyword2, ... ]

< string to be printed >

    [travel,airline]UA Reservations         800-241-6522
    [travel,airline]UA Premier Reservations
            03-3817-4441    Japan
            800-356-8900    US and Canada
            008-025-808     Australia
            810-1308        Hong Kong
            02-325-9914     Korea
            09-358-3500     New Zealand
            810-4356        Philippines
            321-8888        Singapore
            02-325-9914     Taiwan
    [travel,airline]UA Premier Exective
            800-225-8900    Reservations
            800-325-0046    Service Desk

    Kokkai Gijidou, The National Diet <国会議事堂>
            03-5521-7445    100-0014 東京都千代田区永田町1-7-1

=cut

package App::Greple::tel;

use strict;
use warnings;

use Carp;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&print_tel);
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = qw();
}
our @EXPORT_OK;

END { }

use Text::VisualWidth::PP qw/vwidth/;
use Text::VisualPrintf qw/vsprintf/;

sub print_tel {
    my %attr = @_;
    my $s = '';

    s/^\s*#.*\n//mg;

    my @record = split(/\n/);
    my($name, $jname, $ename, @keys);

    my($fname, $tel, $addr) = split(/\t+/, $record[0]);
    shift @record unless defined $tel;
    $fname =~ s/\s*<(.*)>\s*// and $jname = $1;
    $fname =~  s/\s*\[(.*)\]\s*// and @keys = split (/\s*,\s*/, $1);
    $name = $jname || $fname;
    if (vwidth($name) > 18) {
	$s .= "$name\n";
	$name = '';
    }
    for my $data (@record) {
	my($dummy, $tel, $addr) = split(/\t+/, $data);
	$tel = '' if not defined $tel or length($tel) <= 2;
	$s .= vsprintf("%-18s %-16s %s\n", $name, $tel, $addr || '');
	$name = '';
    }
    $s;
}

1;

__DATA__

option default \
	--icode=guess -i \
	--block='^(?!#)\S.*\n(?:(?=[\s#]).*\n)*' \
	--inside='^(?!#)\S[^\[\n]*' \
	--print print_tel \
	--chdir ~/lib --glob telephone --glob tel.*[a-z0-9]
