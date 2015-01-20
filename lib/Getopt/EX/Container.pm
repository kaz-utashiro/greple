package Getopt::EX::Container;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Text::ParseWords qw(shellwords);
use List::Util qw(first);

sub new {
    my $class = shift;
    my $obj = bless {
	Module => undef,
	Base => undef,
	Define => [],
	Option => [],
	Builtin => [],
	Call => [],
	Help => [],
    }, $class;

    configure $obj @_ if @_;

    $obj;
}

sub configure {
    my $obj = shift;
    my %opt = @_;

    if (my $base = $opt{BASECLASS}) {
	$obj->{Base} = $base;
    }

    if (my $file = $opt{FILE}) {
	$obj->module($file);
	if (open(RC, "<:encoding(utf8)", $file)) {
	    $obj->readrc(*RC);
	    close RC;
	}
    }
    elsif (my $module = $opt{MODULE}) {
	my $pkg = $opt{PACKAGE} || 'main';
	$module = join '::', $obj->{Base}, $module if $obj->{Base};
	$obj->module($module);
	eval "package $pkg; use $module";
	croak "$module: $@" if $@;
	local *data = "${module}::DATA";
	if (not eof *data) {
	    $obj->readrc(*data);
	}
    }

    if (my $builtin = $opt{BUILTIN}) {
	$obj->builtin(@$builtin);
    }

    $obj;
}

sub readrc {
    my $obj = shift;
    my $fh = shift;
    my $text = do { local $/; <$fh> };
    for ($text) {
	s/^__(?:CODE|PERL)__\s*\n(.*)//ms and do {
	    package main;
	    eval $1;
	};
	s/^\s*(?:#.*)?\n//mg;
	s/\\\n//g;
    }
    $obj->parsetext($text);
}

############################################################

sub module {
    my $obj = shift;
    @_  ? $obj->{Module} = shift
	: $obj->{Module};
}

sub title {
    my $obj = shift;
    my $mod = $obj->module;
    $mod =~ m{ .* [:/] (.+) }x ? $1 : $mod;
}

sub define {
    my $obj = shift;
    my $name = shift;
    my $list = $obj->{Define};
    if (@_) {
	my $re = qr/\Q$name/;
	unshift(@$list, [ $name, $re, shift ]);
    } else {
	first { $_->[0] eq $name } @$list;
    }
}

sub expand {
    my $obj = shift;
    local *_ = shift;
    for my $defent (@{$obj->{Define}}) {
	my($name, $re, $string) = @$defent;
	s/$re/$string/g;
    }
    s/(\$ENV\{ (['"]?) \w+ \g{-1} \})/$1/xgee;
}

use constant BUILTIN => "__BUILTIN__";
sub validopt { $_[0] ne BUILTIN }

sub setopt {
    my $obj = shift;
    my $name = shift;
    my $list = $obj->{Option};
    my @args = shellwords(shift);
    for (@args) {
	$obj->expand(\$_);
    }
    unshift @$list, [ $name, @args ];
}

sub getopt {
    my $obj = shift;
    my($name, %opt) = @_;
    return () if $name eq 'default' and not $opt{DEFAULT} || $opt{ALL};

    my $list = $obj->{Option};
    my $e = first {
	$_->[0] eq $name and $opt{ALL} || validopt($_->[1])
    } @$list;
    my @e = $e ? @$e : ();
    shift @e;
    @e;
}

sub default {
    my $obj = shift;
    $obj->getopt('default', DEFAULT => 1);
}

sub options {
    my $obj = shift;
    reverse map { $_->[0] } @{$obj->{Option}};
}

sub help {
    my $obj = shift;
    my $name = shift;
    my $list = $obj->{Help};
    if (@_) {
	unshift(@$list, [ $name, shift ]);
    } else {
	my $e = first { $_->[0] eq $name } @$list;
	$e ? $e->[1] : undef;
    }
}

sub parsetext {
    my $obj = shift;
    my $text = shift;
    while ($text =~ /(.+)\n?/g) {
	$obj->parseline($1);
    }
    $obj;
}

sub parseline {
    my $obj = shift;
    my $line = shift;
    my @arg = split ' ', $line, 3;

    if (@arg < 3) {
	warn sprintf("Parse error in %s: %s\n", $obj->title, $line);
	return;
    }

    ##
    ## in-line help document after //
    ##
    my $optname = $arg[1] // '';
    if ($arg[0] eq "builtin") {
	$optname =~ s/^(\w+).*/length($1) == 1 ? '-' : '--' . $1/e;
    }
    if ($arg[2] and $arg[2] =~ s{ (?:^|\s+) // \s+ (?<message>.*) }{}x) {
	$obj->help($optname, $+{message});
    }

    if ($arg[0] eq "define") {
	$obj->define($arg[1], $arg[2]);
    }
    elsif ($arg[0] eq "option") {
	$obj->setopt($arg[1], $arg[2]);
    }
    elsif ($arg[0] eq "defopt") {
	$obj->define($arg[1], $arg[2]);
	$obj->setopt($arg[1], $arg[1]);
    }
    elsif ($arg[0] eq "builtin") {
	$obj->setopt($optname, BUILTIN);
	if ($arg[2] =~ /^\\?(?<mark>[\$\@\%])(?<name>[\w:]+)/) {
	    my($mark, $name) = @+{"mark", "name"};
	    my $mod = $obj->module;
	    /:/ or s/^/${mod}::/ for $name;
	    no strict 'refs';
	    $obj->builtin($arg[1] => {'$' => \${$name},
				      '@' => \@{$name},
				      '%' => \%{$name}}->{$mark});
	}
    }
    elsif ($arg[0] eq "help") {
	$obj->help($arg[1], $arg[2]);
    }
    else {
	warn sprintf("Unknown operator \"%s\" in %s\n",
		     $arg[0], $obj->title);
    }

    $obj;
}

sub builtin {
    my $obj = shift;
    my $list = $obj->{Builtin};
    @_  ? push @$list, @_
	: @$list;
}

sub call {
    my $obj = shift;
    my $list = $obj->{Call};
    @_  ? push @$list, @_
	: @$list;
}

sub run_getopt {
    my $obj = shift;
    my $argv = shift;
    my $module = $obj->module;

    ##
    ## If &getopt is defined in module, call it and replace @ARGV.
    ##
    my $getopt = "${module}::getopt";
    if (defined &$getopt) {
	no strict 'refs';
	@$argv = &$getopt($obj, @$argv);
    }
}

1;
