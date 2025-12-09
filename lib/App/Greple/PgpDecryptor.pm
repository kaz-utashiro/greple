=head1 NAME

PgpDecryptor - Module for decrypt PGP data

=head1 SYNOPSIS

 my $pgp = App::Greple::PgpDecryptor->new;

=head1 DESCRIPTION

=head2 initialize

Initialize object.

Without parameter, read passphrase from terminal.

    $pgp->initialize();

Provide passphrase string or file descriptor if available.

    $pgp->initialize({passphrase => passphrase});

    $pgp->initialize({passphrase_fd => fd});

=head2 decrypt

Decrypt data.  Pass the encrypted data and get the result.

    $decrypted = $pgp->decript($encrpted);

=head2 decrypt_comand

Return decrypt command string.  You can use this command to decrypt
data.  Call B<reset> after command execution.

    open(STDIN, '-|') or exec $pgp->decrypt_command;

=head2 reset

Reset internal status.  

=cut


package App::Greple::PgpDecryptor;

use v5.24;
use warnings;
use Carp;

sub new {
    my $obj = bless {
	FH        => undef,
    }, shift;
    $obj;
}

sub initialize {
    my $obj = shift;
    my $opt = @_ ? shift : {};
    my $passphrase = "";

    if (my $fd = $opt->{passphrase_fd}) {
	$obj->fh(_openfh($fd));
    }
    else {
	if (not defined $obj->fh) {
	    $obj->fh(_openfh());
	}
	if (defined $opt->{passphrase}) {
	    $passphrase = $opt->{passphrase};
	} else {
	    _readphrase(\$passphrase);
	}
	$obj->setphrase(\$passphrase);

	##
	## Destroy data as much as possible
	##
	$passphrase =~ s/./\0/g;
	$passphrase = "";
	undef $passphrase;
    }

    $obj;
}

sub setphrase {
    my $obj = shift;
    my $fh = $obj->fh;
    my $passphrase_r = shift;

    $obj->reset;
    $fh->syswrite($$passphrase_r, length($$passphrase_r));
    $obj->reset;
}

sub getphrase {
    my $obj = shift;
    my $fh = $obj->fh;

    $obj->reset;
    my $phrase = $fh->getline;
    $obj->reset;
    $phrase;
}

sub fh {
    my $obj = shift;
    @_ ? $obj->{FH} = shift
       : $obj->{FH};
}

sub pgppassfd {
    my $obj = shift;
    $obj->fh->fileno;
}

sub decrypt_command {
    my $obj = shift;
    my $command = "gpg";
    my @option = ( qw(--quiet --batch --decrypt) ,
		   qw(--no-tty --no-mdc-warning) );
    sprintf "$command @option --passphrase-fd %d", $obj->pgppassfd;
}

sub reset {
    my $obj = shift;
    defined $obj->fh or return;
    $obj->fh->sysseek(0, 0) or die $!;
}

sub _openfh {
    use Fcntl;
    use IO::File;

    my $fd = shift;
    my $fh;

    if (defined $fd) {
	$fh = IO::Handle->new;
	$fh->fdopen($fd, "w+");
    } else {
	$fh = new_tmpfile IO::File;
	defined $fh or die "new_tmpefile: $!";
    }

    $fh->fcntl(F_SETFD, 0) or die "fcntl F_SETFD failed: $!\n";

    return $fh;
}

my $noecho;
my $restore;
BEGIN {
    ($noecho, $restore) = eval {
	require Term::ReadKey;
	import  Term::ReadKey;
	(sub { ReadMode('noecho', @_) }, sub { ReadMode('restore', @_) });
    };
    if (not defined $noecho) {
	$noecho  = sub { system 'stty -echo < /dev/tty' };
	$restore = sub { system 'stty  echo < /dev/tty' };
    }
}

sub _readphrase {
    my $passphrase_r = shift;

    print STDERR "Enter PGP Passphrase> ";
    open my $tty, '<', '/dev/tty' or die;
    $noecho->($tty);
    if (defined (my $pass = ReadLine(0, $tty))) {
	chomp($$passphrase_r = $pass);
    }
    $restore->($tty);
    close $tty;
    print STDERR "\n";

    $passphrase_r;
}

sub decrypt {
    use IPC::Open2;

    my $obj = shift;
    my $enc_data = shift;

    $obj->reset;

    my $pid = open2(\*RDRFH, \*WTRFH, $obj->decrypt_command);

    if (length($enc_data) <= 1024 * 16) {
	print WTRFH $enc_data;
    }
    else {
	my $pid = fork;
	croak "process fork failed" if not defined $pid;
	if ($pid == 0) {
	    print WTRFH $enc_data;
	    close WTRFH;
	    close RDRFH;
	    exit;
	}
    }
    close WTRFH;
    my $dec_data = do { local $/ ; <RDRFH> };
    close RDRFH;

    $dec_data;
}

1;
