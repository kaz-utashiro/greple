package App::Greple::Grep;

use v5.24;
use warnings;

use Exporter 'import';
our @EXPORT      = qw(FILELABEL);
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

our @ISA = qw(App::Greple::Text);

use Data::Dumper;
use List::Util qw(min max reduce sum);
use Clone qw(clone);

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

package App::Greple::Grep::Block {
    use strict;
    sub min    :lvalue { $_[0]->[0] }
    sub max    :lvalue { $_[0]->[1] }
    sub number :lvalue { $_[0]->[2] }
}

package App::Greple::Grep::Match {
    use strict;
    sub min      :lvalue { $_[0]->[0] }
    sub max      :lvalue { $_[0]->[1] }
    sub index    :lvalue { $_[0]->[2] }
    sub callback :lvalue { $_[0]->[3] }
}

package App::Greple::Grep::Result {
    use strict;
    sub block   { $_[0]->[0] }
    sub matched { $_[0]->@[ 1 .. $#{$_[0]} ] }
    sub min     { $_[0]->block->min }
    sub max     { $_[0]->block->max }
    sub number  { $_[0]->block->number }
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
    my $group_index_offset = 0;
    my @patlist = $pat_holder->patterns;
    while (my($i, $pat) = each @patlist) {
	my($func, @args) = do {
	    if ($pat->is_function) {
		$pat->function;
	    } else {
		Getopt::EX::Func->new(\&match_regions,
				      pattern => $pat->regex,
				      group => $self->{group_index},
				      index => $self->{group_index} >= 2,
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
	    ##
	    ## Update offset even when no match for --ci=G
	    ##
	    if ($self->{group_index} == 2 and not $pat->is_function) {
		$group_index_offset += $pat->group_count //= do {
		    "" =~ /@{[$pat->regex]}?/;
		    $#+ || 1;
		};
	    }
	} else {
	    bless $_, 'App::Greple::Grep::Match' for @p;
	    if ($pat->is_positive) {
		push @blocks, @{clone(\@p)};
		$self->{stat}->{match_positive} += @p;
		$positive_count++;
	    }
	    else {
		$self->{stat}->{match_negative} += @p;
	    }
	    ##
	    ## Adjust group index for --ci=G option
	    ## group_index: 0=off, 1=group, 2=sequential, 3=per-pattern
	    ##
	    if ($self->{group_index} == 2) {
		my $max_index = 0;
		for (@p) {
		    if (defined $_->index) {
			$_->index += $group_index_offset;
			$max_index = $_->index + 1 if $_->index >= $max_index;
		    }
		}
		$group_index_offset = $max_index;
	    }
	    $_->index //= $i for @p;
	    if (my $n = $self->{callback}->@*) {
		if (my $callback = $self->{callback}->[ $i % $n ]) {
		    $_->callback //= $callback for @p;
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
	if ($self->{block}->@*) {		# --block
	    my $text = \$_;
	    merge_regions { nojoin => 1, destructive => 1 }, map {
		get_regions($self->{filename}, $text, $_);
	    } $self->{block}->@*;
	}
	elsif (@blocks) {			# from matched range
	    my %opt = ( A => $self->{after},
		        B => $self->{before},
		        border => [ $self->borders ] );
	    my $blocker = smart_blocker(\%opt);
	    merge_regions { nojoin => 1, destructive => 1 }, map {
		[ $blocker->(\%opt, $_->min, $_->max) ]
	    } @blocks;
	}
	else {
	    ( [ 0, length ] );			# nothing matched
	}
    } ];
    while (my($i, $blk) = each @$bp) {
	bless $blk, 'App::Greple::Grep::Block';
	# set 1-origined block number in the 3rd entry
	$blk->number = $i + 1;
    }

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
	    grep { $countcheck->(int($mp->[$_][POSI_LIST]->@*)) }
	    @effective_index;
	}
	or return $self;
    }

    ##
    ## --block with -ABC option
    ##
    if ($self->{block}->@* and ($self->{after} or $self->{before})) {
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
				    $mp->[$bi][MUST_LIST]->@*,
				    $mp->[$bi][POSI_LIST]->@*,
				    $mp->[$bi][NEGA_LIST]->@*);
	if ($self->{stretch}) {
	    my $b = $bp->[$bi];
	    my $m = $matched[0];
	    my $i = min map { $_->[2] // 0 } @matched;
	    @matched = [ $b->min, $b->max, $i, $m->[3] ];
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
    for my $r (@list) {
	bless $r, 'App::Greple::Grep::Result';
	bless $r->block, 'App::Greple::Grep::Block';
	for my $m ($r->matched) {
	    bless $m, 'App::Greple::Grep::Match';
	}
    }

    ##
    ## --join-blocks
    ##
    if ($self->{join_blocks} and @list > 1) {
	reduce {
	    if ($a->[-1][0]->max == $b->[0]->min) {
		$a->[-1][0]->max  = $b->[0]->max;
		push @{$a->[-1]}, splice @$b, 1;
	    } else {
		push @$a, $b;
	    }
	    $a;
	} \@list, splice @list, 1;
    }

    ##
    ## ( [ [blockstart, blockend, number ], [start, end], [start, end], ... ],
    ##   [ [blockstart, blockend, number ], [start, end], [start, end], ... ], ... )
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
        warn "alert timer start ($alarm_start)\n" if $debug{a};
    }
    my @borders = match_borders $self->{border};
    if (defined $alarm_start) {
	if ($SIG{ALRM}) {
	    alarm 0;
	    warn "reset alert timer\n" if $debug{a};
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
    sum(map { $_->@* - 1 } $obj->result) // 0;
}

sub blocks {
    my $obj = shift;
    $obj->{BLOCKS}->@*;
}

sub slice_result {
    my $obj = shift;
    my $result = shift;
    my($block, @list) = @$result;
    my $template = unpack_template(\@list, $block->min);
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

package App::Greple::Text {
    use strict;
    use warnings;
    use overload '""' => sub { ${ $_[0]->{text} } };
    sub new {
	my $class = shift;
	bless { text => \$_[0] }, $class;
    }
    sub text { ${ $_[0]->{text} } }
    sub cut {
	my($obj, $from, $to) = @_;
	substr ${ $obj->{text} }, $from, $to - $from;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Greple::Grep - Greple grep engine module

=head1 SYNOPSIS

    use App::Greple::Grep;

    my $grep = App::Greple::Grep->new(
        text     => \$text,
        filename => $filename,
        pattern  => $pattern_holder,
        ...
    )->run;

    for my $result ($grep->result) {
        my $block = $result->block;
        for my $match ($result->matched) {
            # process each match
        }
    }

=head1 DESCRIPTION

This module provides the core grep engine for the B<greple> command.
It is typically not used directly, but can be accessed through the
C<--postgrep> option to manipulate search results.

=head1 CLASSES

=head2 App::Greple::Grep::Block

Represents a text block containing matched patterns.

=over 4

=item B<min>

Start position of the block (0-origin byte offset).

=item B<max>

End position of the block.

=item B<number>

Block number (1-origin).

=back

=head2 App::Greple::Grep::Match

Represents an individual match within a block.

=over 4

=item B<min>

Start position of the match.

=item B<max>

End position of the match.

=item B<index>

Pattern index (0-origin) indicating which pattern matched.
Used for colorization with C<--colorindex> option.

=item B<callback>

Callback function to be called when this match is output.
The callback receives the following arguments:

For CODE reference:

    $callback->($start, $end, $index, $matched_string)

For L<Getopt::EX::Func> object:

    $callback->call(
        &FILELABEL => $file,
        start => $start,
        end   => $end,
        index => $index,
        match => $matched_string,
    )

The callback should return the string to be output.  If it returns
C<undef>, the original matched string is used.

=back

=head2 App::Greple::Grep::Result

Represents the search result for a single block.

=over 4

=item B<block>

Returns the C<App::Greple::Grep::Block> object.

=item B<matched>

Returns a list of C<App::Greple::Grep::Match> objects.

=item B<min>, B<max>, B<number>

Shortcuts for C<< $result->block->min >>, etc.

=back

=head1 METHODS

=head2 App::Greple::Grep

=over 4

=item B<result>

Returns a list of C<App::Greple::Grep::Result> objects.

=item B<result_ref>

Returns a reference to the result array.  This can be used to modify
the results in a C<--postgrep> function.

=item B<matched>

Returns the total number of matches.

=item B<blocks>

Returns a list of all blocks.

=item B<cut>(I<$from>, I<$to>)

Returns the substring of the text from position I<$from> to I<$to>.

=item B<slice_result>(I<$result>)

Returns a list of strings alternating between unmatched and matched
portions within the block.

=back

=head1 USING --postgrep OPTION

The C<--postgrep> option allows you to process the Grep object after
the search is complete.  The function receives the Grep object as its
argument.

    sub postgrep {
        my $grep = shift;
        for my $result ($grep->result) {
            for my $match ($result->matched) {
                # Modify match attributes
                $match->callback = sub { ... };
            }
        }
    }

=head1 CALLBACK EXAMPLE

The L<App::Greple::subst> module uses callbacks to replace matched
text:

    my $callback = sub {
        my($start, $end, $index, $matched) = @_;
        # Return replacement string
        return $replacement;
    };

    for my $match ($result->matched) {
        $match->callback = $callback;
    }

=head1 SEE ALSO

L<greple>, L<App::Greple::subst>
