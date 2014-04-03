=head1 NAME

bm - Greple module for bombay format

=head1 SYNOPSIS

greple -Mbm [ options ]

    --com      find all comments
    --com1     find comment level 1
    --com2     find comment level 2
    --com3     find comment level 3
    --com2+    find comment level 2 and 3
    --injp     match text in Japanese part
    --jp       search only Japanese block only
    --ineg     match text in English part
    --eg       search only English block only
    --both     search Japanese/English block
    --comment  search comment block

=head1 TEXT FORMAT

    Society’s increased dependency on networked software systems has been
    matched by an increase in the number of attacks aimed at these
    systems.

    社会がネットワーク化したソフトウェアシステムへの依存を深めるにつれ、こ
    れらのシステムを狙った攻撃の数は増加の一途を辿っています。

    ※ comment level 1

    ※※ comment level 2

    ※※※ comment level 3

=cut

package App::Greple::bm ;

use utf8 ;
use strict ;
use warnings ;

use Data::Dumper ;
use Carp ;

BEGIN {
    use Exporter   () ;
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS) ;

    $VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g ;

    @ISA         = qw(Exporter) ;
    @EXPORT      = qw(&part) ;
    %EXPORT_TAGS = ( ) ;
    @EXPORT_OK   = qw() ;
}
our @EXPORT_OK ;

END { }

my $target = -1 ;
my %part ;

my $wchar_re = qr{
    [\p{East_Asian_Width=Wide}\p{East_Asian_Width=FullWidth}]
}x;

sub part {
    my %arg = @_ ;

    if ($target != \$_) {
	setdata() ;
	$target = \$_ ;
    }

    my @part;
    push @part, @{$part{eg}} if $arg{eg};
    push @part, @{$part{jp}} if $arg{jp};
    push @part, @{$part{comment}} if $arg{comment};

    sort { $a->[0] <=> $b->[0] } @part;
}

sub setdata {

    %part = ( eg => [], jp => [], comment => [] ) ;

    my $lang = 'null' ;

    while (m{ \G ( (?:^.+\n)+ ) \n+ }mgx) {
	my $para = $1 ;
	my($from, $to) = ( $-[1], $+[1] ) ;

	next if $para =~ /\A-\*-/ ;

	if ($para =~ /\A※/) {
	    push @{$part{comment}}, [ $from, $to ] ;
	    $part{$lang}->[-1][1] = $to;
	    next;
	}
	$lang = $lang eq 'eg' ? 'jp' : 'eg' ;
	push @{$part{$lang}}, [ $from, $to ] ;

	if ($lang eq 'eg' and $para =~ /$wchar_re/) {
	    die "Unexpected wide char in english part:\n", $para;
	}
    }
}

1;

__DATA__

option --com  --nocolor -nH --re '^※+'
option --com1 --nocolor -nH --re '^※(?!※)'
option --com2 --nocolor -nH --re '^※※(?!※)'
option --com3 --nocolor -nH --re '^※※※'
option --com2+ --nocolor -nH --re '^※※'

option --injp --inside '&part(jp)'
option --jp --block '&part(jp)'

option --ineg --inside '&part(eg)'
option --eg --block '&part(eg)'

option --both --block '&part(eg,jp)'

option --comment --block '&part(comment)'

help --com      find all comments
help --com1     find comment level 1
help --com2     find comment level 2
help --com3     find comment level 3
help --com2+    find comment level 2 and more
help --injp     match text in Japanese part
help --jp       search only Japanese block only
help --ineg     match text in English part
help --eg       search only English block only
help --both     search Japanese/English block
help --comment  search comment block
