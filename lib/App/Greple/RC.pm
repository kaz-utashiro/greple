package App::Greple::RC;

use strict;
use warnings;

use Text::ParseWords qw(shellwords);
use List::Util qw(first);

sub new {
    my $class = shift;
    my $title = shift || 'main';
    bless {
	Title => $title,
	Define => [],
	Option => [],
	Help => [],
    }, $class;
}

sub title {
    my $obj = shift;
    @_  ? $obj->{Title} = shift
	: $obj->{Title};
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
    return () if $name eq 'default' and not $opt{DEFAULT};

    my $list = $obj->{Option};
    my $e = first { $_->[0] eq $name } @$list;
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
    $rest //= "";

    ##
    ## in-line help document after //
    ##
    if (grep { $arg0 eq $_ } qw(define option defopt) and
	$rest =~ s{ \s+ // \s+ (.*) }{}x)
    {
	my $help = $1;
	$obj->help($arg1, $help);
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
    elsif ($arg0 eq "help") {
	$obj->help($arg1, $rest);
    }
#    elsif ($arg0 eq "set" and $arg1 eq "option") {
#	package main;
#	my @args = shellwords($rest);
#	GetOptionsFromArray(\@args, @optargs) || pod2usage;
#    }
    else {
	warn "$arg0: Unknown operator in rc file.\n";
    }

    $obj;
}

1;
