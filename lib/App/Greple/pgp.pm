=head1 NAME

pgp - Greple module to handle pgp files

=head1 SYNOPSIS

greple -Mpgp [ --pass phrase ]

=head1 DESCRIPTION

Invoke PGP decrypt command for files with I<.pgp>, I<.gpg> or I<.asc>
suffix.  PGP passphrase is asked only once at the beginning of command
execution.

=head1 OPTION

=over 7

=item B<--pass> I<phrase>

You can specify PGP passphrase by this option.  Generally, it is not
recommended to use.

=back

=cut

package App::Greple::pgp;

use strict;
use warnings;
use Carp;

use App::Greple::Common;
use App::Greple::PgpDecryptor;

my $pgp = new App::Greple::PgpDecryptor;

sub getopt {
    return @_ if @_ == 0 or $_[0] =~ /^--(man|show)/;
    my %opt;
    if (@_ >= 2 and $_[0] =~ /^--pass (?: =(?<phrase>.*) )? $/x) {
	shift;
	$opt{passphrase} = $+{phrase} // shift;
    }
    $pgp->initialize(\%opt);
    ('--if'  => sprintf('s/\.(pgp|gpg|asc)//:%s', $pgp->decrypt_command),
     '--end' => __PACKAGE__ . '::reset'),
    @_;
}

sub reset {
    $pgp->reset;
}

1;
