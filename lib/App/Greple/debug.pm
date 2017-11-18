=head1 NAME

debug - Greple module for debug control

=head1 SYNOPSIS

greple -Mdebug::on(target)

greple -Mdebug::on=target

=head1 DESCRIPTION

Enable debug mode for specified target.

    getopt: Getopt::Long

    getoptex: Getopt::EX

=head1 EXAMPLE

Next command will show how the module option is processed in
L<Getopt::EX> module.

    greple -Mdebug::on=getoptex -Mdig --dig . -do something

=cut


package App::Greple::debug;

use strict;
use warnings;
use Carp;

use App::Greple::Common;
use Getopt::Long;

my %flags = (
    getoptex => \$Getopt::EX::Loader::debug,
    getopt   => sub { main::configure_getopt('debug') },
);

sub on {
    my %arg = @_;
    delete $arg{&FILELABEL}; # no entry when called from -M otption.

    if (defined (my $val = delete $arg{all})) {
	for my $key (keys %flags) {
	    $arg{$key} //= $val;
	}
    }

    for my $flag (keys %arg) {
	my $e = $flags{$flag} or next;
	if (ref $e eq 'CODE') {
	    $e->($arg{$flag});
	} else {
	    ${$flags{$flag}} = $arg{$flag};
	}
    }
}

1;
