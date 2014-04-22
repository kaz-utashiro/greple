package App::Greple::diff;

use strict;
use warnings;

use Carp;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&print_wdiff);
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = qw();
}
our @EXPORT_OK;

END { }

use Data::Dumper;

sub print_wdiff {
    my %arg = @_;
    my @matched = @{$arg{matched}};

    for (my $i = $#matched; $i >= 0; $i--) {
	my($s, $e) = @{$matched[$i]};
	my $t = substr($_, $s, $e - $s);
	die if length $t < 4;
	substr($_, $s, $e - $s) = substr($t, 2, -2);
	$matched[$i][0] = $s - $i * 4;
	$matched[$i][1] = $e - $i * 4 - 4;
    }
    $_;
}

1;

=head1 NAME

diff - greple module for diff command output

=head1 SYNOPSIS

greple -Mdiff [ options ]

    --diffcolor    colorize diff output
    --udiffcolor   colorize diff -u output
    --wdiffcolor   colorize wdiff output
    --diffblock    blocknize diff section

    :diffblock:    diff section pattern

=cut

__DATA__

##
## normal diff
##
define :ctrl_chng_n:  ^\d+(?:,\d+)?c\d+(?:,\d+)?\n
define :ctrl_apnd_n:  ^\d+a\d+(?:,\d+)?\n
define :ctrl_delt_n:  ^\d+(?:,\d+)?d\d+\n
define :ctrl_n:       ^\d+(?:,\d+)?[adc]\d+(?:,\d+)?\n
define :old_n:        (?:^<\ .*\n)+
define :new_n:        (?:^>\ .*\n)+
define :sep_n:        ^---\n
define :mark_old_n:   ^<\ 
define :mark_new_n:   ^>\ 
define :text_old_n:   (?<=^<\ ).*
define :text_new_n:   (?<=^>\ ).*
define :block_apnd_n: :ctrl_apnd_n::old_n:
define :block_chng_n: :ctrl_chng_n::old_n::sep_n::new_n:
define :block_delt_n: :ctrl_delt_n::new_n:
define :block_n:      :block_apnd_n:|:block_chng_n:|:block_delt_n:

##
## diff -c
##
define :ctrl_old_c:   ^\*\*\* .*
define :ctrl_c:       :ctrl_old_c:
define :old_c:        (?:^\-\ .*\n)+
define :new_c:        (?:^\+\ .*\n)+
define :alt_c:        (?:^\!\ .*\n)+
define :sep_c:        ^---.*\n
define :mark_old_c:   ^\-\ 
define :mark_new_c:   ^\+\ 
define :mark_alt_c:   ^\!\ 
define :text_old_c:   (?<=^\-\ ).*
define :text_new_c:   (?<=^\+\ ).*
define :text_alt_c:   (?<=^\!\ ).*
define :block_c:      ^\*\*\* .*\n(?:(?:[\+ \-\!] |--- ).*\n)+

define :ctrl:     :ctrl_n:|:ctrl_c:
define :old:      :old_n:|:old_c:
define :new:      :new_n:|:new_c:
define :sep:      :sep_n:|:sep_c:
define :mark_old: :mark_old_n:|:mark_old_c:
define :mark_new: :mark_new_n:|:mark_new_c:
define :mark_sep: :mark_sep_n:|:mark_sep_c:
define :mark_alt: :mark_alt_c:
define :text_old: :text_old_n:|:text_old_c:
define :text_new: :text_new_n:|:text_new_c:
define :text_sep: :text_sep_n:|:text_sep_c:
define :text_alt: :text_alt_c:

option  --diffcolor \
	--all --need 1 \
	--re :ctrl:                     --colormap "CS"   \
	--re :sep:                      --colormap "C"    \
	--re :mark_old: --re :text_old: --colormap "RS R" \
	--re :mark_new: --re :text_new: --colormap "GS G" \
	--re :mark_alt: --re :text_alt: --colormap "BS B"

define :ctrl_u:     ^\@\@.*
define :old_u:      (?:^\-.*\n)+
define :new_u:      (?:^\+.*\n)
define :mark_old_u: ^\-
define :mark_new_u: ^\+
define :text_old_u: (?<=^\-).*
define :text_new_u: (?<=^\+).*
define :block_u:    ^\@\@.*\n(?:[ \-\+].*\n)+

option  --udiffcolor \
	--all --need 1 \
	--re :ctrl_u:     --colormap C  \
	--re :mark_old_u: --colormap RS \
	--re :text_old_u: --colormap R  \
	--re :mark_new_u: --colormap GS \
	--re :text_new_u: --colormap G

define :block:      :block_n:|:block_c:|:block_u:
define :block_apnd: :block_apnd_n:|:block_apnd_c:
define :block_chng: :block_chng_n:|:block_chng_c:
define :block_delt: :block_delt_n:|:block_delt_c:

option --diffblock --block :block:
option :diffblock: :block:

help --diffcolor    colorize diff (and diff -c) output
help --udiffcolor   colorize diff -u output
help --wdiffcolor   colorize wdiff output
help --diffblock    blocknize diff section
help :diffblock:    diff section pattern

option --wdiffcolor \
	--all \
	--print print_wdiff --continue \
	--re '(?s)\[\-.*?\-\]' --colormap R \
	--re '(?s)\{\+.*?\+\}' --colormap G
