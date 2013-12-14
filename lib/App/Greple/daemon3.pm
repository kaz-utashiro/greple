=head1 NAME

daemon3 - Module for translation of the book "The Design and Implementation of the FreeBSD Operating System"

=head1 SYNOPSIS

greple -Mdaemon3 [ options ]

    --jp            search from japanese part
    --jpblock       japanese part as blocks
    --comment       search from comment part
    --nocomment     search excluding comment part
    --commentblock  comment part as blocks

=head1 TEXT FORMAT

=head2 Pattern 1

Simple Translation

    .\" Copyright 2004 M. K. McKusick
    .Dt $Date: 2005/09/06 14:28:17 $
    .Vs $Revision: 1.5 $
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

    $VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&jp_part);
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = qw();
}
our @EXPORT_OK;

END { }

sub jp_part {
    my @result;
    my @block;
    while (m{	\G            (?<macro> .*?\n)
		^\.EG[^\n]*\n (?<eg>    .*?\n)
		^\.JP[^\n]*\n (?<jp>    .*?\n)
		^\.EJ[^\n]*\n
	}msgx) {
	push(@result, [ $-[1], $+[1] ]) if $1;
	push(@block, [ $-[3], $+[3] ]);
    }
    for my $block (@block) {
	my($s, $e) = @$block;
	my $txt = substr($_, $s, $e - $s);
	if ($txt !~ /\n\n/) {
	    push(@result, $block);
	    next;
	}
	my $i = 0;
	while ($txt =~ /^((?<firstchar>.).*?\n)(?:\n+|\Z)/smg) {
	    my($ss, $ee) = ($-[1], $+[1]);
	    if ($+{firstchar} eq '※' or $i++ % 2) {
		push(@result, [ $s + $ss, $s + $ee ]);
	    }
	}
    }
    sort { $a->[0] <=> $b->[0] } @result;
}

1;

__DATA__

define :comment: (?m)^※.*\n(?:(?!\.(?:EG|JP|EJ)).+\n)*
set option --icode=guess
option --jp --inside '&jp_part'
option --jpblock --block '&jp_part'
option --comment --inside :comment:
option --nocomment --outside :comment:
option --commentblock --block :comment:
