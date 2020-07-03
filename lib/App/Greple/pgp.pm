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

=item B<--pgppass> I<passphrase>

You can specify PGP passphrase by this option.  Generally, it is not
recommended to use.

=back

=cut

package App::Greple::pgp;

use v5.14;
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

option default --if s/\\.(pgp|gpg|asc)$//:&App::Greple::pgp::filter

builtin pgppass=s $opt_pgppass // pgp passphrase
