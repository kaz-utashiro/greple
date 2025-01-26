package App::Greple::Grep;

use v5.14;
use warnings;

use Exporter 'import';
our @EXPORT      = qw(FILELABEL);
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

our @ISA = qw(App::Greple::Text);

use Data::Dumper;
use List::Util qw(min max reduce sum);

use Getopt::EX::Func qw(callable);

use App::Greple::Common qw(%debug &FILELABEL);
use App::Greple::Regions;
use App::Greple::Pattern;

use constant {
    MATCH_NEGATIVE => 0,
    MATCH_POSITIVE => 1,
    MATCH_MUST     => 2,
};
push @EXPORT, qw(
    MATCH_NEGATIVE
    MATCH_POSITIVE
    MATCH_MUST
);

use constant {
    POSI_BASE => 0, POSI_POSI => 0, POSI_NEGA => 1, POSI_LIST => 2,
    NEGA_BASE => 3, NEGA_POSI => 3, NEGA_NEGA => 4, NEGA_LIST => 5,
    MUST_BASE => 6, MUST_POSI => 6, MUST_NEGA => 7, MUST_LIST => 8,
    INDX_POSI => 0, INDX_NEGA => 1, INDX_LIST => 2,
};

my @match_base;
BEGIN {
    $match_base[MATCH_POSITIVE] = POSI_BASE;
    $match_base[MATCH_NEGATIVE] = NEGA_BASE;
    $match_base[MATCH_MUST] = MUST_BASE;
}

sub category {
    my $obj = shift;
    return MATCH_MUST     if $obj->is_required;
    return MATCH_NEGATIVE if $obj->is_negative;
    return MATCH_POSITIVE;
}

sub new {
    my $class = shift;
    my $obj = bless { @_ }, $class;
    $obj;
}

sub run {
    my $self = shift;
    $self->prepare->compose;
}

sub prepare {
    my $self = shift;

    local *_ = $self->{text};
    my $pat_holder = $self->{pattern};
    my @blocks;

    $self->{RESULT} = [];
    $self->{BLOCKS} = [];

    ##
    ## build match result list
    ##
    my @result;
    my $positive_count = 0;
    my @patlist = $pat_holder->patterns;
    while (my($i, $pat) = each @patlist) {
	my($func, @args) = do {
	    if ($pat->is_function) {
		$pat->function;
	    } else {
		Getopt::EX::Func->new(\&match_regions,
				      pattern => $pat->regex,
				      group => $self->{group_match},
				      index => $self->{group_index},
		    );
	    }
	};
	my @p = $func->call(@args, &FILELABEL => $self->{filename});
	if (@p == 0) {
	    ##
	    ## $self->{need} can be negative value, which means
	    ## required pattern can be compromised upto that number.
	    ##
	    return $self if $pat->is_required and $self->{need} >= 0;
	} else {
	    if ($pat->is_positive) {
		push @blocks, map { [ @$_ ] } @p;
		$self->{stat}->{match_positive} += @p;
		$positive_count++;
	    }
	    else {
		$self->{stat}->{match_negative} += @p;
	    }
	    map { $_->[2] //= $i } @p;
	    if (my $n = @{$self->{callback}}) {
		if (my $callback = $self->{callback}->[ $i % $n ]) {
		    map { $_->[3] //= $callback } @p;
		}
	    }
	}
	push @result, \@p;
    }
    $self->{stat}->{match_block} += @blocks;

    ##
    ## optimization for inadequate match
    ##
    return $self if $positive_count < $self->{need} + $self->{must};

    ##
    ## --inside, --outside
    ##
    if (my @reg_union = $self->{regions}->union) {
	my @tmp = map { [] } @result;
	while (my($regi, $reg) = each @reg_union) {
	    my @select = get_regions($self->{filename}, \$_, $reg->spec);
	    @select or next if $reg->is_inside;
	    while (my($resi, $r) = each @result) {
		my @l = select_regions({ strict => $self->{strict} },
				       $r, \@select, $reg->flag);
		if ($self->{region_index} // @result == 1) {
		    map { $_->[2] = $regi } @l;
		}
		push @{$tmp[$resi]}, @l;
	    }
	}
	@result = map { [ merge_regions { nojoin => 1, destructive => 1 }, @$_ ] } @tmp;
    }

    ##
    ## --include, --exclude
    ##
    for my $reg ($self->{regions}->intersect) {
	my @select = get_regions($self->{filename}, \$_, $reg->spec);
	@select or next if not $reg->is_outside;
	for my $r (@result) {
	    @$r = select_regions({ strict => $self->{strict} },
				 $r, \@select, $reg->flag);
	}
    }

    ##
    ## Setup BLOCKS
    ##
    my $bp = $self->{BLOCKS} = [ do {
	if (@{$self->{block}}) {		# --block
	    my $text = \$_;
	    merge_regions { nojoin => 1, destructive => 1 }, map {
		grep { $_->[0] != $_->[1] }
		get_regions($self->{filename}, $text, $_);
	    } @{$self->{block}};
	}
	elsif (@blocks) {			# from matched range
	    my %opt = ( A => $self->{after},
		        B => $self->{before},
		        border => [ $self->borders ] );
	    my $blocker = smart_blocker(\%opt);
	    merge_regions { nojoin => 1, destructive => 1 }, map {
		[ $blocker->(\%opt, $_->[0], $_->[1]) ]
	    } @blocks;
	}
	else {
	    ( [ 0, length ] );			# nothing matched
	}
    } ];

    ##
    ## build match table
    ##
    my @match_table = map { [ 0, 0, [], 0, 0, [], 0, 0, [] ] } @$bp;
    while (my($ri, $r) = each @result) {
	my $base = $match_base[category($patlist[$ri])];
	my @b = classify_regions({ strict => $self->{strict} }, $r, $bp);
	while (my($bi, $b) = each @b) {
	    my $t = $match_table[$bi];
	    if (@$b) {
		${$t}[$base + INDX_POSI]++;
		push @{$t->[$base + INDX_LIST]}, @$b;
	    } else {
		${$t}[$base + INDX_NEGA]++;
	    }
	}
    }

    show_match_table(\@match_table) if $debug{g};

    $self->{MATCH_TABLE} = \@match_table;

    $self;
}

sub compose {
    my $self = shift;
    my $bp = $self->{BLOCKS};
    my $mp = $self->{MATCH_TABLE};

    ##
    ## now it is quite easy to get effective blocks
    ##
    my $compromize = $self->{need} < 0 ? abs($self->{need}) : 0;
    my @effective_index = grep(
	$mp->[$_][MUST_NEGA] <= $compromize &&
	$mp->[$_][POSI_POSI] >= $self->{need} &&
	$mp->[$_][NEGA_POSI] <= $self->{allow},
	keys @$bp)
	or return $self;

    ##
    ## --matchcount
    ##
    if (my $countcheck = $self->{countcheck}) {
	@effective_index = do {
	    grep { $countcheck->(int(@{$mp->[$_][POSI_LIST]})) }
	    @effective_index;
	}
	or return $self;
    }

    ##
    ## --block with -ABC option
    ##
    if (@{$self->{block}} and ($self->{after} or $self->{before})) {
	my @mark;
	for my $i (@effective_index) {
	    map { $mark[$_] = 1 if $_ >= 0 }
	    $i - $self->{before} .. $i + $self->{after};
	}
	@effective_index = grep $mark[$_], keys @$bp;
    }

    ##
    ## compose the result
    ##
    my @list = ();
    for my $bi (@effective_index) {
	my @matched = merge_regions({ nojoin => 1, destructive => 1 },
				    @{$mp->[$bi][MUST_LIST]},
				    @{$mp->[$bi][POSI_LIST]},
				    @{$mp->[$bi][NEGA_LIST]});
	if ($self->{stretch}) {
	    my $b = $bp->[$bi];
	    my $m = $matched[0];
	    my $i = min map { $_->[2] // 0 } @matched;
	    @matched = [ $b->[0], $b->[1], $i, $m->[3] ];
	}
	if ($self->{only}) {
	    push @list, map({ [ $_, $_ ] } @matched);
	} elsif ($self->{all}) {
	    push @list, [ [ 0, length ] ] if @list == 0;
	    push @{$list[0]}, @matched;
	} else {
	    push @list, [ $bp->[$bi], @matched ];
	}
    }

    ##
    ## --join-blocks
    ##
    if ($self->{join_blocks} and @list > 1) {
	reduce {
	    if ($a->[-1][0][-1] == $b->[0][0]) {
		$a->[-1][0][-1]  = $b->[0][1];
		push @{$a->[-1]}, splice @$b, 1;
	    } else {
		push @$a, $b;
	    }
	    $a;
	} \@list, splice @list, 1;
    }

    ##
    ## ( [ [blockstart, blockend], [start, end], [start, end], ... ],
    ##   [ [blockstart, blockend], [start, end], [start, end], ... ], ... )
    ##
    $self->{RESULT} = \@list;

    $self;
}

sub borders {
    my $self = shift;
    local $SIG{ALRM};
    my $alarm_start;
    if ($self->{alert_size} and length >= $self->{alert_size}) {
	$alarm_start = time;
	$SIG{ALRM} = sub {
	    $SIG{ALRM} = undef;
	    STDERR->printflush(
		$self->{filename} .
		": Counting lines, and it may take longer...\n");
	};
	alarm $self->{alert_time};
    }
    my @borders = match_borders $self->{border};
    if (defined $alarm_start) {
	if ($SIG{ALRM}) {
	    alarm 0;
	} else {
	    STDERR->printflush(sprintf("Count %d lines in %d seconds.\n",
				       @borders - 1,
				       time - $alarm_start));
	}
    }
    @borders;
}

sub result_ref {
    my $obj = shift;
    $obj->{RESULT};
}

sub result {
    my $obj = shift;
    @{ $obj->{RESULT} };
}

sub matched {
    my $obj = shift;
    sum(map { @{$_} - 1 } $obj->result) // 0;
}

sub blocks {
    my $obj = shift;
    @{ $obj->{BLOCKS} };
}

sub slice_result {
    my $obj = shift;
    my $result = shift;
    my($block, @list) = @$result;
    my $template = unpack_template(\@list, $block->[0]);
    unpack($template, $obj->cut(@$block));
}

sub slice_index {
    my $obj = shift;
    my $result = shift;
    my($block, @list) = @$result;
    map { $_ * 2 + 1 } keys @list;
}

sub unpack_template {
    ##
    ## make template to split result text into matched and unmatched parts
    ##
    my($matched, $offset) = @_;
    my @len;
    for (@$matched) {
	my($s, $e) = @$_;
	$s = $offset if $s < $offset;
	push @len, $s - $offset, $e - $s;
	$offset = $e;
    }
    join '', map "a$_", @len, '*';
}

sub show_match_table {
    my $table = shift;
    local $Data::Dumper::Terse = 1;
    while (my($i, $e) = each @$table) {
	printf STDERR
	    "%4d %s", $i++, Dumper($e) =~ s/\s+(?!$)/ /gsr;
    }
}

sub get_regions {
    my $file = shift;
    local *_ = shift;
    my $pattern = shift;

    ## func object
    if (callable $pattern) {
	$pattern->call(&FILELABEL => $file);
    }
    ## pattern
    else {
	match_regions(pattern => $pattern);
    }
}

sub smart_blocker {
    my $opt = shift;
    return \&blocker if $opt->{A} or $opt->{B};
    my $from = my $to = -1;
    sub {
	if ($from <= $_[1] and $_[2] < $to) {
	    return($from, $to);
	}
	($from, $to) = &blocker;
    }
}

use List::BinarySearch qw(binsearch_pos);

sub blocker {
    my($opt, $from, $to) = @_;
    my $border = $opt->{border};

    my $bi = binsearch_pos { $a <=> $b } $from, @$border;
    $bi-- if $border->[$bi] != $from;
    $bi = max 0, $bi - $opt->{B} if $opt->{B};

    my $ei = binsearch_pos { $a <=> $b } $to, @$border;
    $ei++ if $ei == $bi and $ei < $#{$border};
    $ei = min $#{$border}, $ei + $opt->{A} if $opt->{A};

    @$border[ $bi, $ei ];
}

1;


package App::Greple::Text;

use strict;
use warnings;

use overload 
    '""' => \&stringify;

sub stringify {
    my $obj = shift;
    ${ $obj->{text} };
}

sub new {
    my $class = shift;
    my $obj = bless {
	text => \$_[0],
    }, $class;
    $obj;
}

sub text {
    my $obj = shift;
    ${ $obj->{text} };
}

sub cut {
    my $obj = shift;
    my($from, $to) = @_;
    substr ${ $obj->{text} }, $from, $to - $from;
}

1;
