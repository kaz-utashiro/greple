package App::Greple::colors;

=head1 NAME

colors - Greple module for various colormap

=head1 SYNOPSIS

greple -Mcolors --light ...

greple -Mcolors --dark ...

greple -Mcolors --solarized ...

=head1 DESCRIPTION

This module provides predefined color schemes for different terminal
backgrounds and preferences.  Colors are specified using
L<Term::ANSIColor::Concise> format.

=head2 COLOR FORMAT

=over 4

=item B<RGB format> (e.g., C<K/544>, C<555/100>)

3-digit RGB values (0-5 each) for 216-color palette.  Format is
C<foreground/background>.  C<K> means black, C<W> means white.

=item B<Hex format> (e.g., C<#002b36>, C<080808>)

6-digit hexadecimal RGB values for 24-bit true color.

=item B<Grey levels> (e.g., C<L01> - C<L24>)

24-level greyscale from dark (L01) to light (L24).

=back

=head1 OPTIONS

=over 4

=item B<--light>

Color scheme for light background terminals.  Uses dark foreground
colors on lighter backgrounds.

=item B<--dark>

Color scheme for dark background terminals.  Uses light foreground
colors on darker backgrounds.

=item B<--bright>

Alias for B<--light>.

=item B<--grey24>

=item B<--grey24-bg>

24-level greyscale colors.  B<--grey24> uses grey foreground colors,
B<--grey24-bg> uses grey background with contrasting foreground.

=item B<--greyhex>

=item B<--greyhex-bg>

24-level greyscale using hex color codes for true color terminals.

=item B<--solarized>

=item B<--solarized-fg>

=item B<--solarized-bg>

Ethan Schoonover's Solarized color palette.  B<--solarized> is an
alias for B<--solarized-fg>.  B<--solarized-bg> uses Solarized colors
as background.

=back

=head1 SEE ALSO

L<App::Greple>, L<Term::ANSIColor::Concise>

=head2 Color Adjustment

L<Term::ANSIColor::Concise> provides color adjustment modifiers that
can be appended to any color specification.  This allows you to
customize colors without modifying this module.

Modifier format: C<[+-=*][parameter][value]>

    l - Lightness (0-100)      <red>+l20 (lighter red)
    y - Luminance (0-100)      <blue>-y10 (darker blue)
    s - Saturation (0-100)     <green>=s50 (less saturated)
    h - Hue shift (degrees)    <red>+h30 (shift toward orange)
    c - Complement             <red>c (cyan)
    i - RGB Inverse            <blue>i (yellow)
    g - Grayscale              <red>g

Example:

    greple --cm '<red>+l20,<blue>-s10,<green>+h15'

See L<Term::ANSIColor::Concise> for complete documentation.

=head2 Solarized

Solarized is a sixteen color palette designed by Ethan Schoonover for
use with terminal and GUI applications.

=over 4

=item L<https://ethanschoonover.com/solarized/>

Official Solarized homepage.

=item L<https://github.com/altercation/solarized>

Solarized repository with color values and ports for various applications.

=back

=cut

use v5.24;
use warnings;

1;

__DATA__

option	--light \
	--cm K/544,K/454,K/445 \
	--cm K/455,K/545,K/554 \
	--cm K/543,K/453,K/435 \
	--cm K/534,K/354,K/345 \
	--cm K/444 \
	--cm K/433,K/343,K/334 \
	--cm K/344,K/434,K/443 \
	--cm K/333

option	--dark \
	--cm 555/100,555/010,555/001 \
	--cm 555/011,555/101,555/110 \
	--cm 555/021,555/201,555/210 \
	--cm 555/012,555/102,555/120 \
	--cm 555/111 \
	--cm 555/211,555/121,555/112 \
	--cm 555/122,555/212,555/221 \
	--cm 555/222

option	--bright --light

option  --greyhex12 \
	--cm #000,#111,#222,#333,#444,#555,#666,#777,#888,#AAA,#BBB,#CCC,#DDD,#EEE,#FFF

option	--greyhex \
	--cm 080808,121212,1c1c1c,262626,303030,3a3a3a,444444,4e4e4e \
	--cm 585858,626262,6c6c6c,767676,808080,8a8a8a,949494,9e9e9e \
	--cm a8a8a8,b2b2b2,bcbcbc,c6c6c6,d0d0d0,dadada,e4e4e4,eeeeee

option	--greyhex-bg \
	--cm ffffff/080808,ffffff/121212,ffffff/1c1c1c,ffffff/262626 \
	--cm ffffff/303030,ffffff/3a3a3a,ffffff/444444,ffffff/4e4e4e \
	--cm ffffff/585858,ffffff/626262,ffffff/6c6c6c,ffffff/767676 \
	--cm ffffff/808080,ffffff/8a8a8a,ffffff/949494,ffffff/9e9e9e \
	--cm 000000/a8a8a8,000000/b2b2b2,000000/bcbcbc,000000/c6c6c6 \
	--cm 000000/d0d0d0,000000/dadada,000000/e4e4e4,000000/eeeeee

option	--grey24 \
	--cm L01,L02,L03,L04,L05,L06,L07,L08,L09,L10,L11,L12 \
	--cm L13,L14,L15,L16,L17,L18,L19,L20,L21,L22,L23,L24

option	--grey24-bg \
	--cm w/L01,w/L02,w/L03,w/L04 \
	--cm w/L05,w/L06,w/L07,w/L08 \
	--cm w/L09,w/L10,w/L11,w/L12 \
	--cm w/L13,w/L14,w/L15,w/L16 \
	--cm K/L17,K/L18,K/L19,K/L20 \
	--cm K/L21,K/L22,K/L23,K/L24

option	--pastel \
	--cm w/123,w/231,w/312 \
	--cm w/321,w/231,w/312

option	--dark-pastel \
	--cm w/012,w/120,w/201 \
	--cm w/210,w/120,w/201

######################################################################
# Solarized
######################################################################

define {base03}  #002b36
define {base02}  #073642
define {base01}  #586e75
define {base00}  #657b83
define {base0}   #839496
define {base1}   #93a1a1
define {base2}   #eee8d5
define {base3}   #fdf6e3
define {yellow}  #b58900
define {orange}  #cb4b16
define {red}     #dc322f
define {magenta} #d33682
define {violet}  #6c71c4
define {blue}    #268bd2
define {cyan}    #2aa198
define {green}   #859900

option --solarized --solarized-fg

option	--solarized-fg \
	--cm {yellow}  \
	--cm {orange}  \
	--cm {red}     \
	--cm {magenta} \
	--cm {violet}  \
	--cm {blue}    \
	--cm {cyan}    \
	--cm {green}

option	--solarized-bg \
	--cm L25/{yellow}  \
	--cm L25/{orange}  \
	--cm L25/{red}     \
	--cm L25/{magenta} \
	--cm L25/{violet}  \
	--cm L25/{blue}    \
	--cm L25/{cyan}    \
	--cm L25/{green}

option --solarized-base03 --face +/{base03}
option --solarized-base02 --face +/{base02}
option --solarized-base01 --face +/{base01}
option --solarized-base00 --face +/{base00}

option --solarized-base0 --face +/{base0}
option --solarized-base1 --face +/{base1}
option --solarized-base2 --face +/{base2}
option --solarized-base3 --face +/{base3}

option --solarized-face03 --face +{base03}
option --solarized-face02 --face +{base02}
option --solarized-face01 --face +{base01}
option --solarized-face00 --face +{base00}

option --solarized-face0 --face +{base0}
option --solarized-face1 --face +{base1}
option --solarized-face2 --face +{base2}
option --solarized-face3 --face +{base3}
