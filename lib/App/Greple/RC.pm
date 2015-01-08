package App::Greple::RC;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw(@rcdata);

use Text::ParseWords qw(shellwords);
use List::Util qw(first);

our @rcdata;

sub new {
    my $class = shift;
    my $module = shift || 'main';
    bless {
	Module => $module,
	Define => [],
	Option => [],
	Builtin => [],
	Help => [],
    }, $class;
}

sub module {
    my $obj = shift;
    @_  ? $obj->{Module} = shift
	: $obj->{Module};
}

sub title {
    my $obj = shift;
    my $mod = $obj->module;
    $mod =~ /.*:(.+)/ ? $1 : $mod;
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
    my($arg0, $arg1, $rest) = split(' ', $line, 3);

    my @commands = qw(define option builtin defopt);
    return if not grep { $arg0 eq $_ } @commands;

    my $optname = $arg1;
    if ($arg0 eq "builtin") {
	$optname =~ s/^(\w+).*/length($1) == 1 ? '-' : '--' . $1/e;
    }

    ##
    ## in-line help document after //
    ##
    if ($rest and $rest =~ s{ (?:^|\s+) // \s+ (?<message>.*) }{}x) {
	$obj->help($optname, $+{message});
    }

    if ($arg0 eq "define") {
	$obj->define($arg1, $rest);
    }
    elsif ($arg0 eq "option") {
	$obj->setopt($arg1, $rest);
    }
    elsif ($arg0 eq "defopt") {
	$obj->define($arg1, $rest);
	$obj->setopt($arg1, $arg1);
    }
    elsif ($arg0 eq "builtin") {
	$obj->setopt($optname, BUILTIN);
	if ($rest =~ /^\\?(?<mark>[\$\@\%])(?<name>[\w:]+)/) {
	    my($mark, $name) = @+{"mark", "name"};
	    my $mod = $obj->module;
	    /:/ or s/^/${mod}::/ for $name;
	    no strict 'refs';
	    $obj->builtin($arg1 => {'$' => \${$name},
				    '@' => \@{$name},
				    '%' => \%{$name}}->{$mark});
	}
    }
    elsif ($arg0 eq "help") {
	$obj->help($arg1, $rest);
    }
    else {
	warn "$arg0: Unknown operator in rc file.\n";
    }

    $obj;
}

sub builtin {
    my $obj = shift;
    my $list = $obj->{Builtin};
    @_  ? push @$list, @_
	: @$list;
}

1;
