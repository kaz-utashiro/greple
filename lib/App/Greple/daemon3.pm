=head1 NAME

daemon3 - Module for translation of the book "The Design and Implementation of the FreeBSD Operating System"

=head1 SYNOPSIS

greple -Mdaemon3 [ options ]

    --by <part>  makes <part> as a data record
    --in <part>  search from <part> section
		 
    --jp         print Japanese chunk
    --eg         print English chunk
    --egjp       print Japanese/English chunk
    --comment    print comment block
    --injp       search from Japanese text
    --ineg       search from English text
    --inej       search from English/Japanese text
    --retrieve   retrieve given part in plain text
    --colorcode  show each part in color-coded

=head1 DESCRIPTION

Text is devided into forllowing parts.

    e        English  text
    j        Japanese text
    eg       English  text and comment
    jp       Japanese text and comment
    macro    Common roff macro
    retain   Retained original text
    comment  Comment block
    com1     Level 1 comment
    com2     Level 2 comment
    com3     Level 3 comment
    mark     .EG, .JP, .EJ mark lines
    gap      empty line between English and Japanese

So [ macro ] + [ e ] recovers original text, and [ macro ] + [ j ]
produces Japanese version of book text.  You can do it by next
command.

    $ greple -Mdaemon3 --retrieve macro,e

    $ greple -Mdaemon3 --retrieve macro,j


=head1 OPTION

=over 7

=item B<--by> I<part>

Makes I<part> as a unit of output.  Multiple part can be given
connected by commma.

=item B<--in> I<part>

Search pattern only from specified I<part>.

=item B<--roffsafe>

Exclude pattern included in roff comment and index.

=item B<--retrieve> I<part>

Retrieve specified part as a plain text.

Special word I<all> means I<macro>, I<mark>, I<e>, I<j>, I<comment>,
I<retain>, I<gap>.  Next command produces original text.

    greple -Mdaemon3 --retrieve all

If the I<part> start with minus ('-') character, it is removed from
specification.  Without positive specification, I<all> is assumed. So
next command print all lines other than I<retain> part.

    greple -Mdaemon3 --retrieve -retain

=item B<--colorcode>

Produce color-coded result.

=back


=head1 EXAMPLE

Produce original text.

    $ greple -Mdaemon3 --retrieve macro,e

Search sequence of "system call" in Japanese text and print I<egjp>
part including them.  Note that this print lines even if "system" and
"call" is devided by newline.

    $ greple -Mdaemon3 -e "system call" --by egjp --in j

Seach English text block which include all of "socket", "system",
"call", "error" and print I<egjp> block including them.

    $ greple -Mdaemo3 "socket system call error" --by egjp --in e

Look the file conents each part colored in different color.

    $ greple -Mdaemon3 --colorcode

Look the colored contents with all other staff

    $ greple -Mdaemon3 --colorcode --all

Compare produced result to original file.

    $ diff -U-1 <(lv file) <(greple -Mdaemon3 --retrieve macro,j) | sdif

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

Sentence-by-sentence Translation

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

Block start with ※ (kome-mark) character is comment block.

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
use Data::Dumper;
use List::Util qw(min max);

use App::Greple::Common;

use Exporter 'import';
our @EXPORT      = qw(&part);
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

END { }

{
    package LabeledRegionList;

    sub new {
	my $class = shift;
	my $obj = bless { }, $class;
	$obj->create(@_) if @_;
	$obj;
    }
    sub create {
	my $obj = shift;
	map { $obj->{$_} = [] } @_;
    }
    sub getRef {
	my($obj, $tag) = @_;
	$obj->{$tag};
    }
    sub getList {
	my($obj, $tag) = @_;
	@{$obj->getRef($tag)};
    }
    sub getSortedList {
	my $obj = shift;
	do {
	    sort { $a->[0] <=> $b->[0] }
	    map  { $obj->getList($_) }
	    @_;
	};
    }
    sub enhance ($$$) {
	my($obj, $tag, $ent) = @_;
	my $ref = $obj->getRef($tag);
	if (@$ref == 0) {
	    push @$ref, $ent;
	} else {
	    $ref->[-1] = [ $ref->[-1][0], $ent->[1] ];
	}
    }
    sub push {
	my $obj = shift;
	my $tag = shift;
	my $list = $obj->getRef($tag) or die "$tag: invalid name\n";
	CORE::push @$list, @_;
    }
    sub clean {
	my $obj = shift;
	for my $key (keys %$obj) {
	    @{$obj->{$key}} = ();
	}
    }
    sub tags {
	keys %{+shift};
    }
}

my $target = -1;
    
my $region =
    new LabeledRegionList
    qw(macro mark e j egjp eg jp retain comment com1 com2 com3 gap);

my @all = qw(macro mark e j comment retain gap);

sub part {
    my %arg = @_;
    my $file = delete $arg{&FILELABEL} or die;

    if ($target != \$_) {
	$region->clean;
	&setdata($region);
	$target = \$_;
    }

    if (exists $arg{all}) {
	my $val = delete $arg{all};
	map { $arg{$_} = $val } @all;
    }

    my @posi = grep $arg{$_}, grep /^\w+$/, keys %arg;
    my @nega = map { s/^-//; $_ } grep /^-/, keys %arg;

    my @part = do {
	if (@nega) {
	    my %nega = map { ($_, 1) } @nega;
	    grep { not $nega{$_} } @posi ? @posi : @all;
	} else {
	    @posi;
	}
    };

    $region->getSortedList(@part);
}

sub setdata {
    my $region = shift;
    my $pos = 0;

    while (m{	\G
		(?<macro>    (?s:.*?) )
		(?<start_eg> ^\.EG.*\n) (?<eg> (?s:.*?\n))
		(?<start_jp> ^\.JP.*\n) (?<jp> (?s:.*?\n))
		(?<end>      ^\.EJ.*    (?:\n|\z))
	}mgx) {

	$pos = pos();

	$region->push("macro", [ $-[1], $+[1] ]) if $-[1] != $+[1];
	$region->push("mark",
		      [ $-[2], $+[2] ], [ $-[4], $+[4] ], [ $-[6], $+[6] ]);
	my $eg = [ $-[3], $+[3] ];
	my $jp = [ $-[5], $+[5] ];
	my $trans = $+{jp};

	if ($trans !~ /\n\n/) {
	    $region->push("egjp", [ $eg->[0], $jp->[1] ]);
	    $region->push("e", $eg);
	    $region->push("j", $jp);
	    $region->push("eg", $eg);
	    $region->push("jp", $jp);
	    next;
	}

	$region->push("retain", $eg);

	my($s, $e) = @$jp;
	my $i = 0;
	my $lang = sub { qw(e j)[$i] };
	my $part = sub { qw(eg jp)[$i] };
	my $toggle = sub { $i ^= 1 };
	while ($trans =~ /^((?<kome>(?>※*)).*?\n)(\n+|\z)/smg) {
	    my $ent = [ $s + $-[1], $s + $+[1] ];
	    my $gap = [ $s + $-[3], $s + $+[3] ];
	    $region->push("gap", $gap) if $gap->[0] != $gap->[1];
	    if ($+{kome}) {
		my $level = min(length $+{kome}, 3);
		&$toggle;
		$region->push("comment", $ent);
		$region->push("com".$level, $ent);
		$region->enhance(&$part, $ent);
		$region->enhance("egjp", $ent);
	    } else {
		$region->push(&$lang, $ent);
		$region->push(&$part, $ent);
		if (&$lang eq 'e') {
		    $region->push("egjp", $ent);
		} else {
		    $region->enhance("egjp", $ent);
		}
	    }
	    &$toggle;
	}
    }

    if ($pos > 0 and $pos != length) {
	$region->push("macro", [ $pos, length ]);
    }
}

1;

__DATA__

option default --icode=guess

define &part &App::Greple::daemon3::part

define :comment: ^※.*\n(?:(?!\.(?:EG|JP|EJ)).+\n)*
option --nocomment --exclude :comment:

define :roffcomment: ^\.\\\".*
define :roffindex:   ^\.(IX|CO).*
option --roffsafe --exclude :roffcomment: --exclude :roffindex:

option --part     &part($<shift>)
option --by       --block  &part($<shift>)
option --in       --inside &part($<shift>)

option --jp       --by jp
option --eg       --by eg
option --egjp     --by egjp
option --comment  --by comment

option --injp      --in j --roffsafe --nocomment
option --ineg      --in e --roffsafe --nocomment
option --inej      --in e,j --roffsafe --nocomment

option --retrieve   -h --nocolor --le &part($<shift>)

option --colorcode  --need 1 --regioncolor \
		    --le &part(comment) --cm R \
		    --le &part(macro)   --cm C \
		    --le &part(e)       --cm B \
		    --le &part(j)       --cm K \
		    --le &part(retain)  --cm W \
		    --le &part(mark)    --cm Y \
		    --le &part(gap)     --cm X

help --jp           print Japanese chunk
help --eg           print English chunk
help --egjp         print Japanese/English chunk
help --comment      print comment block

help --injp         serach Japanese text
help --ineg         serach English text
help --inej         serach English/Japanese text

help --retrieve     retrieve given part in plain text
help --colorcode    show each part in color-coded
