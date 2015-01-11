package App::Greple::Grep;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw(FILELABEL);
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

use Data::Dumper;
use Scalar::Util qw(blessed);

use Getopt::RC::Func;

use App::Greple::Common;
use App::Greple::Regions;


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

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub new_func {
    new Getopt::RC::Func @_;
}

sub grep_pattern {
    my $self = shift;

    local *_ = $self->{text};
    my @patterns = @{$self->{pattern}};
    my @blocks;

    ##
    ## build match result list
    ##
    my @result;
    my %required = (yes => 0, no => 0);
    for my $i (0 .. $#patterns) {
	my($sw, $regex) = @{$patterns[$i]};
	my($func, @args) = do {
	    if (ref $regex eq 'ARRAY') {
		new_func(@$regex);
	    }
	    elsif (blessed $regex and $regex->can('call')) {
		$regex;
	    }
	    elsif (ref $regex eq 'CODE') {
		new_func($regex);
	    }
	    else {
		new_func(\&match_regions, pattern => $regex);
	    }
	};
	my @p = $func->call(@args, &FILELABEL => $self->{filename});
	if (@p) {
	    if ($sw eq MATCH_MUST or $sw eq MATCH_POSITIVE) {
		push @blocks, map { [ @$_ ] } @p;
		$self->{stat}->{match_positive} += @p;
		$required{yes}++;
	    } else {
		$self->{stat}->{match_negative} += @p;
		$required{no}++;
	    }
	    map { push @$_, $i } @p;
	}
	push @result, \@p;
    }
    $self->{stat}->{match_block} += @blocks;

    ##
    ## optimization for zero match
    ##
    if ($required{yes} == 0 and $self->{need} > 0) {
	$self->{result} = [];
	return $self;
    }

    ##
    ## --inside, --outside
    ##
    my @reg_union = @{$self->{reg_union}};
    if (@reg_union) {
	my @tmp = map { [] } @result;
	for my $regi (0 .. $#reg_union) {
	    my($in_out, $arg) = @{$reg_union[$regi]};
	    my @select = get_regions($self->{filename}, \$_, $arg);
	    next unless $in_out == REG_OUT or @select;
	    for my $resi (0 .. $#result) {
		my $r = $result[$resi];
		my @l = select_regions({ strict => $self->{strict} },
				       $r, \@select, $in_out);
		if ($self->{region_index} or @result == 1) {
		    map { $_->[2] = $regi } @l;
		}
		push @{$tmp[$resi]}, @l;
	    }
	}
	@result = map { [ merge_regions(@$_) ] } @tmp;
    }

    ##
    ## --include, --exclude
    ##
    my @reg_clude = @{$self->{reg_clude}};
    for my $region (@reg_clude) {
	my($in_out, $arg) = @$region;
	my @select = get_regions($self->{filename}, \$_, $arg);
	next unless $in_out == REG_IN or @select;
	for my $r (@result) {
	    @$r = select_regions({ strict => $self->{strict} },
				 $r, \@select, $in_out);
	}
    }

    ##
    ## --all
    ##
    if ($self->{all}) {
	@blocks = ( [ 0, length $_ ] );
    }
    ##
    ## --block
    ##
    elsif (@{$self->{block}}) {
	@blocks = ();
	for my $re (@{$self->{block}}) {
	    push @blocks, get_regions($self->{filename}, \$_, $re);
	}
    	@blocks = merge_regions({nojoin => 1}, @blocks);
    }
    ##
    ## build block list from matched range
    ##
    elsif (@blocks) {
	my $textp = \$_;
	my %opt = (A => $self->{after},
		   B => $self->{before},
		   p => $self->{paragraph});
	my $sub_blocknize = optimized_blocknize(\%opt);
    	@blocks =
	    merge_regions({nojoin => 1},
			  map({[$sub_blocknize->(\%opt,
						 $textp, $_->[0], $_->[1])]}
			      @blocks));
    }

    ##
    ## build match table
    ##
    my @match_table = map { [ 0, 0, [], 0, 0, [], 0, 0, [] ] } @blocks;
    for my $i (0 .. $#result) {
	my $base = $match_base[$patterns[$i][0]];
	my @b = classify_regions({ strict => $self->{strict} },
				 $result[$i], \@blocks);
	for my $bi (0 .. $#b) {
	    my $te = $match_table[$bi];
	    if (@{$b[$bi]}) {
		${$te}[$base + INDX_POSI]++;
		push @{$te->[$base + INDX_LIST]}, @{$b[$bi]};
	    } else {
		${$te}[$base + INDX_NEGA]++;
	    }
	}
    }

    show_match_table(\@match_table) if $opt_d{v};

    ##
    ## now it is quite easy to get effective blocks
    ##
    my @effective_index = grep(
	$match_table[$_][MUST_NEGA] == 0 &&
	$match_table[$_][POSI_POSI] >= $self->{need} &&
	$match_table[$_][NEGA_POSI] <= $self->{allow},
	0 .. $#blocks);

    ##
    ## --block with -ABC option
    ##
    if (@{$self->{block}} and ($self->{after} or $self->{before})) {
	my %mark;
	for my $i (@effective_index) {
	    map($mark{$_} = 1,
		max($i - $self->{before}, 0)
		..
		min($i + $self->{after}, $#blocks));
	}
	@effective_index = sort { $a <=> $b } map { int $_ } keys %mark;
    }

    ##
    ## compose the result
    ##
    my @list = ();
    for my $bi (@effective_index) {
	my @matched = merge_regions({nojoin => $self->{only}},
				    @{$match_table[$bi][MUST_LIST]},
				    @{$match_table[$bi][POSI_LIST]},
				    @{$match_table[$bi][NEGA_LIST]}
	    );
	if ($self->{only}) {
	    push @list, map({ [ $_, $_ ] } @matched);
	} else {
	    push @list, [ $blocks[$bi], @matched ];
	}
    }

    ##
    ## ( [ [blockstart, blockend], [start, end], [start, end], ... ],
    ##   [ [blockstart, blockend], [start, end], [start, end], ... ], ... )
    ##
    $self->{result} = \@list;

    $self;
}

sub result {
    my $obj = shift;
    @{ $obj->{result} };
}

BEGIN {
    $Data::Dumper::Terse = 1;
}
sub show_match_table {
    my $i = 0;
    for my $t (@{+shift}) {
	my $m = Dumper($t);
	$m =~ s/\s+(?!$)/ /gs;
	printf STDERR "%d %s", $i++, $m;
    }
}

sub get_regions {
    my $file = shift;
    local *_ = shift;
    my $pattern = shift;

    ## func object
    if (blessed $pattern and $pattern->can('call')) {
	$pattern->call(&FILELABEL => $file);
    }
    ## pattern
    else {
	match_regions(pattern => $pattern);
    }
}

sub optimized_blocknize {
    my %opt = %{$_[0]};
    my($begin, $end) = (-1, -1);
    if ($opt{p} or $opt{A} or $opt{B}) {
	\&blocknize;
    } else {
	sub {
	    if ($begin <= $_[1] and $_[2] < $end) {
		;
	    } else {
		($begin, $end) = &blocknize;
	    }
	    ($begin, $end);
	}
    }
}

sub blocknize {
    my %opt = %{+shift};
    local *_ = shift;		# text
    my($from, $to) = @_;	# range
    my $matched = substr($_, $from, $to - $from);

    my $delim = $opt{p} ? "\n\n" : "\n";

    my $begin = $from;
    for (my $c = $opt{B} + 1; $c; $c--) {
	if ($opt{p}) {
	    $begin-- while substr($_, $begin, 2) eq "\n\n";
	}
	$begin = rindex($_, $delim, $begin - length $delim);
	last if $begin < 0;
    }
    if ($begin < 0) {
	$begin = 0;
    } else {
	$begin += length $delim;
    }

    ##
    ## This decision is quite difficult when the matched strings
    ## contains multiple newlines at the end.  I'm not sure what
    ## behavior is most intuitive.
    ##
    $to -= length $1 if $matched =~ /(\n{1,1})\z/;
    pos($_) = $to;

    my $end;
    for (my $c = $opt{A} + 1; $c; $c--) {
	if ($opt{p} ? /\G \n?+ (?:.+\n)* (\n+)/gx : /\G.*\n()/g) {
	    $end = pos() - length $1;
	    next;
	}
	$end = length $_;
	last;
    }
    $end // die;

    ($begin, $end);
}

1;
