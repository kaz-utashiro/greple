package App::Greple::colors;

=head1 NAME

colors - Greple module for various colormap

=head1 SYNOPSIS

greple -Mcolors

=head1 OPTIONS

=over 4

=item B<--light>

For light terminal.  Same as a default.

=item B<--dark>

For dark terminal.

=item B<--grey24>

=item B<--grey24-bg>

24 level grey scales.

=item B<--solarized>

=item B<--solarized-fg>

=item B<--solarized-bg>

Solarized colors.  B<--solarized> is same as B<--solarized-fg>.

=item B<--git-color-blame>

Colorize L<git-blame(1)> command output.

=back

=head1 SEE ALSO

L<https://github.com/altercation/solarized>

=cut

use v5.14;
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

######################################################################
# GIT
######################################################################

option --git-color-blame \
	--re '^[0-9a-f^][0-9a-f]{7,39}\b.+' \
	--uniqcolor --uniqsub 'sub{s/\s.*//r}' \
	--all --face +E-D
