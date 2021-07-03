=head1 NAME

select - Greple module to select files

=head1 SYNOPSIS

greple -Mdig -Mselect ... --dig .

  FILENAME
    --suffix         file suffixes
    --select-name    regex match for file name
    --select-path    regex match for file path
    --x-suffix	     exclusive version of --suffix	   
    --x-select-name  exclusive version of --select-name
    --x-select-path  exclusive version of --select-path

  DATA
    --shebang        included in #! line
    --select-data    regex match for file data
    --x-shebang      exclusive version of --shebang	   
    --x-select-data  exclusive version of --select-data

=head1 DESCRIPTION

Greple's B<-Mselect> module allows to filter files using their name
and content data.  It is usually supposed to be used along with
B<-Mfind> or B<-Mdig> module.

For example, next command scan files end with C<.pl> and C<.pm> under
current directory.

    greple -Mdig -Mselect --suffix=pl,pm foobar --dig .

This is almost equivalent to the next command using B<--dig> option
with extra conditional expression for B<find> command.

    greple -Mdig foobar --dig . -name '*.p[lm]'

The problems is that the above command does not search perl command
script without suffixes.  Next command looks for both files looking at
C<#!> (shebang) line.

    greple -Mdig -Mselect --suffix=pl,pm --shebang perl foobar --dig .

Generic option B<--select-name>, B<--select-path> and B<--select-data>
take regular expression and works for arbitrary use.

=head2 ORDER and DEFAULT

Besides normal inclusive rules, there is exclusive rules which start
with B<--x-> option name.

As for the order of rules, all exclusive rules are checked first, then
inclusive rules are applied.

When no rules are matched, default action is taken.  If no inclusive
rule exists, it is selected.  Otherwise discarded.

=head1 OPTIONS

=head2 FILENAME

=over 7

=item B<--suffix>=I<xx,yy,zz ...>

Specify one or more file name suffixes connecting by comma (C<,>).
They will be converted to C</\.(xx|yy|zz)$/> expression and compared
to the file name.

=item B<--select-name>=I<regex>

Specify regular expression and it is compared to the file name.  Next
command search Makefiles under any directory.

    greple -Mselect --select-name '^Makefile.*'

=item B<--select-path>=I<regex>

Specify regular expression and it is compared to the file path.

=item B<--x-suffix>=I<xx,yy,zz ...>

=item B<--x-select-name>=I<regex>

=item B<--x-select-path>=I<regex>

These are reverse version of corresponding options.  File is not
selected when matched.

=back

=head2 DATA

=over 7

=item B<--shebang>=I<aa,bb,cc>

This option test if a given string is included in the first line of
the file start with C<#!> (aka shebang) mark.  Multiple names can be
specified connecting by command (C<,>).  Given string is converted to
the next regular expression:

    /\A #! .*\b (aa|bb|cc)/x

=item B<--select-data>=I<regex>

Specify regular expression and it is compared to the file content data.

=item B<--x-shebang>=I<aa,bb,cc>

=item B<--x-select-data>=I<regex>

These are reverse version of corresponding options.  File is not
selected when matched.

=back

=cut

package App::Greple::select;

use v5.14;
use warnings;
use Hash::Util qw(lock_keys);
use Data::Dumper;
use App::Greple::Common;

our @select_shebang;
our @select_suffix;
our @select_name;
our @select_path;
our @select_data;

our @discard_shebang;
our @discard_suffix;
our @discard_name;
our @discard_path;
our @discard_data;

my %opt;
my $select = __PACKAGE__->new();

sub new {
    my $class = shift;
    my $obj = bless { include => [],
		      exclude => [] }, $class;
    lock_keys %$obj;
    $obj;
}

sub include { @{shift->{include}} }

sub exclude { @{shift->{exclude}} }

package filter_ent {
    sub new {
	my $class = shift;
	bless [ @_ ], $class;
    }
    sub type   { shift->[0] }
    sub regex  { shift->[1] }
    sub action { shift->[2] }
}

sub add {
    my $obj = shift;
    my($type, $regex, $action) = @_;
    my $list = $action ? $obj->{include} : $obj->{exclude};
    push @{$list}, filter_ent->new($type, $regex, $action);
}

sub check {
    my $obj = shift;
    my($path, $data) = @_;
    my $name = $path =~ s{\A.*/}{}r;
    for my $f ($obj->exclude, $obj->include) {
	my $type = $f->type;
	my $compare = { name => \$name ,
			path => \$path ,
			data =>  $data }->{$type} or die;
	${$compare} =~ $f->regex and return $f->action;
    }
    return $obj->include ? 0 : 1;
}

############################################################

sub opt {
    while (my($k, $v) = splice @_, 0, 2) {
	$opt{$k} = $v;
    }
}

use List::Util qw(reduce);

sub prologue {
    for (
	[ \@select_shebang,  q/,/, data => 1, sub { qr/\A\#!.*\b\Q$_[0]\E/ } ],
	[ \@discard_shebang, q/,/, data => 0, sub { qr/\A\#!.*\b\Q$_[0]\E/ } ],
	[ \@select_suffix,   q/,/, name => 1, sub { qr/\.\Q$_[0]\E$/ } ],
	[ \@discard_suffix,  q/,/, name => 0, sub { qr/\.\Q$_[0]\E$/ } ],
	[ \@select_data,     q//,  data => 1 ],
	[ \@discard_data,    q//,  data => 0 ],
	[ \@select_name,     q//,  name => 1 ],
	[ \@discard_name,    q//,  name => 0 ],
	[ \@select_path,     q//,  path => 1 ],
	[ \@discard_path,    q//,  path => 0 ],
	) {
	my($list, $split, $type, $action, $re) = @$_;
	do {
	    map { $select->add($type, $_, $action) }
	    map { $re ? $re->($_) : qr/$_/ }
	    map { $split ? split($split, $_) : $_ }
	    @$list;
	}
    }
}

sub select {
    my %arg = @_;
    my $name = delete $arg{&FILELABEL} or die;
    if ($select->check($name, *_)) {
	say $name if $opt{yes};
	$opt{die} and die "SKIP $name";
    } else {
	say $name if $opt{no};
	die "SKIP $name";
    }
}

1;

__DATA__

option default \
	--prologue __PACKAGE__::prologue \
	--begin    __PACKAGE__::select

builtin   shebang=s @select_shebang
builtin   suffix=s  @select_suffix
builtin x-shebang=s @discard_shebang
builtin x-suffix=s  @discard_suffix

builtin   select-name=s @select_name
builtin   select-path=s @select_path
builtin   select-data=s @select_data
builtin x-select-name=s @discard_name
builtin x-select-path=s @discard_path
builtin x-select-data=s @discard_data

#  LocalWords:  greple shebang perl regex aka
