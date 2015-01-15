package App::Greple::Regions;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT      = qw(REGION_INSIDE REGION_OUTSIDE
		      REGION_UNION  REGION_INTERSECT
		      match_regions
		      classify_regions
		      select_regions
		      merge_regions
		      reverse_regions
		      );
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use constant {

    REGION_AREA_MASK  => 1,
    REGION_INSIDE     => 1,
    REGION_OUTSIDE    => 0,

    REGION_SET_MASK   => 2,
    REGION_UNION      => 2,
    REGION_INTERSECT  => 0,
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

sub spec         { shift -> {SPEC} }
sub flag         { shift -> {FLAG} }
sub is_union     { shift->flag & REGION_UNION  }
sub is_intersect { not (shift -> is_union)     }
sub is_inside    { shift->flag & REGION_INSIDE }
sub is_outside   { not (shift -> is_inside)    }

{
    package App::Greple::Regions::Holder;

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

sub configure {
    my $obj = shift;
    while (@_ >= 2) {
	$obj->{$_[0]} = $_[1];
	splice @_, 0, 2;
    }
}

sub match_regions {
    my %arg = @_;
    my $pattern = $arg{pattern} // croak "Parameter error";
    my $regex = ref $pattern eq 'Regexp' ? $pattern : qr/$pattern/m;
    my @regions;
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
	while (@list and $list[0][1] < $from) {
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
    ($flag & REGION_INSIDE) ? @inside : @outside;
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
    ($flag & REGION_INSIDE) ? @inside : @outside;
}

sub merge_regions {
    my $option = ref $_[0] eq 'HASH' ? shift : {};
    my $nojoin = $option->{nojoin};
    my @in = @_;
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

sub reverse_regions {
    my $from = shift;
    my $max = shift;
    my @flat = (0, map(@$_, @$from), $max);

    grep { $_->[0] != $_->[1] }
    map  { [ splice(@flat, 0, 2) ] }
    0 .. @flat / 2 - 1;
}

1;
