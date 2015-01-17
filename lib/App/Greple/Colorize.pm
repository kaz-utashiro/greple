=head1 NAME

App::Greple::Colorize


=head1 SYNOPSIS

use App::Greple::Colorize qw(colorize);

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

and corresponding lowercase background color :

    r, g, b, c, m, y, k, w

or RGB value if using ANSI 256 color terminal :

    FORMAT:
        foreground[/background]

    COLOR:
        000 .. 555       : 6 x 6 x 6 216 colors
        000000 .. FFFFFF : 24bit RGB mapped to 216 colors
	L00 .. L23       : 24 grey levels

    Sample:
        005     0000FF        : blue foreground
           /505       /FF00FF : magenta background
        000/555 000000/FFFFFF : black on white
        500/050 FF0000/00FF00 : red on green

and other effects :

    S  Standout (reverse video)
    U  Underline
    D  Double-struck (boldface)
    F  Flash (blink)

When RGB values are all same in the hex 24bit spec, it is converted 24
grey levels.

=cut

package App::Greple::Colorize;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(colorize);

use Carp;
use List::Util qw(first);
use Term::ANSIColor qw(:constants);

use constant { FG => 'fg', BG => 'bg' } ;

sub colorseq {
    my $spec = shift // '';

    my($start, $end) = ('', '');
    if ($spec =~ /:/) {
	($start, $end) = split(/:/, $spec, 2);
    } else {
	map {
	    while (s{(?<bg>   /? ) \K			# /
		     (?<spec> [0-9a-f]{6}		# 24bit hex
			    | [0-5][0-5][0-5]		# 216 (6x6x6) colors
			    | L[01][0-9] | L[2][0-3]	# 24 grey levels
		     )
		   }{}xi) {
		$start .= ansi256($+{spec}, $+{bg} ? BG : FG);
	    }
	    $start .= UNDERLINE if /U/;
	    $start .= REVERSE   if /S/;
	    $start .= BOLD      if /D/;
	    $start .= BLINK     if /F/;
	    $start .= RED       if /R/; $start .= ON_RED       if /r/;
	    $start .= GREEN     if /G/; $start .= ON_GREEN     if /g/;
	    $start .= BLUE      if /B/; $start .= ON_BLUE      if /b/;
	    $start .= CYAN      if /C/; $start .= ON_CYAN      if /c/;
	    $start .= MAGENTA   if /M/; $start .= ON_MAGENTA   if /m/;
	    $start .= YELLOW    if /Y/; $start .= ON_YELLOW    if /y/;
	    $start .= BLACK     if /K/; $start .= ON_BLACK     if /k/;
	    $start .= WHITE     if /W/; $start .= ON_WHITE     if /w/;
	} $spec if $spec;
	$end = RESET if $start;
	$start =~ s/m\e\[/;/g;
    }
    ($start, $end);
}

my @grey24 = ( 0x08, 0x12, 0x1c, 0x26, 0x30, 0x3a, 0x44, 0x4e,
	       0x58, 0x62, 0x6c, 0x76, 0x80, 0x8a, 0x94, 0x9e,
	       0xa8, 0xb2, 0xbc, 0xc6, 0xd0, 0xda, 0xe4, 0xee );

sub ansi256 {
    my($code, $xg) = @_;
    my($r, $g, $b, $grey);
    if ($code =~ /^([0-5])([0-5])([0-5])$/) {
	($r, $g, $b) = ($1, $2, $3);
    }
    elsif ($code =~ /^L(\d+)/i) {
	$1 > 23 and croak "Color format error [$code]";
	$grey = 0 + $1;
    }
    elsif ($code =~ /^([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i) {
	my($rx, $gx, $bx) = (hex($1), hex($2), hex($3));
	if ($rx != 0 and $rx != 0xff and $rx == $gx and $rx == $bx) {
	    $grey = first { $rx >= $grey24[$_] } reverse 0 .. $#grey24;
	} else {
	    $r = int(5 * $rx / 255);
	    $g = int(5 * $gx / 255);
	    $b = int(5 * $bx / 255);
	}
    }
    else {
	croak "Color format error [$code]";
    }
    sprintf("\e[%d;%d;%dm",
	    $xg eq BG ? 48 : 38,
	    5,
	    defined $grey ? ($grey + 232) : ($r*36 + $g*6 + $b + 16)
	);
}

my %colorcache;
my $reset_re;
BEGIN {
    my $reset = RESET;
    $reset_re = qr/\Q$reset/;
}

sub colorize {
    my @result;
    while (@_ >= 2) {
	my($color, $text) = splice @_, 0, 2;
	$colorcache{$color} //= [ colorseq($color) ];
	my($s, $e) = @{$colorcache{$color}};
	$text =~ s/(^|$reset_re)([^\e\r\n]+)/${1}${s}${2}${e}/mg
	    if $s ne "";
	push @result, $text;
    }
    croak "Wrong number of parameters" if @_;
    join '', @result;
}

1;
