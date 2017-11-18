=head1 NAME

ppi - Greple module to use Perl PPI module

=head1 SYNOPSIS

greple -Mppi

=head1 DESCRIPTION

=cut

package App::Greple::ppi;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use List::Util qw(sum);

use PPI;
use PPI::Dumper;

use App::Greple::Common;

use Exporter 'import';
our @EXPORT      = qw(&ppi_opt &ppi_prune &part &colordump &colordump_re);
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

END { }

my $debug;
my $docsrc = -1;
my $doc;

sub update_doc {
    return if $docsrc == \$_;
    $doc = PPI::Document->new(\$_);
    $docsrc = \$_;
}

my $target = -1;
my %part;

sub update_part {
    return if $target == \$_;

    $part{top} = [ toplevel($doc) ];
    $part{statement} = [ statement($doc) ];

    $target = \$_;
}

sub ppi_opt {
    my %arg = @_;
    my $file = delete $arg{&FILELABEL} or die;

    update_doc();
    if ($arg{dump}) {
	$_ = PPI::Dumper->new($doc)->string;
    }
    $debug = 1 if $arg{debug};
}

sub ppi_prune {
    my %arg = @_;
    my $file = delete $arg{&FILELABEL} or die;

    update_doc();
    for my $class (grep { $arg{$_} } keys %arg) {
	$doc->prune($class);
    }
}

sub part {
    my %arg = @_;
    my $file = delete $arg{&FILELABEL} or die;

    update_doc();
    update_part();

    regions(grep { $arg{$_} } keys %arg);
}

sub regions {
    sort { $a->[0] <=> $b->[0] }
    map  { @{ $part{$_} } }
    grep { $part{$_} }
    @_;
}

sub toplevel {
    my $doc = shift;
    my $from = 0;
    my @block;
    my @children = $doc->children;

    while (@children) {
	my $i = shift @children;
	my $len = length $i->content;

	if ($i->significant) {
	    my($s, $e) = ($from, $from + $len);
	    if (my $next = $i->next_sibling) {
		$e += 1 if $next->content eq "\n";
	    }
	    if ((my $column = $i->column_number) > 1) {
		$s -= $column - 1;
	    }
	    push @block, [ $s, $e ];
	}

	$from += $len;
    }
    @block;
}

sub statement {
    my $doc = shift;
    my $from = 0;
    my @block;
    my @children = $doc->children;

    if ($doc->class eq 'PPI::Statement::Sub') {
	##
	## collect tokens
	##
	my $top = $children[0];
	if ($top and $top->isa('PPI::Token')) {
	    my $len = 0;
	    while (@children and $children[0]->isa('PPI::Token')) {
		my $token = shift @children;
		$len += length $token->content;
	    }
	    my $s = 0 - ($top->column_number - 1);
	    my $e = $len;
	    $e++ if @children and $children[0]->isa('PPI::Structure');
	    push @block, [ $s, $e ];
	    $from = $len;
	}
    }

    while (@children) {
	my $i = shift @children;
	my $len = length $i->content;

	if ($i->class eq 'PPI::Statement::Sub') {
	    push @block, offset($from, statement($i));
	}
	elsif ($i->class eq 'PPI::Structure::Block') {
	    push @block, offset($from + 1, statement($i));
	}
	elsif ($i->significant) {
	    my($s, $e) = ($from, $from + $len);
	    if (my $next = $i->next_sibling) {
		$e += 1 if $next->content eq "\n";
	    }
	    if ((my $column = $i->column_number) > 1) {
		$s -= $column - 1;
	    }
	    push @block, [ $s, $e ];
	}

	$from += $len;
    }
    @block;
}

sub offset {
    my $offset = shift;
    map {
	[ $_->[0] + $offset, $_->[1] + $offset ]
    } @_;
}

use Term::ANSIColor qw(:constants);

my $color_re = qr{ \e \[ [\d;]* m }x;
my $sp = '  ';
my $sp_re = qr/$sp/;

sub colordump {
    my @esc;
    while (<>) {
	s/^ (?<space> $sp_re*) (?<esc> $color_re*)//x or do { print; next } ;
	my $esc = $+{esc};
	my @space = $+{space} =~ /($sp_re)/g;
	splice @esc, +@space;
	$esc[@space] = $esc . $sp . RESET if $esc;
	print map { $esc[$_] || $space[$_] } 0 .. $#space;
	print $esc, $_;
    }
}

my $reset = RESET;
my $mark = "\001";

sub colordump_regex {
    local $_ = do { local $/; <STDIN> } ;
    my($n, $m);
    $n++ while s{
	^
	(?<top> (?<in> $sp_re*) (?<esc> $color_re) .* \n )
	(?<child>
		(?:	\k<in> $sp_re
			(?:
				\s* [^\e\s]+ (?: $ | \s .* )
				|
				\s* $mark .*
			)
			\n
		)*
	)
	(?! \k<in> $sp_re )
    }{
	$m++;
	my($top, $child, $in, $esc) = @+{qw(top child in esc)};
	$top   =~ s/^$in\K/${mark}/;
	$child =~ s/^$in\K($sp_re)/${mark}${esc}${1}${reset}/mg;
	$top . $child;
    }mgex;
    warn "colordump: repeat ($n, $m) times\n" if $debug;
    s/$mark//g;
    print;
}

1;

__DATA__

option	default --if=expand

option	--top --block &part(top)		// print top level object
option	--state --block &part(statement)	// decend to subroutine

option	--dump --begin ppi_opt(dump)		// replace with dumped text
option	--cdump --dump \
	--of &colordump --no-line-number --uc --color=always \
	// color version

option	--dumper --dump --re (?=never)(?=match) --need 0 --all \
						// dump all
option	--cdumper --cdump \
	--dump --re '^ *\KPPI::\S+' --need 0 --all \
	// color version

option	--prune      --begin ppi_prune($<shift>)	// prune class
option	--nopod      --prune PPI::Token::Pod
option	--nospace    --prune PPI::Token::Whitespace
option	--nocomment  --prune PPI::Token::Comment
option	--nodata     --prune PPI::Statement::Data
option	--sig        --nopod --nospace --nocomment --nodata \
	// dump only siginificant part
