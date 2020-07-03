=head1 NAME

debug - Greple module for debug control

=head1 SYNOPSIS

greple -dmc

greple -Mdebug

greple -Mdebug::on(getoptex)

greple -Mdebug::on=getoptex

=head1 DESCRIPTION

Enable debug mode for specified target.  Currently, following targets
are available.

    getoptex         Getopt::EX
    getopt           Getopt::Long
    color       -dc  Color information
    directory   -dd  Change directory information
    file        -df  Show search file names
    number      -dn  Show number of processing files
    misc        -dm  Pattern and other information
    option      -do  Show command option processing
    process     -dp  Exec ps command before exit
    stat        -ds  Show statistic information
    grep        -dg  Show grep internal state
    unused      -du  Show unused 1-char option name

When used without function call, default target is enabled; currently
C<getoptex> and C<option>.

    $ greple -Mdebug

Specify required target with C<on> function like:

    $ greple -Mdebug::on(color,misc,option)

    $ greple -Mdebug::on=color,misc,option

Calling C<debug::on=all> enables all targets, except C<unused> and
C<number>.

Target name marked with C<-dx> can be enabled in that form.  Following
commands are all equivalent.

    $ greple -Mdebug::on=color,misc,option

    $ greple -dc -dm -do

    $ greple -dcmo

=head1 EXAMPLE

Next command will show how the module option is processed in
L<Getopt::EX> module.

    $ greple -Mdebug::on=getoptex,option -Mdig something --dig .

=cut


package App::Greple::debug;

use v5.14;
use warnings;
use Carp;
use Data::Dumper;

use App::Greple::Common;
use Getopt::Long;

my %flags = (
    getoptex  => \$Getopt::EX::Loader::debug,
    getopt    => { on  => sub { main::configure_getopt('debug')    },
		   off => sub { main::configure_getopt('no_debug') } },
    color     => \$opt_d{c},
    directory => \$opt_d{d},
    file      => \$opt_d{f},
    number    => \$opt_d{n},
    misc      => \$opt_d{m},
    option    => \$opt_d{o},
    process   => \$opt_d{p},
    stat      => \$opt_d{s},
    grep      => \$opt_d{g},
    unused    => \$opt_d{u},
    );

sub getoptex  { on ( getoptex  => 1 ) }
sub getopt    { on ( getopt    => 1 ) }
sub color     { on ( color     => 1 ) }
sub directory { on ( directory => 1 ) }
sub file      { on ( file      => 1 ) }
sub number    { on ( number    => 1 ) }
sub misc      { on ( misc      => 1 ) }
sub option    { on ( option    => 1 ) }
sub process   { on ( process   => 1 ) }
sub stat      { on ( stat      => 1 ) }
sub grep      { on ( grep      => 1 ) }
sub unused    { on ( unused    => 1 ) }

my %exclude = map { $_ => 1 } qw(unused number);

my @all_flags = grep { not $exclude{$_} } sort keys %flags;

sub switch {
    my %arg = @_;
    my @keys = keys %arg;
    while (@keys) {
	my $key = shift @keys;
	my $val = $arg{$key};
	my $e = $flags{$key} or next;
	if (ref $e eq 'ARRAY') {
	    unshift @keys, @{$e};
	    next;
	}
	if (ref $e eq 'HASH') {
	    if (my $sub = $e->{ $val ? 'on' : 'off' }) {
		ref $sub eq 'CODE' or die;
		$sub->();
	    }
	} else {
	    ${$e} = $val;
	}
    }
}

my @default = qw(getoptex option);

sub switch_default {
    switch map { $_ => $_[0] } @default;
}

sub on {
    my %arg = @_;
    delete $arg{&FILELABEL}; # no entry when called from -M otption.

    # Clear default setting on first call.
    state $called;
    $called++ or switch_default 0;

    if (delete $arg{'all'}) {
	map { $arg{$_} = 1 } @all_flags;
    }

    switch(%arg);
}

sub initialize {
    switch_default 1;
}

1;

#  LocalWords:  getoptex getopt grep greple misc
