package Getopt::EX::LabeledParam;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT      = qw();
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

use Data::Dumper;
use Getopt::EX::Container;
use Getopt::EX::Func qw(parse_func);

sub new {
    my $class = shift;

    my $obj = bless {
	newlabel => 0,
	HASH => {},
	LIST => [],
    }, $class;

    configure $obj @_;

    $obj;
}

sub configure {
    my $obj = shift;
    while (@_ >= 2) {
	my($k, $v) = splice @_, 0, 2;
	if ($k =~ /^\w/ and exists $obj->{$k}) {
	    $obj->{$k} = $v;
	}
    }
    $obj;
}

sub get_hash { shift->{HASH} }

sub set_hash {
    my $obj = shift;
    %{ $obj->{HASH} } = @_;
    $obj;
}

sub list { @{ shift->{LIST} } }

sub push_list {
    my $obj = shift;
    push @{ $obj->{LIST} }, @_;
    $obj;
}

sub set_list {
    my $obj = shift;
    @{ $obj->{LIST} } = @_;
    $obj;
}

sub append {
    my $obj = shift;
    for my $item (@_) {
	if (ref $item eq 'ARRAY') {
	    push @{$obj->{LIST}}, @$item;
	}
	elsif (ref $item eq 'HASH') {
	    while (my($k, $v) = each %$item) {
		$obj->{HASH}->{$k} = $v;
	    }
	}
	else {
	    push @{$obj->{LIST}}, $item;
	}
    }
}

sub load_params {
    my $obj = shift;

    my $re_field = qr/[\w\*\?]+/;
    map {
	my $spec = pop @$_;
	my @spec;
	while ($spec =~ s/\&(\w+ (?: \( [^)]* \) )? ) ;?//x) { # &func
	    push @spec, parse_func({ PACKAGE => 'main' }, $1);
	}
	if ($spec =~ s/\b(sub\s*{.*)//) { # sub { ... }
	    push @spec, parse_func($1);
	}
	push @spec, $spec if $spec ne "";
	my $c = @spec > 1 ? [ @spec ] : $spec[0];
	if (@$_ == 0) {
	    $obj->push_list($c);
	}
	else {
	    map { $obj->{HASH}->{$_} = $c }
	    map {
		if (!/\W/ and $obj->{newlabel}) {
		    $_;
		} else {
		    match_glob($_, keys %{$obj->{HASH}})
		}
	    }
	    @$_;
	}
    }
    map {
	if (my @field = /\G($re_field)=/gp) {
	    [ @field, ${^POSTMATCH} ];
	} else {
	    [ $_ ];
	}
    }
    map {
	m/( (?: $re_field= )*
	    (?: .* \b sub \s* \{ .*
	      | (?: \([^)]*\) | [^,\s] )+
	    )
	  )/gx;
    }
    @_;

    $obj;
}

sub match_glob {
    local $_ = shift;
    s/\?/./g;
    s/\*/.*/g;
    my $regex = qr/^$_$/;
    grep { $_ =~ $regex } @_;
}

1;

=head1 NAME

Getopt::EX::LabeledParam - Labeled parameter handling


=head1 SYNOPSIS

  GetOptions('colormap|cm:s' => @opt_colormap);
  my %colormap;
  my @colors;

  require Getopt::EX::LabeledParam;
  my $cmap = new Getopt::EX::LabeledParam
      newlabel => 0,
      HASH => \%colormap,
      LIST => \@colors,
      ;
  $cmap->append(@opt_colormap);


=head1 DESCRIPTION

This module implements super class of L<Getopt::EX::Colormap>.

Parameters can be given in two ways: one in labeled table, and one in
indexed list.

Basically, labeled parameter is defined by B<LABEL>=I<VALUE> notation:

    FILE=R

Definition can be connected by comma (C<,>):

    FILE=R,LINE=G

Multiple labels can be set for same value:

    FILE=LINE=TEXT=R

Wildcard C<*> and C<?> can be used in label name, and they matches
existing hash key name.  If labels C<OLD_FILE> and C<NEW_FILE> exists
in hash,

    *FILE=R

and

    OLD_FILE=NEW_FILE=R

produces same result.

If B<LABEL>= part is omitted, values are treated anonymous list and
stored in list object.  For example,

    R,G,B,C,M,Y

makes six entries in the list.  The list object is accessed by index,
rather than label.

Handler maintains hash and list objects, and labeled values are stored
in hash, non-label values are in list automatically.  User can mix
both specifications.

When the value field has a special form of function call,
L<Getopt::EX::Func> object is created and stored for that entry.  See
L<FUNCTION SPEC> section in L<Getopt::EX::Colormap> for more detail.
Module should have switch to enable this capability, but not now.


=head1 METHODS

=over 4

=item B<configure>

=over 4

=item B<HASH> =E<gt> I<hashref>

=item B<LIST> =E<gt> I<listref>

B<HASH> and B<LIST> reference can be set by B<new> or B<configure>
method.  You can provide default setting of hash and list, and it is
usually easier to access those values directly, rather than through
class methods.

=item B<newlable> =E<gt> 0/1

By default, B<load_params> does not create new entry in colormap
table, and absent label is ignored.  Setting <newlabel> parameter true
makes it possible create a new hash entry.

=back

=item B<append> HASHREF or LIST

Append colormap hash or color list.  If a hash reference is given, all
entry of the hash is appended to the colormap.  Otherwise, they are
appended anonymous color list.

=back
