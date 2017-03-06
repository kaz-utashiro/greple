package Getopt::EX::Container;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Data::Dumper;
use Text::ParseWords qw(shellwords);
use List::Util qw(first);

use Getopt::EX::Func qw(parse_func);

sub new {
    my $class = shift;
    my $obj = bless {
	Module => undef,
	Base => undef,
	Define => [],
	Expand  => [],
	Option => [],
	Builtin => [],
	Autoload => {},
	Call => [],
	Help => [],
    }, $class;

    configure $obj @_ if @_;

    $obj;
}

sub configure {
    my $obj = shift;
    my %opt = @_;

    if (my $base = delete $opt{BASECLASS}) {
	$obj->{Base} = $base;
    }

    if (my $file = delete $opt{FILE}) {
	$obj->module($file);
	if (open(RC, "<:encoding(utf8)", $file)) {
	    $obj->readrc(*RC);
	    close RC;
	}
    }
    elsif (my $module = delete $opt{MODULE}) {
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

    if (my $builtin = delete $opt{BUILTIN}) {
	$obj->builtin(@$builtin);
    }

    warn "Unprocessed option: ", Dumper \%opt if %opt;

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
	    die if $@;
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

sub setlocal {
    my $obj = shift;
    $obj->setlist("Expand", @_);
}

sub setopt {
    my $obj = shift;
    $obj->setlist("Option", @_);
}

sub setlist {
    my $obj = shift;
    my $list = $obj->{+shift};
    my $name = shift;
    my @args = do {
	if (ref $_[0] eq 'ARRAY') {
	    @{ $_[0] };
	} else {
	    map { shellwords $_ } @_;
	}
    };

    for (my $i = 0; $i < @args; $i++) {
	if (my @opt = $obj->getlocal($args[$i])) {
	    splice @args, $i, 1, @opt;
	    redo;
	}
    }

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

    # check autoload
    unless (@e) {
	my $hash = $obj->{Autoload};
	for my $mod (keys %$hash) {
	    if (exists $hash->{$mod}->{$name}) {
		delete $hash->{$mod};
		return ($mod, $name);
	    }
	}
    }

    @e;
}

sub getlocal {
    my $obj = shift;
    my($name, %opt) = @_;

    my $e = first { $_->[0] eq $name } @{$obj->{Expand}};
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
    my $auto = $obj->{Autoload};
    my @option = reverse map { $_->[0] } @{$obj->{Option}};
    my @auto = map { keys %{$auto->{$_}} } keys $auto;
    (@option, @auto);
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

    ##
    ## Commands
    ##
    if ($arg[0] eq "define") {
	$obj->define($arg[1], $arg[2]);
    }
    elsif ($arg[0] eq "option") {
	$obj->setopt($arg[1], $arg[2]);
    }
    elsif ($arg[0] eq "expand") {
	$obj->setlocal($arg[1], $arg[2]);
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
    elsif ($arg[0] eq "autoload") {
	shift @arg;
	$obj->autoload(@arg);
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

sub autoload {
    my $obj = shift;
    my $module = shift;
    my @option = do {
	if (ref $_[0] eq 'ARRAY') {
	    @{ $_[0] };
	} else {
	    map { shellwords $_ } @_;
	}
    };
    my $hash = ($obj->{Autoload}->{$module} //= {});
    map {
	$hash->{$_} = 1;
	$obj->help($_, "autoload: $module");
    } @option;
}

sub call {
    my $obj = shift;
    my $list = $obj->{Call};
    @_  ? push @$list, @_
	: @$list;
}

sub run_inits {
    my $obj = shift;
    my $argv = shift;
    my $module = $obj->module;

    ##
    ## Call function specified with module.
    ##
    for my $call ($obj->call) {
	my $func = $call->can('call') ? $call : parse_func($call);
	$func->call;
    }

    ##
    ## Call &initialize if defined.
    ##
    my $init = "${module}::initialize";
    if (defined &$init) {
	no strict 'refs';
	&$init($obj, $argv);
    }
}

1;

=head1 NAME

Getopt::EX::Container - RC/Module data container

=head1 SYNOPSIS

  use Getopt::EX::Container;

  my $bucket = new Getopt::EX::Container
	BASECLASS => $baseclass,
	FILE => $file_name  /  MODULE => $module_name,
	;

=head1 DESCRIPTION

This module is usually used from L<Getopt::EX::Loader>, and keeps
all data about loaded rc file or module.

After user defined module was loaded, subroutine C<initialize> is
called if it exists in the module, then this container object is
passed to the function as a first argument.  So you can use it to
directly touch the object contents through class interface.


=head1 RC FILE FORMAT

=over 7

=item B<option> I<name> I<string>

Define option I<name>.  Argument I<string> is processed by
I<shellwords> routine defined in L<Text::ParseWords> module.  Be sure
that this module sometimes requires escape backslashes.

Any kind of string can be used for option name but it is not combined
with other options.

    option --fromcode --outside='(?s)\/\*.*?\*\/'
    option --fromcomment --inside='(?s)\/\*.*?\*\/'

If the option named B<default> is defined, it will be used as a
default option.

For the purpose to include following arguments within replaced
strings, two special notations can be used in option definition.
String C<$E<lt>nE<gt>> is replaced by the I<n>th argument after the
substituted option, where I<n> is number start from one.  String
C<$E<lt>shiftE<gt>> is replaced by following command line argument and
the argument is removed from option list.

For example, when

    option --line --le &line=$<shift>

is defined, command

    greple --line 10,20-30,40

will be evaluated as this:

    greple --le &line=10,20-30,40

=item B<expand> I<name> I<string>

Define local option I<name>.  Command B<expand> is almost same as
command B<option> in terms of its function.  However, option defined
by this command is expanded in, and only in, the process of
definition, while option definition is expanded when command arguments
are processed.

This is similar to string macro defined by following B<define>
command.  But macro expantion is done by simple string replacement, so
you have to use B<expand> to define option composed by multiple
arguments.

=item B<define> I<name> I<string>

Define string macro.  This is similar to B<option>, but argument is
not processed by I<shellwords> and treated just a simple text, so
meta-characters can be included without escape.  Macro expansion is
done for option definition and other macro definition.  Macro is not
evaluated in command line option.  Use option directive if you want to
use in command line,

    define (#kana) \p{InKatakana}
    option --kanalist --nocolor -o --join --re '(#kana)+(\n(#kana)+)*'
    help   --kanalist List up Katakana string

=item B<help> I<name>

Define help message for option I<name>.

=item B<builtin> I<spec> I<variable>

Define built-in option which should be processed by option parser.
Defined option spec can be taken by B<builtin> method, and script is
responsible to give them to parser.

Arguments are assumed to be L<Getopt::Long> style spec, and
I<variable> is string start with C<$>, C<@> or C<%>.  They will be
replaced by a reference to the object which the string represent.

=item B<autoload> I<module> I<options>

Define module which should be loaded automatically when specified
option is found in the command arguments.

For example,

    autoload -Mdig --dig

replaces option "I<--dig>" to "I<-Mdig --dig>", and I<dig> module is
loaded before processing I<--dig> option.

=back


=head1 METHODS

=over 4

=item B<new>

Create object.  Parameters are just passed to C<configure> method.

=item B<configure>

Configure object.  Parameter is passed in hash name and value style.

=over 4

=item B<BASECLASS> =E<gt> I<class>

Set base class.

=item B<FILE> =E<gt> I<filename>

Load file.

=item B<MODULE> =E<gt> I<modulename>

Load module.

=back

=item B<define> I<name>, I<macro>

Define macro.

=item B<setopt> I<name>, I<option>

Set option.

=item B<setlocal> I<name>, I<option>

Set option which is effective only in the module.

=item B<getopt> I<name>

Get option.  Takes option name and return it's definition if
available.  It doesn't return I<default> option, get it by I<default>
method.

=item B<default>

Get default option.  Use C<setopt(default =E<gt> ...)> to set.

=item B<builtin>

Get built-in options.

=item B<autoload>

Set autoload module.

=back
