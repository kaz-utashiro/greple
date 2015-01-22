=head1 NAME

Getopt::EX::Colormap;


=head1 SYNOPSIS

use Getopt::EX::Colormap qw(colorize);

$text = colorize(SPEC, TEXT);

$text = colorize(SPEC_1, TEXT_1, SPEC_2, TEXT_2, ...);


=head1 EXAMPLE

print colorize('R', "red", 'G', "green", 'B', "blue");


=head1 DESCRIPTION

SPEC is combination of single character representing uppercase
foreground color :

    R  Red
    G  Green
    B  Blue
    C  Cyan
    M  Magenta
    Y  Yellow
    K  Black
    W  White

and alternative (usually brighter) colors in lowercase:

    r, g, b, c, m, y, k, w

or RGB value if using ANSI 256 color terminal :

    FORMAT:
        foreground[/background]

    COLOR:
        000 .. 555       : 6 x 6 x 6 216 colors
        000000 .. FFFFFF : 24bit RGB mapped to 216 colors
	L00 .. L23       : 24 grey levels

    Sample:
	K/W                   : black on white
        005     0000FF        : blue foreground
           /505       /FF00FF : magenta background
        000/555 000000/FFFFFF : black on white
        500/050 FF0000/00FF00 : red on green

and other effects :

    X  No effect
    Z  Zero (reset)
    D  Double-struck (boldface)
    I  Italic
    S  Standout (reverse video)
    V  Vanish (concealed)
    U  Underline
    F  Flash (blink)

When RGB values are all same in the hex 24bit spec, it is converted 24
grey levels.

=cut

package Getopt::EX::Colormap;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(colorize);

use Carp;
use List::Util qw(first);
use Scalar::Util qw(blessed);
use Data::Dumper;

our $COLOR_RGB24 = 0;

my @grey24 = ( 0x08, 0x12, 0x1c, 0x26, 0x30, 0x3a, 0x44, 0x4e,
	       0x58, 0x62, 0x6c, 0x76, 0x80, 0x8a, 0x94, 0x9e,
	       0xa8, 0xb2, 0xbc, 0xc6, 0xd0, 0xda, 0xe4, 0xee );

sub rgb_to_grey {
    my $rgb = shift;
    first { $rgb >= $grey24[$_] } reverse 0 .. $#grey24;
}

sub ansi256_number {
    my $code = shift;
    my($r, $g, $b, $grey);
    if ($code =~ /^([0-5])([0-5])([0-5])$/) {
	($r, $g, $b) = ($1, $2, $3);
    }
    elsif ($code =~ /^L(\d+)/i) {
	$1 > 23 and die "Color spec error: $code";
	$grey = 0 + $1;
    }
    elsif ($code =~ /^([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i) {
	my($rx, $gx, $bx) = (hex($1), hex($2), hex($3));
	if ($rx != 0 and $rx != 0xff and $rx == $gx and $rx == $bx) {
	    $grey = rgb_to_grey $rx;
	} else {
	    $r = int ( 5 * $rx / 255 );
	    $g = int ( 5 * $gx / 255 );
	    $b = int ( 5 * $bx / 255 );
	}
    }
    else {
	die "Color spec error: $code";
    }
    defined $grey ? ($grey + 232) : ($r*36 + $g*6 + $b + 16)
}

my %numbers = (
    ';' => undef,	# ; : NOP
    X => undef,		# X : NOP
    N => undef,		# N : None (NOP)
    Z => 0,		# Z : Zero (Reset)
    D => 1,		# D : Double-Struck (Bold)
    P => 2,		# P : Pale (Dark)
    I => 3,		# I : Italic
    U => 4,		# U : Underline
    F => 5,		# F : Flash (Blink)
    S => 7,		# S : Standout (Reverse)
    V => 8,		# V : Vanish (Concealed)
    K => 30, k => 90,	# K : Kuro (Black)
    R => 31, r => 91,	# R : Red  
    G => 32, g => 92,	# G : Green
    Y => 33, y => 93,	# Y : Yellow
    B => 34, b => 94,	# B : Blue 
    M => 35, m => 95,	# M : Magenta
    C => 36, c => 96,	# C : Cyan 
    W => 37, w => 97,	# W : White
    );

sub ansi_numbers {
    local $_ = shift // '';
    my @numbers;
    my $BG = 0;
    while (m{\G
	     (?:
	       (?<slash> /)				# /
	     | (?<h24>  [0-9a-f]{6} )			# 24bit hex
	     | (?<c256> [0-5][0-5][0-5]			# 216 (6x6x6) colors
		      | L(?:[01][0-9]|[2][0-3]) )	# 24 grey levels
	     | (?<c16>  [KRGYBMCW] )			# 16 colors
	     | (?<efct> [;XNZDPIUFSV] )			# effects
	     | (?<err>  .+ )				# error
	     )
	    }xig) {
	if ($+{slash}) {
	    $BG++ and die "Color spec error: $_";
	}
	elsif (my $h24 = $+{h24}) {
	    if ($COLOR_RGB24) {
		push @numbers, ($BG ? 48 : 38), 2, do {
		    map { hex $_ }
		    $h24 =~ /^([\da-f]{2})([\da-f]{2})([\da-f]{2})/i
		};
	    } else {
		push @numbers, ($BG ? 48 : 38), 5, ansi256_number $h24;
	    }
	}
	elsif (my $c256 = $+{c256}) {
	    push @numbers, ($BG ? 48 : 38), 5, ansi256_number $c256;
	}
	elsif (my $c16 = $+{c16}) {
	    push @numbers, $numbers{$c16} + ($BG ? 10 : 0);
	}
	elsif (my $efct = $+{efct}) {
	    $efct = uc $efct;
	    push @numbers, $numbers{$efct} if defined $numbers{$efct};
	}
	elsif (my $err = $+{err}) {
	    die "Color spec error: \"$err\" in \"$_\""
	}
	else { die }
	
    }
    @numbers;
}

sub CSI {
    @_  ? "\e[" . ( join ';', @_ ) . 'm'
	: ''
}

sub ansi_indicator {
    my $spec = shift;
    my @numbers = ansi_numbers $spec;
    @numbers ? CSI @numbers : undef;
}

sub ansi_pair {
    my $spec = shift;
    my $start = ansi_indicator $spec;
    my $end = CSI 0 if $start;
    ($start // '', $end // '');
}

my %colorcache;
my $reset_re;
BEGIN {
    my $reset = CSI 0;
    $reset_re = qr/\Q$reset/;
}

sub colorize {
    cached_colorize(\%colorcache, @_);
}

sub cached_colorize {
    my $cache = shift;
    my @result;
    while (@_ >= 2) {
	my($spec, $text) = splice @_, 0, 2;
	for my $color (ref $spec eq 'ARRAY' ? @$spec : $spec) {
	    $text = apply_color($cache, $color, $text);
	}
	push @result, $text;
    }
    croak "Wrong number of parameters" if @_;
    join '', @result;
}

sub apply_color {
    my($cache, $color, $text) = @_;
    if (blessed $color and $color->can('call')) {
	return $color->call for $text;
    }
    else {
	$cache->{$color} //= [ ansi_pair($color) ];
	my($s, $e) = @{$cache->{$color}};
	$text =~ s/(^|$reset_re)([^\e\r\n]+)/${1}${s}${2}${e}/mg
	    if $s ne "";
	return $text;
    }
}

sub new {
    my $class = shift;
    my $obj = bless {
	HASH  => {},
	LIST  => [],
	CACHE => {},
    }, $class;

    configure $obj @_ if @_;

    $obj;
}

sub hash {
    my $obj = shift;
    $obj->{HASH};
}

sub list {
    my $obj = shift;
    @{ $obj->{LIST} };
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

sub configure {
    my $obj = shift;
    my %opt = @_;

    for my $key (qw(HASH LIST)) {
	if (my $val = delete $opt{$key}) {
	    $obj->{$key} = $val;
	}
    }
    warn "Unknown option: ", Dumper %opt if %opt;
}

sub load_option {
    my $obj = shift;

    require Getopt::EX::LabeledParam;
    my $cmap = new Getopt::EX::LabeledParam
	newlabel => 0,
	HASH => $obj->{HASH},
	LIST => $obj->{LIST},
	;
    $cmap->append(@_);
    $obj;
}

sub index_color {
    my $obj = shift;
    my $index = shift;
    my $text = shift;

    my $list = $obj->{LIST};
    if (@$list) {
	$text = $obj->color($list->[$index % @$list], $text, $index);
    }
    $text;
}

sub color {
    my $obj = shift;
    my $color = shift;
    my $text = shift;

    my $map = $obj->{HASH};
    my $c = exists $map->{$color} ? $map->{$color} : $color;

    return $text unless $c;

    cached_colorize($obj->{CACHE}, $c, $text);
}

1;
