package App::Greple::RC;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw(@rcdata $BASECLASS);

use Text::ParseWords qw(shellwords);
use List::Util qw(first);

our $BASECLASS = 'App::Greple';
our @rcdata;

sub new {
    my $class = shift;
    my $obj = bless {
	Module => undef,
	Define => [],
	Option => [],
	Builtin => [],
	Call => [],
	Help => [],
    }, $class;

    my %opt = @_;

    if (my $file = $opt{FILE}) {
	$obj->module('main');
	if (open(RC, "<:encoding(utf8)", $file)) {
	    $obj->readrc(*RC);
	    close RC;
	}
    }
    elsif (my $module = $opt{MODULE}) {
	$module = "${BASECLASS}::${module}" if $BASECLASS;
	$obj->module($module);
	if (-f $module) {
	    require $module;
	} else {
	    my $pkg = $opt{PACKAGE} || 'main';
	    eval "package $pkg; use $module";
	}
	croak "$module: $!" if $@;
	local *data = "${module}::DATA";
	if (not eof *data) {
	    $obj->readrc(*data);
	}
	close *data;
    }
    $obj;
}

sub readrc {
    my $obj = shift;
    my $fh = shift;
    my $text = do { local $/; <$fh> };
    for ($text) {
	s/^__(?:CODE|PERL)__\s*\n(.*)//ms and eval $1;
	s/^\s*(?:#.*)?\n//mg;
	s/\\\n//g;
    }
    $obj->parsetext($text);
}

sub modopt {
    my $argref = shift;
    my @modules;
    while (@$argref) {
	if ($argref->[0] =~ /^-M(?<module>.+)/) {
	    shift @$argref;
	    push @modules, load_module($+{module}, $argref);
	    next;
	}
	last;
    }
    @modules;
}

sub load_module {
    my $mod = shift;
    my $argref = shift;
    my $base = $BASECLASS;
    my $call;

    ##
    ## Check -Mmod::func(arg) or -Mmod::func=arg
    ##
    if ($mod =~ s{
	^ (?<name> .* ) ::
	  (?<call>
		\w+
		(?: (?<P>[(]) | = )  ## start with '(' or '='
		(?<arg> [^)]* )      ## optional arg list
		(?(<P>) [)] | )      ## close ')' or none
	  ) $
    }{$+{name}}x) {
	$call = $+{call};
    }

    my $module = $mod;
    my $rc = App::Greple::RC->new(MODULE => $module);

    if ($call) {
	$rc->call("${module}::${call}");
    }

    ##
    ## If &getopt is defined in module, call it and replace @ARGV.
    ##
    my $getopt = "${module}::getopt";
    if (defined &$getopt) {
	no strict 'refs';
	@$argref = &$getopt($rc, @$argref);
    }

    $rc;
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

sub call {
    my $obj = shift;
    my $list = $obj->{Call};
    @_  ? push @$list, @_
	: @$list;
}

1;
