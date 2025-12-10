=head1 NAME

pgp - Greple module to handle PGP encrypted files

=head1 SYNOPSIS

greple -Mpgp pattern *.gpg

greple -Mpgp --pgppass 'passphrase' pattern file.gpg

=head1 DESCRIPTION

Enables searching within PGP/GPG encrypted files.  Files with
I<.pgp>, I<.gpg>, or I<.asc> extensions are automatically decrypted.
Passphrase is requested interactively once and cached for subsequent
files.

=head1 REQUIREMENTS

This module requires the B<gpg> (GnuPG) command to be installed and
available in PATH.

=head1 OPTIONS

=over 7

=item B<--pgppass> I<passphrase>

Specify the PGP passphrase directly.  B<Not recommended> for security
reasons as the passphrase may be visible in process listings or shell
history.  Use interactive input instead when possible.

=back

=head1 SECURITY NOTES

=over 4

=item *

The passphrase is stored in memory during execution and cleared when
no longer needed.

=item *

Decrypted content is processed through pipes and not written to disk.

=item *

Avoid using B<--pgppass> option in scripts or command history.

=back

=head1 SEE ALSO

L<App::Greple>, L<gpg(1)>

=cut

package App::Greple::pgp;

use v5.24;
use warnings;
use Carp;

use App::Greple::PgpDecryptor;

my  $pgp;
our $opt_pgppass;

sub activate {
    ($pgp = App::Greple::PgpDecryptor->new)
	->initialize({passphrase => $opt_pgppass});
}

sub filter {
    activate if not defined $pgp;
    $pgp->reset;
    my $pid = open(STDIN, '-|') // croak "process fork failed";
    if ($pid == 0) {
	exec $pgp->decrypt_command or die $!;
    }
    $pid;
}

1;

__DATA__

option default --if s/\\.(pgp|gpg|asc)$//:&__PACKAGE__::filter

builtin pgppass=s $opt_pgppass // pgp passphrase
