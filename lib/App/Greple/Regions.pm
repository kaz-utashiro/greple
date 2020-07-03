package App::Greple::Regions;

use v5.14;
use warnings;
use Carp;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Exporter 'import';
our @EXPORT      = qw(REGION_INSIDE REGION_OUTSIDE
		      REGION_UNION  REGION_INTERSECT
		      match_regions
		      classify_regions
		      select_regions
		      merge_regions
		      reverse_regions
		      match_borders
		      borders_to_regions
		      );
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use constant {

    REGION_AREA_MASK  => 1,
    REGION_INSIDE     => 0,
    REGION_OUTSIDE    => 1,

    REGION_SET_MASK   => 2,
    REGION_INTERSECT  => 0,
    REGION_UNION      => 2,
};

sub new {
    my $class = shift;

    my $obj = bless {
	FLAG => undef,
	SPEC => undef,
    }, $class;

    configure $obj @_ if @_;

    $obj;
}

sub configure {
    my $obj = shift;
    while (@_ >= 2) {
	$obj->{$_[0]} = $_[1];
	splice @_, 0, 2;
    }
}

sub spec         { shift -> {SPEC} }
sub flag         { shift -> {FLAG} }
sub is_union     { (shift->flag & REGION_SET_MASK ) == REGION_UNION     }
sub is_intersect { (shift->flag & REGION_SET_MASK ) == REGION_INTERSECT }
sub is_inside    { (shift->flag & REGION_AREA_MASK) == REGION_INSIDE    }
sub is_outside   { (shift->flag & REGION_AREA_MASK) == REGION_OUTSIDE   }

package App::Greple::Regions::Holder {

    sub new {
	my $class = shift;
	bless [], $class;
    }

    sub append {
	my $obj = shift;
	push @$obj, App::Greple::Regions->new(@_);
    }

    sub regions {
	my $obj = shift;
	@$obj;
    }

    sub union {
	grep { $_->is_union } shift->regions;
    }

    sub intersect {
	grep { $_->is_intersect } shift->regions;
    }
}

sub match_regions {
    my %arg = @_;
    my $pattern = $arg{pattern} // croak "Parameter error";
    my $regex = ref $pattern eq 'Regexp' ? $pattern : qr/$pattern/m;
    my @regions;

    no warnings 'utf8';

    while (/$regex/gp) {
	##
	## this is much faster than:
	## my($s, $e) = ($-[0], $+[0]);
	##
	## calling pos() cost is not neglective, either.
	##
	my $pos = pos();
	push @regions, [ $pos - length ${^MATCH}, $pos ];
    }
    @regions;
}

sub classify_regions {
    my $opt = ref $_[0] eq 'HASH' ? shift : {};

    $opt->{strict} and goto &classify_regions_strict;

    my @list = @{+shift};
    my @by = @{+shift};
    my @table;
    for (my $i = 0; $i < @by; $i++) {
	my($from, $to) = @{$by[$i]};
	while (@list and $list[0][1] < $from) {
	    shift @list;
	}
	while (@list and $list[0][1] == $from and $list[0][0] < $from) {
	    shift @list;
	}
	my $t = $table[$i] = [];
	for (my $i = 0; ($i < @list) and ($list[$i][0] < $to); $i++) {
	    push @$t, [ @{$list[$i]} ];
	}
    }
    @table;
}

sub classify_regions_strict {
    my @list = @{+shift};
    my @by = @{+shift};
    my @table;
    for (my $i = 0; $i < @by; $i++) {
	my($from, $to) = @{$by[$i]};
	while (@list and $list[0][0] < $from) {
	    shift @list;
	}
	my $t = $table[$i] = [];
	while (@list and $list[0][0] < $to and $list[0][1] <= $to) {
	    push @$t, shift @list;
	}
    }
    @table;
}

sub select_regions {
    my $opt = ref $_[0] eq 'HASH' ? shift : {};

    $opt->{strict} and goto &select_regions_strict;

    my @list = @{+shift};
    my @by = @{+shift};
    my $flag = shift;

    my(@outside, @inside);

    for (my $i = 0; $i < @by; $i++) {
	my($from, $to) = @{$by[$i]};
	for (my $j = 0; $j < @list and $list[$j][0] < $from; $j++) {
	    push @outside, [ @{$list[$j]} ];
	}
	while (@list and $list[0][0] < $from and $list[0][1] <= $from) {
	    shift @list;
	}
	for (my $j = 0; $j < @list and $list[$j][0] < $to; $j++) {
	    push @inside, [ @{$list[$j]} ];
	}
	while (@list and $list[0][1] < $to) {
	    shift @list;
	}
	while (@list and $list[0][0] < $to and $list[0][1] <= $to) {
	    shift @list;
	}
    }
    push @outside, @list;
    (($flag & REGION_AREA_MASK) == REGION_INSIDE) ? @inside : @outside;
}

sub select_regions_strict {
    my @list = @{+shift};
    my @by = @{+shift};
    my $flag = shift;

    my(@outside, @inside);

    for (my $i = 0; $i < @by; $i++) {
	my($from, $to) = @{$by[$i]};
	while (@list and $list[0][0] < $from and $list[0][1] <= $from) {
	    push @outside, shift(@list);
	}
	while (@list and $list[0][0] < $from) {
	    shift @list;
	}
	while (@list and $list[0][0] < $to and $list[0][1] <= $to) {
	    push @inside, shift(@list);
	}
	while (@list and $list[0][0] < $to) {
	    shift @list;
	}
    }
    push @outside, @list;
    (($flag & REGION_AREA_MASK) == REGION_INSIDE) ? @inside : @outside;
}

sub merge_regions {
    my $option = ref $_[0] eq 'HASH' ? shift : {};
    my $nojoin = $option->{nojoin};
    my @in = $option->{destructive} ? @_ : map { [ @$_ ] } @_;
    unless ($option->{nosort}) {
	@in = sort({$a->[0] <=> $b->[0] || $b->[1] <=> $a->[1]
			||  (@$a > 2 ? $a->[2] <=> $b->[2] : 0)
		   } @in);
    }
    my @out;
    push(@out, shift @in) if @in;
    while (@in) {
	my $top = shift @in;

	if ($out[-1][1] > $top->[0]) {
	    $out[-1][1] = $top->[1] if $out[-1][1] < $top->[1];
	}
	elsif (!$nojoin
	       and $out[-1][1] == $top->[0]
	       ##
	       ## don't connect regions in different pattern group
	       ##
	       and (@$top < 3 or $out[-1][2] == $top->[2])
	    ) {
	    $out[-1][1] = $top->[1] if $out[-1][1] < $top->[1];
	}
	else {
	    push @out, $top;
	}
    }
    @out;
}

use List::Util qw(pairmap);

sub reverse_regions {
    my $option = ref $_[0] eq 'HASH' ? shift : {};
    my($from, $max) = @_;
    my @reverse = do {
	pairmap { [ $a, $b ] }
	0, map( { $_->[0] => $_->[1] } @$from ), $max
    };
    return @reverse if $option->{leave_empty};
    grep { $_->[0] != $_->[1] } @reverse
}

sub match_borders {
    my $regex = shift;
    my @border = (0);
    while (/$regex/gp) {
	my $pos = pos();
	for my $i ($pos - length ${^MATCH}, $pos) {
	    push @border, $i if $border[-1] != $i;
	}
    }
    push @border, length if $border[-1] != length;
    @border;
}

sub borders_to_regions {
    return () if @_ < 2;
    map { [ $_[$_-1], $_[$_] ] } 1..$#_;
}

1;
