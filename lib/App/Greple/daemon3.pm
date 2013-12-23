=head1 NAME

daemon3 - Module for translation of the book "The Design and Implementation of the FreeBSD Operating System"

=head1 SYNOPSIS

greple -Mdaemon3 [ options ]

    --clean        cleanup roff comment and index macro
    --jp           search from japanese/macro part
    --jponly       search from japanese text part
    --jpblock      japanese part as blocks
    --jptext       search from japanese text without roff macros
    --eg           search from english/macro part
    --egonly       search from english text part
    --egblock      english part as blocks
    --egtext       search from english text without roff macros
    --comment      search from comment part
    --nocomment    search excluding comment part
    --commentblock comment part as blocks

=head1 TEXT FORMAT

=head2 Pattern 1

Simple Translation

    .\" Copyright 2004 M. K. McKusick
    .Dt $Date: 2013/12/23 09:04:26 $
    .Vs $Revision: 1.3 $
    .EG \"---------------------------------------- ENGLISH
    .H 2 "\*(Fb Facilities and the Kernel"
    .JP \"---------------------------------------- JAPANESE
    .H 2 "\*(Fb の機能とカーネルの役割"
    .EJ \"---------------------------------------- END

=head2 Pattern 2

Site-by-side Translation

    .PP
    .EG \"---------------------------------------- ENGLISH
    The \*(Fb kernel provides four basic facilities:
    processes,
    a filesystem,
    communications, and
    system startup.
    This section outlines where each of these four basic services
    is described in this book.
    .JP \"---------------------------------------- JAPANESE
    The \*(Fb kernel provides four basic facilities:
    processes,
    a filesystem,
    communications, and
    system startup.
    
    \*(Fb カーネルは、プロセス、ファイルシステム、通信、
    システムの起動という4つの基本サービスを提供する。
    
    This section outlines where each of these four basic services
    is described in this book.
    
    本節では、これら4つの基本サービスが本書の中のどこで扱われるかを解説する。
    .EJ \"---------------------------------------- END

=head2 COMMENT

Block start with ※ character is comment block.

    .JP \"---------------------------------------- JAPANESE
    The
    .GL kernel
    is the part of the system that runs in protected mode and mediates
    access by all user programs to the underlying hardware (e.g.,
    .Sm CPU ,
    keyboard, monitor, disks, network links)
    and software constructs
    (e.g., filesystem, network protocols).
    
    .GL カーネル
    は、システムの一部として特権モードで動作し、
    すべてのユーザプログラムがハードウェア (\c
    .Sm CPU 、
    モニタ、ディスク、ネットワーク接続等) や、ソフトウェア資源
    (ファイルシステム、ネットワークプロトコル等)
    にアクセスするための調停を行う。
    
    ※
    protected mode は、ここでしか使われていないため、
    protection mode と誤解されないために特権モードと訳すことにする。

=cut

package App::Greple::daemon3;

use utf8;
use strict;
use warnings;

use Carp;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&part);
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = qw();
}
our @EXPORT_OK;

END { }

my $target = -1;
my(@macro, @eg, @jp, @egjp);

sub part {
    my %arg = @_;

    if ($target != \$_) {
	&setdata;
	$target = \$_;
    }

    sort({ $a->[0] <=> $b->[0] }
	 $arg{macro} ? @macro : (),
	 $arg{egjp} ? @egjp : (),
	 $arg{eg} ? @eg : (),
	 $arg{jp} ? @jp : (),
	);
}

sub setdata {
    my $pos = 0;

    @macro = @eg = @jp = @egjp = ();

    while (m{	\G            (?<macro> (?s:.*?))
		^\.EG[^\n]*\n (?<eg>    .*?\n)
		^\.JP[^\n]*\n (?<jp>    .*?\n)
		^\.EJ[^\n]*   (?:\n|\Z)
	}msgx) {

	$pos = pos();
	push @macro, [ $-[1], $+[1] ];
	my $eg = [ $-[2], $+[2] ];
	my $jp = [ $-[3], $+[3] ];
	my $jptxt = $+{jp};

	if ($jptxt !~ /\n\n/) {
	    push @egjp, [ $eg->[0], $jp->[1] ];
	    push @eg, $eg;
	    push @jp, $jp;
	    next;
	}

	my($s, $e) = @$jp;
	my $i = 0;
	while ($jptxt =~ /^((?<firstchar>.).*?\n)(?:\n+|\Z)/smg) {
	    my($ss, $ee) = ($s + $-[1], $s + $+[1]);
	    if ($+{firstchar} eq '※' or $i++ % 2) {
		push @jp, [ $ss, $ee ];
		@egjp ? $egjp[-1][1] = $ee : push @egjp, [ $ss, $ee ];
	    } else {
		push @eg, [ $ss, $ee ];
		push @egjp, [ $ss, $ee ];
	    }
	}
    }

    if ($pos > 0 and $pos != length) {
	push @macro, [ $pos, length ];
    }
}

1;

__DATA__

define :comment: ^※.*\n(?:(?!\.(?:EG|JP|EJ)).+\n)*
define :roffcomment: ^\.\\\".*
define :roffindex:   ^\.(IX|CO).*

option default --icode=guess

option --clean --exclude :roffcomment: --exclude :roffindex:

option --jp --inside '&part(jp,macro)'
option --jponly --inside '&part(jp)'
option --jpblock --block '&part(jp)'
option --jptext --jponly --clean --nocomment

option --eg --inside '&part(eg,macro)'
option --egonly --inside '&part(eg)'
option --egblock --block '&part(eg)'
option --egtext --egonly --clean --nocomment

option --comment --inside :comment:
option --nocomment --exclude :comment:
option --commentblock --block :comment:

option --macro --inside '&part(macro)'
option --allblock --block '&part(macro,eg,jp)'

help --clean        cleanup roff comment and index macro
help --jp           search from japanese/macro part
help --jponly       search from japanese text part
help --jpblock      japanese part as blocks
help --jptext       search from japanese text without roff macros
help --eg           search from english/macro part
help --egonly       search from english text part
help --egblock      english part as blocks
help --egtext       search from english text without roff macros
help --comment      search from comment part
help --nocomment    search excluding comment part
help --commentblock comment part as blocks
