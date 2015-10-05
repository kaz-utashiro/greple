package Getopt::EX::Long;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT      = ( 'GetOptions' );
our @EXPORT_OK   = ( 'GetOptionsFromArray',
		   # 'GetOptionsFromString',
		     'Configure',
		     'HelpMessage',
		     'VersionMessage',
		     'ExConfigure',
    );
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

=head1 NAME

Getopt::EX::Long - Getopt::Long compatible glue module

=head1 SYNOPSIS

  use Getopt::EX::Long;

  or

  require Getopt::EX::Long;
  my $parser = new Getopt::EX::Long::Parser
	config   => [ Getopt::Long option ... ],
	exconfig => [ Getopt::EX::Long option ...];

=head1 DESCRIPTION

L<Getopt::EX::Long> is almost compatible to L<Getopt::Long> and you
can just replace module declaration and it should work just same as
before.

Besides working same, user can define their own option aliases and
write dynamically loaded extension module.  If the command name is
I<example>,

    ~/.examplerc

file is loaded by default.  In this rc file, user can define their own
option with macro processing.  This is useful when the command takes
complicated arguments.

Also, special command option preceded by B<-M> is taken and
corresponding perl module is loaded.  Module is assumed under the
specific base class.  For example,

    % example -Mfoo

will load C<App::example::foo> module, by default.

This module is normal perl module, so user can write any kind of
program.  If the module is specified with initial function call, it is
called at the beginning of command execution.  Suppose that the
module I<foo> is specified like this:

    % example -Mfoo::bar(buz=100) ...

Then, after the module B<foo> is loaded, function I<bar> is called
with the parameter I<baz> which has value 100.

If the module includes C<__DATA__> section, it is interpreted just
same as rc file.  So you can define arbitrary option there.  Combined
with startup function call described above, it is possible to control
module behavior by user defined option.

=head1 INCOMPATIBILITY

Subroutine B<GetOptionsFromString> is not supported.

Variables C<$REQUIRE_ORDER>, C<$PERMUTE>, C<$RETURN_IN_ORDER> can not
be exported.

=head1 SEE ALSO

L<Getopt::EX>
