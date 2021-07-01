package App::Greple::select;

use v5.14;
use warnings;
use Data::Dumper;
use App::Greple::Common;
use Getopt::EX::Colormap qw(colorize);

our @opt_shebang;
our @opt_suffix;
my  %opt;

my $select = __PACKAGE__->new();

sub new {
    my $class = shift;
    my $obj = bless {
	name => [],
	data => [],
    }, $class;
}

sub add {
    my $obj = shift;
    my($type, $re, $return) = @_;
    push @{$obj->{$type}}, [ $re, $return ];
}

sub name {
    my $obj = shift;
    $obj->add(name => @_);
}

sub data {
    my $obj = shift;
    $obj->add(data => @_);
}

sub filters {
    my $obj = shift;
    @{$obj->{name}} + @{$obj->{data}};
}

sub positive {
    my $obj = shift;
    grep { $_->[1] } @{$obj->{name}}, @{$obj->{data}};
}

sub check {
    my $obj = shift;
    my($name, $data_ref) = @_;
    $obj->filters == 0 and return 1;
    for my $f (@{$obj->{name}}) {
	$name =~ $f->[0] and return $f->[1];
    }
    for my $f (@{$obj->{data}}) {
	${$data_ref} =~ $f->[0] and return $f->[1];
    }
    return $obj->positive ? 0 : 1;
}

############################################################

sub opt {
    while (my($k, $v) = splice @_, 0, 2) {
	$opt{$k} = $v;
    }
}

use List::Util qw(reduce);

sub prologue {
    my(@content_re, @name_re);

    push @content_re, do {
	map { qr/\A#!.*\b\Q$_\E/ }
	map { split /,/ }
	@opt_shebang;
    };

    push @name_re, do {
	map    { qr/\.(?:$_)/ }
	reduce { "$a|$b" }
	map    { quotemeta }
	map    { split /,/ }
	@opt_suffix;
    };

    for (@content_re) {
	$select->data($_ => 1);
    }
    for (@name_re) {
	$select->name($_ => 1);
    }
}

sub select {
    my %arg = @_;
    my $name = delete $arg{&FILELABEL} or die;
    if ($select->check($name, *_)) {
	say $name if $opt{yes};
	$opt{die} and die;
    } else {
	say $name if $opt{no};
	die;
    }
}

1;

__DATA__

option default \
	--prologue __PACKAGE__::prologue \
	--begin    __PACKAGE__::select

builtin shebang=s @opt_shebang
builtin suffix=s  @opt_suffix
