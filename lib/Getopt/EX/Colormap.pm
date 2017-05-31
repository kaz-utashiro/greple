package Getopt::EX::Colormap;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(colorize);
our @ISA         = qw(Getopt::EX::LabeledParam);

use Carp;
use Scalar::Util qw(blessed);
use Data::Dumper;

use Getopt::EX::LabeledParam;

our $COLOR_RGB24 = 0;

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
	my($rx, $gx, $bx) = map { hex } $1, $2, $3;
	if ($rx != 255 and $rx == $gx and $rx == $bx) {
	    ##
	    ## Divide area into 25 segments, and map to BLACK and 24 GREYS
	    ##
	    $grey = int ( $rx * 25 / 255 ) - 1;
	    if ($grey < 0) {
		$r = $g = $b = 0;
		$grey = undef;
	    }
	} else {
	    $r = int ( 5 * $rx / 255 );
	    $g = int ( 5 * $gx / 255 );
	    $b = int ( 5 * $bx / 255 );
	}
    }
    else {
	die "Color spec error: $code";
    }
    defined $grey ? ($grey + 232) : ($r*36 + $g*6 + $b + 16);
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
    F => 5,		# F : Flash (Blink: Slow)
    Q => 6,		# Q : Quick (Blink: Rapid)
    S => 7,		# S : Standout (Reverse)
    V => 8,		# V : Vanish (Concealed)
    J => 9,		# J : Junk (Crossed out)
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
	     | (?<sgi>  H\d[x\d]* )			# SGI params
	     | (?<h24>  [0-9a-f]{6} )			# 24bit hex
	     | (?<c256> [0-5][0-5][0-5]			# 216 (6x6x6) colors
		      | L(?:[01][0-9]|[2][0-3]) )	# 24 grey levels
	     | (?<c16>  [KRGYBMCW] )			# 16 colors
	     | (?<efct> [;XNZDPIUFQSVJ] )		# effects
	     | (?<err>  .+ )				# error
	     )
	    }xig) {
	if ($+{slash}) {
	    $BG++ and die "Color spec error: $_\n";
	}
	elsif (my $sgi = $+{sgi}) {
	    push @numbers, $sgi =~ /(\d+)/g;
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
	    die "Color spec error: \"$err\" in \"$_\".\n"
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
    my $obj = SUPER::new $class;

    $obj->{CACHE} = {};
    configure $obj @_ if @_;

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


__END__


=head1 NAME

Getopt::EX::Colormap - ANSI terminal color and option support


=head1 SYNOPSIS

  GetOptions('colormap|cm:s' => @opt_colormap);

  require Getopt::EX::Colormap;
  my $handler = new Getopt::EX::Colormap;
  $handler->load_params(@opt_colormap);  

  print handler->color('FILE', 'FILE labeled text');

  print handler->index_color($index, 'TEXT');

    or

  use Getopt::EX::Colormap qw(colorize);
  $text = colorize(SPEC, TEXT);
  $text = colorize(SPEC_1, TEXT_1, SPEC_2, TEXT_2, ...);


=head1 DESCRIPTION

Coloring text capability is not strongly bound to option processing,
but it may be useful to give simple uniform way to specify complicated
color setting from command line.

This module assumes the color information is given in two ways: one in
labeled table, and one in indexed list.

This is a example of labeled table:

    --cm 'COMMAND=SE,OMARK=CS,NMARK=MS' \
    --cm 'OTEXT=C,NTEXT=M,*CHANGE=BD/445,DELETE=APPEND=RD/544' \
    --cm 'CMARK=GS,MMARK=YS,CTEXT=G,MTEXT=Y'

Each color definitions are separated by comma (C<,>) and label is
specified by I<LABEL=> style precedence.  Multiple labels can be set
for same value by connecting them together.  Label name can be
specified with C<*> and C<?> wild characters.

List example is like this:

    --cm 555/100,555/010,555/001 \
    --cm 555/011,555/101,555/110 \
    --cm 555/021,555/201,555/210 \
    --cm 555/012,555/102,555/120

This is the example of RGB 6x6x6 bit 216 colors specification.  Left
side of slash is foreground color, and left side is for background.
This color list is accessed by index.

Handler maintains hash and list objects, and labeled colors are stored
in hash, non-label colors are in list automatically.  User can mix
both specifications.

Besides producing ANSI colored text, this module supports calling
arbitrary function to handle a string.  See L<FUNCTION SPEC> section
for more detail.


=head1 COLOR SPEC

Color specification is combination of single uppercase character
representing 8 colors :

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

or RGB values and 24 grey levels if using ANSI 256 or full color
terminal :

    000000 .. FFFFFF : 24bit RGB colors
    000 .. 555       : 6x6x6 RGB 216 colors
    L00 .. L23       : 24 grey levels

=over 4

Note that, when values are all same in 24bit RGB, it is converted to
24 grey level, otherwise 6x6x6 216 color.

=back

with other special effects :

    Z  0 Zero (reset)
    D  1 Double-struck (boldface)
    P  2 Pale (dark)
    I  3 Italic
    U  4 Underline
    F  5 Flash (blink: slow)
    Q  6 Quick (blink: rapid)
    S  7 Stand-out (reverse video)
    V  8 Vanish (concealed)
    J  9 Junk (crossed out)

    ;  No effect
    X  No effect

and arbitrary numbers beginning with "H", those are directly converted
into escape sequence.  Use "x" to indicate multiple numbers.  Remember
associated with Hollerith constants.

    H4      underline
    H1x3x7  bold / italic / stand-out

If the spec includes C</>, left side is considered as foreground color
and right side as background.  If multiple colors are given in same
spec, all indicators are produced in the order of their presence.
Consequently, the last one takes effect.

Effect characters are case insensitive, and can be found anywhere and
in any order in color spec string.  Because C<X> and C<;> takes no
effect, you can use them to improve readability, like C<SxD;K/544>.

Samples:

    RGB  6x6x6    24bit           color
    ===  =======  =============   ==================
    B    005      0000FF        : blue foreground
     /M     /505        /FF00FF : magenta background
    K/W  000/555  000000/FFFFFF : black on white
    R/G  500/050  FF0000/00FF00 : red on green
    W/w  L03/L20  303030/c6c6c6 : grey on grey

24-bit RGB color sequence is supported but disabled by default.  Set
C<$COLOR_RGB24> module variable to enable.


=head1 FUNCTION SPEC

It is also possible to set arbitrary function which is called to
handle string in place of color, and that is not necessarily concerned
with color.  This scheme is quite powerful and the module name itself
may be somewhat misleading.  Spec string which start with C<sub{> is
considered as a function definition.  So

    % example --cm 'sub{uc}'

set the function object in the color entry.  And when C<color> method
is called with that object, specified function is called instead of
producing ANSI color sequence.  Function is supposed to get the target
text as a global variable C<$_>, and return the result as a string.
Function C<sub{uc}> in the above example returns uppercase version of
C<$_>.

If your script prints file name according to the color spec labeled by
B<FILE>, then

    % example --cm FILE=R

prints the file name in red, but

    % example --cm FILE=sub{uc}

will print the name in uppercases.

Spec start with C<&> is considered as a function name.  If the
function C<double> is defined like:

    sub double { $_ . $_ }

then, command

    % example --cm '&double'

produces doubled text by C<color> method.  Function can also take
parameters, so the next example

    sub repeat {
	my %opt = @_;
	$_ x $opt{count} // 1;
    }

    % example --cm '&repeat(count=3)'

produces tripled text.

Function object is created by <Getopt::EX::Func> module.  Take a look
at the module for detail.


=head1 EXAMPLE CODE

    #!/usr/bin/perl
    
    use strict;
    use warnings;

    my @opt_colormap;
    use Getopt::EX::Long;
    GetOptions("colormap|cm=s" => \@opt_colormap);
    
    my %colormap = ( # default color map
        FILE => 'R',
        LINE => 'G',
        TEXT => 'B',
        );
    my @colors;
    
    require Getopt::EX::Colormap;
    my $handler = new Getopt::EX::Colormap
        HASH => \%colormap,
        LIST => \@colors;
    
    $handler->load_params(@opt_colormap);

    for (0 .. $#colors) {
        print $handler->index_color($_, "COLOR $_"), "\n";
    }
    
    for (sort keys %colormap) {
        print $handler->color($_, $_), "\n";
    }

This sample program is complete to work.  If you save this script as a
file F<example>, try to put following contents in F<~/.examplerc> and
see what happens.

    option default \
        --cm 555/100,555/010,555/001 \
        --cm 555/011,555/101,555/110 \
        --cm 555/021,555/201,555/210 \
        --cm 555/012,555/102,555/120


=head1 METHODS

=over 4

=item B<color> I<label>, TEXT

=item B<color> I<color_spec>, TEXT

Return colored text indicated by label or color spec string.

=item B<index_color> I<index>, TEXT

Return colored text indicated by I<index>.  If the index is bigger
than color list, it rounds up.

=item B<new>

=item B<append>

=item B<load_params>

See super class L<Getopt::EX::LabeledParam>.

=back


=head1 SEE ALSO

L<Getopt::EX>,
L<Getopt::EX::LabeledParam>
