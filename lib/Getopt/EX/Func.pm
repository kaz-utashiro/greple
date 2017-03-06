package Getopt::EX::Func;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(parse_func);
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

use Data::Dumper;
use Getopt::EX::Module;

sub new {
    my $class = shift;
    my $obj = bless [ @_ ], $class;
}

sub call {
    my $obj = shift;
    unshift @_, @$obj;
    my $name = shift;

    no strict 'refs';
    goto &$name;
}

sub closure {
    my $name = shift;
    my @argv = @_;
    sub {
	package main; # XXX
	no strict 'refs';
	unshift @_, @argv;
	goto &$name;
    }
}

##
## sub { ... }
## funcname(arg1,arg2,arg3=val3)
## funcname=arg1,arg2,arg3=val3
##
sub parse_func {
    my $opt = ref $_[0] eq 'HASH' ? shift : {};
    local $_ = shift;
    my $noinline = $opt->{noinline};
    my $pointer = $opt->{pointer};
    my $caller = caller;

    my @func;

    if (not $noinline and /^sub\s*{/) {
	my $sub = eval $_;
	if ($@) {
	    warn "Error in function -- $_ --.\n";
	    die $@;
	}
	croak "Unexpected result from eval.\n" if ref $sub ne 'CODE';
	@func = ($sub);
    }
    elsif (m{
	^ &?
	  (?<name>[\w:]+)
	  (?:
	    (?: (?<P>[(]) | = )  ## start with '(' or '='
	    (?<arg> [^)]* )      ## optional arg list
	    (?(<P>) [)] | )      ## close ')' or none
	  )?
	$
    }x) {
	my($name, $arg) = @+{"name", "arg"};
	my $pkg = $opt->{PACKAGE} || $caller;
	$name =~ s/^/${pkg}::/ unless $name =~ /::/;
	@func = ($name, arg2kvlist($arg));
    }
    else {
	return undef;
    }

    __PACKAGE__->new( $pointer ? closure(@func) : @func );
}

##
## convert "key1,key2,key3=val3" to (key1=>1, key2=>1, key3=>"val3")
##
sub arg2kvlist {
    map  { /=/ ? split(/=/, $_, 2) : ($_, 1) }
    map  { split /, */ }
    grep { defined }
    @_;
}

1;

=head1 NAME

Getopt::EX::Func - Function call interface


=head1 SYNOPSIS

  use Getopt::EX::Func qw(parse_func);

  my $func = parse_func(...);

  $func->call;

=head1 DESCRIPTION

This module provides the way to create function call object used in
L<Getopt::EX> module set.

If your script has B<--begin> option which tells the script to call
specific function at the beginning of execution.  You can do it like
this:

    use Getopt::EX::Func qw(parse_func);

    GetOptions("begin:s" => $opt_begin);

    my $func = parse_func($opt_begin);

    $func->call;

Then script can be invoked like this:

    % example -Mfoo --begin 'repeat(debug,msg=hello,count=2)'

In this example, function C<repeat> should be declared in module
C<foo> or in start up rc file such as F<~/.examplerc>.  Actual
function call is done in this way:

    repeat ( debug => 1, msg => 'hello', count => '2' );

As you can notice, arguments in the function call string is passed in
I<name> =E<gt> I<value> style.  Parameter without value (C<debug> in
this example) is assigned value 1.

Function itself can be implemented like this:

    our @EXPORT = qw(repeat);
    sub repeat {
	my %opt = @_;
	print Dumper \%opt if $opt{debug};
	for (1 .. $opt{count}) {
	    print $opt{msg}, "\n";
	}
    }

It is also possible to declare the function in-line:

    % example -Mfoo --begin 'sub{ print"wahoo!!\n" }'
