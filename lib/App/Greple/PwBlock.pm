package App::Greple::PwBlock;

use strict;
use warnings;
use utf8;

use List::Util qw(sum reduce);
use Data::Dumper;
use Getopt::EX::Colormap qw(colorize);

sub new {
    my $class = shift;
    my $obj = bless {
	orig   => "",
	masked => "",
	id     => {},
	pw     => {},
	matrix => {},
    }, $class;

    $obj->parse(shift) if @_;

    $obj;
}

sub id {
    my $obj = shift;
    my $label = shift;
    exists $obj->{id}{$label} ? $obj->{id}{$label} : undef;
}

sub pw {
    my $obj = shift;
    my $label = shift;
    exists $obj->{pw}{$label} ? $obj->{pw}{$label} : undef;
}

sub cell {
    my $obj = shift;
    my($col, $row) = @_;
    if (length $col > 1) {
	($col, $row) = split //, $col;
    }
    return undef if not defined $obj->{matrix}{$col};
    $obj->matrix->{$col}{$row};
}

sub any {
    my $obj = shift;
    my $label = shift;
    $obj->id($label) // $obj->pw($label) // $obj->cell(uc $label);
}

sub orig   { $_[0]->{orig}   }
sub masked { $_[0]->{masked} }
sub matrix { $_[0]->{matrix} }

our $parse_matrix = 1;
our $parse_id = 1;
our $parse_pw = 1;

sub parse {
    my $obj = shift;
    $obj->{orig} = $obj->{masked} = shift;
    $obj->parse_matrix if $parse_matrix;
    $obj->parse_pw if $parse_pw;
    $obj->parse_id if $parse_id;
    $obj;
}
    
sub make_pattern {
    my $opt = ref $_[0] eq 'HASH' ? shift : {};
    use English;
    local $LIST_SEPARATOR = '|';
    my @match = @_;
    my @except = qw(INPUT);
    push @except, @{$opt->{IGNORE}} if $opt->{IGNORE};
    qr{ ^\s*+ (?!@except) .*? (?:@match)\w*[:=]? [\ \t]* \K ( .* ) }mxi;
}

our @id_keys = (
    qw(ID ACCOUNT USER CODE NUMBER URL),
    qw(ユーザ アカウント コード 番号),
    );
our $id_chars = '[\w\.\-\@]';
our $id_color = 'K/455';
our $id_label_color = 'S;C/555';

sub parse_id {
    shift->parse_xx(
	hash => 'id',
	pattern => make_pattern(@id_keys),
	chars => $id_chars,
	start_label => '0',
	label_format => '[%s]',
	color => $id_color,
	label_color => $id_label_color,
	blackout => 0,
	);
}		   

our @pw_keys = (
    qw(PASS PIN),
    qw(パス 暗証),
    );
our $pw_chars = '\S';
our $pw_color = 'K/545';
our $pw_label_color = 'S;M/555';
our $pw_blackout = 1;

sub parse_pw {
    shift->parse_xx(
	hash => 'pw',
	pattern => make_pattern({IGNORE => [ 'URL' ]}, @pw_keys),
	chars => $pw_chars,
	start_label => 'a',
	label_format => '[%s]',
	color => $pw_color,
	label_color => $pw_label_color,
	blackout => $pw_blackout,
	);
}		   

sub parse_xx {
    my $obj = shift;
    my %opt = @_;
    my %hash;
    $obj->{$opt{hash}} = \%hash;

    my $label_id = $opt{start_label};
    my $chars = qr/$opt{chars}/;
    $obj->{masked} =~ s{ (?!.*\e) $opt{pattern} }{
	local $_ = $1;
	s{ (?| ()    (https?://[^\s{}|\\\^\[\]\`]+)	# URL
	     | ([(]) ([^)]+)(\))	# ( text )
	     | ()    ($chars+) )	#   text
	}{
	    my($pre, $match, $post) = ($1, $2, $3 // '');
	    $hash{$label_id} = $match;
	    my $label = sprintf $opt{label_format}, $label_id++;
	    if ($opt{blackout}) {
		if ($opt{blackout} > 1) {
		    $match = 'x' x $opt{blackout};
		} else {
		    my $char = $opt{blackout_char} // 'x';
		    $match =~ s/./$char/g;
		}
	    }
	    $label = colorize($opt{label_color}, $label) if $opt{label_color};
	    $match = colorize($opt{color}, $match) if $opt{color};
	    $pre . $label . $match . $post;
	}xge;
	$_;
    }igex;

    $obj;
}

sub parse_matrix {
    my $obj = shift;
    my @area = guess_matrix_area($obj->{masked});
    my %matrix;
    $obj->{matrix} = \%matrix;

    for my $area (@area) {
	my $start = $area->[0];
	my $len = $area->[1] - $start;
	my $matrix = substr($obj->{masked}, $start, $len);
	$matrix =~ s{ \b (?<index>\d) \W+ \K (?<chars>.*) $}{
	    my $index = $+{index};
	    my $chars = $+{chars};
	    my $col = 'A';
	    $chars =~ s{(\S+)}{
		my $cell = $1;
		$matrix{$col}{$index} = $cell;
		$col++;
		$cell =~ s/./x/g;
		colorize('D;R', $cell);
	    }ge;
	    $chars;
	}xmge;
	substr($obj->{masked}, $start, $len) = $matrix;
	last; # process 1st segment only
    }

    $obj;
}
    
sub guess_matrix_area {
    my $text   = shift;
    my @text   = $text =~ /(.*\n|.+\z)/g;
    my @length = map { length } @text;
    my @words  = map { [ /(\w+)/g ] } @text;
    my @one    = map { [ grep { length == 1 } @$_ ] } @words;
    my @two    = map { [ grep { length == 2 } @$_ ] } @words;
    my @more   = map { [ grep { length >= 3 } @$_ ] } @words;
    my $series = 5;

    map  { [ sum(@length[0 .. $_->[0]]) - $length[$->[0]],
	     sum(@length[0 .. $_->[1]]) ] }
    sort { $b->[1] - $b->[0] <=> $a->[1] - $a->[0] }
    grep { $_->[0] + $series - 1 <= $_->[1] }
    map  { defined $_ ? ref $_ ? @$_ : [$_, $_] : () }
    reduce {
	my $r = ref $a eq 'ARRAY' ? $a : [ [$a, $a] ];
	my $l = $r->[-1][1];
	if ($l + 1 == $b
	    and @{$one[$l]} == @{$one[$b]}
	    and @{$two[$l]} == @{$two[$b]}
	    ) {
	    $r->[-1][1] = $b;
	} else {
	    push @$r, [ $b, $b ];
	}
	$r;
    }
    grep { $one[$_][0] =~ /\d/ }
    grep { @{$one[$_]} >= 10 || @{$two[$_]} >= 5 and @{$more[$_]} == 0 }
    0 .. $#text;
}

1;
