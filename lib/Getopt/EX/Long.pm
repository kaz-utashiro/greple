package Getopt::EX::Long;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT = (	'GetOptions',
		'GetOptionsFromArray',
#		'GetOptionsFromString',
		'Configure',
		'HelpMessage',
		'VersionMessage',

		'ExConfigure',
    );
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );
our @ISA         = qw(Getopt::Long);

use Data::Dumper;
use Getopt::Long();
use Getopt::EX::Loader;
use Getopt::EX::Func qw(parse_func);

our $BASECLASS;
our $RCFILE;
our $AUTO_DEFAULT = 1;

my $loader;

sub GetOptions {
    unshift @_, \@ARGV;
    goto &GetOptionsFromArray;
}

sub GetOptionsFromArray {
    my $argv = $_[0];

    set_default() if $AUTO_DEFAULT;

    $loader //= new Getopt::EX::Loader
	RCFILE => $RCFILE,
	BASECLASS => $BASECLASS;

    $loader->deal_with($argv);

    push @_, $loader->builtins;

    goto &Getopt::Long::GetOptionsFromArray;
}

sub GetOptionsFromString {
    die "GetOptionsFromString is not supported, yet.\n";
}

sub ExConfigure {
    my %opt = @_;
    for my $name (qw(BASECLASS RCFILE AUTO_DEFAULT)) {
	if (my $val = delete $opt{$name}) {
	    no strict 'refs';
	    ${$name} = $val;
	}
    }
    warn "Unknown option: ", Dumper \%opt if %opt;
}

sub Configure {
    goto &Getopt::Long::Configure;
}

sub HelpMessage {
    goto &Getopt::Long::HelpMessage;
}

sub VersionMessage {
    goto &Getopt::Long::VersionMessage;
}

sub set_default {
    my @default = get_default();
    while (my($label, $value) = splice(@default, 0, 2)) {
	no strict 'refs';
	${$label} //= $value;
    }
}

sub get_default {
    my @list;

    my $prog = ($0 =~ /([^\/]+)$/) ? $1 : return ();

    if (defined (my $home = $ENV{HOME})) {
	if (-f (my $rc = "$home/.${prog}rc")) {
	    push @list, RCFILE => $rc;
	}
    }

    push @list, BASECLASS => "App::$prog";

    @list;
}

1;

############################################################

package Getopt::EX::Long::Parser;

use strict;
use warnings;

use List::Util qw(first);
use Data::Dumper;

use Getopt::EX::Loader;

our @ISA = qw(Getopt::Long::Parser);

sub new {
    my $class = shift;

    my @exconfig;
    while (defined (my $i = first { $_[$_] eq 'exconfig' } 0 .. $#_)) {
	push @exconfig, @{ (splice @_, $i, 2)[1] };
    }
    if (@exconfig == 0 and $Getopt::EX::Long::AUTO_DEFAULT) {
	@exconfig = Getopt::EX::Long::get_default();
    }

    my $obj = SUPER::new $class @_;

    my $loader = $obj->{exloader} = new Getopt::EX::Loader @exconfig;

    $obj;
}

sub getoptionsfromarray {
    my $obj = shift;
    my $argv = $_[0];
    my $loader = $obj->{exloader};

    $loader->deal_with($argv);

    push @_, $loader->builtins;

    $obj->SUPER::getoptionsfromarray(@_);
}

1;
