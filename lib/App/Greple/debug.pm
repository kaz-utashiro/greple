=head1 NAME

debug - Greple module for debug control

=head1 SYNOPSIS

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
    misc        -dm  Pattern and other information
    option      -do  Show command option processing
    process     -dp  Exec ps command before exit
    stat        -ds  Show statistic information
    grep        -dg  Show grep internal state
    unused      -du  Show unused 1-char option name

When used without function call, default target is enabled; currently
C<getoptex>.

    $ greple -Mdebug

Specify required target with C<on> function like:

    $ greple -Mdebug::on(color,misc,option)

    $ greple -Mdebug::on=color,misc,option

Calling C<debug::all()> enables all targets.  Exceptionally C<unused>
is no enabled, because it immediately exits.

Target name marked with C(-dx) can be enabled in that form.  Following
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

use strict;
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
    misc      => \$opt_d{m},
    option    => \$opt_d{o},
    process   => \$opt_d{p},
    stat      => \$opt_d{s},
    grep      => \$opt_d{g},
    unused    => \$opt_d{u},
    );

my %exclude = ( unused => 1 );

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

my @default = qw(getoptex);

my $called = 0;

sub on {
    my %arg = @_;
    delete $arg{&FILELABEL}; # no entry when called from -M otption.

    # Clear default setting on first call.
    if ($called++ == 0) {
	switch_default(0);
    }

    if (delete $arg{'all'}) {
	map { $arg{$_} = 1 } @all_flags;
    }

    switch(%arg);
}

sub initialize {
    switch_default(1);
}

sub switch_default {
    switch map { $_ => $_[0] } @default;
}

1;

#  LocalWords:  getoptex getopt grep greple misc
