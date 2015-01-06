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

use strict;
use warnings;
use Carp;

use App::Greple::Common qw(setopt newopt);
use App::Greple::PgpDecryptor;

my $pgp;
my %pgpopt;
my $decrypt;
my $opt_pgppass;

sub getopt {
    my $pkg = __PACKAGE__;
    newopt("pgppass=s" => \$opt_pgppass);
    setopt({ append => 1 }, end => "&${pkg}::reset");
    setopt({ append => 1 }, if  => "s/\.(pgp|gpg|asc)//:&${pkg}::filter");
    @_;
}

sub filter {
    unless ($pgp) {
	$pgp = new App::Greple::PgpDecryptor;
	if ($opt_pgppass) {
	    $pgpopt{passphrase} = $opt_pgppass;
	}
	$decrypt = $pgp->initialize(\%pgpopt)->decrypt_command;
    }
    my $pid = open(STDIN, '-|') // croak "process fork failed";
    if ($pid == 0) {
	local @ARGV;
	exec $decrypt or die $!;
    }
    $pid;
}

sub reset {
    $pgp->reset if defined $pgp;
}

1;

__DATA__

option --pgppass
help   --pgppass pgp passphrase
