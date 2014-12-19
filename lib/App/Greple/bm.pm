=head1 NAME

bm - Greple module for bombay format

=head1 SYNOPSIS

greple -Mbm [ options ]

    default              --cache-auto
    --part               '&part($<shift>)'
    --cdedit             --chdir $ENV{SCCC2DIR}/Edit
    --ed1                --cdedit --glob '../SCCC1/*.bm1'
    --ed2                --cdedit --glob '*.bm1'
    --com                find all comments
    --com1               find comment level 1
    --com2               find comment level 2
    --com3               find comment level 3
    --com2+              find comment level 2 or <
    --injp               match in Japanese part
    --injptxt            match in Japanese text part
    --jp                 display Japanese block
    --jptxt              display Japanese text block
    --ineg               match in English part
    --inegtxt            match in English text part
    --eg                 display English block
    --egtxt              display English text block
    --both               display jp/eg combined block
    --table              search inside table  
    --figure             search inside figure 
    --example            search inside example
    --comment            display comment block
    --extable            exclude table       
    --exfigure           exclude figure 
    --exexample          exclude example
    --excomment          exclude comment
    --cache-auto         automatic cache update
    --cache-create       create cache
    --cache-clean        remove cache
    --cache-update       force to update cache
    --nocache            disable cache
    --join-block         join block into single line
    --oldcite            old style 2digit citation
    --newcite            new style 4digit citation


=head1 TEXT FORMAT

    Society’s increased dependency on networked software systems has been
    matched by an increase in the number of attacks aimed at these
    systems.

    社会がネットワーク化したソフトウェアシステムへの依存を深めるにつれ、こ
    れらのシステムを狙った攻撃の数は増加の一途を辿っています。

    ※ comment level 1

    ※※ comment level 2

    ※※※ comment level 3

=head1 CACHE

Module will read region cache file if it is available and newer than
target file.  Cache file for file F<FOO> is F<.FOO.greple.bm.json>.

Option B<--cache-auto> is set be default, and cache data is
automatically updated if necessary.

Cache data is not created automatically.  Use B<--cache-create> to
create cache file for the first time.  Use B<--cache-clean> to clean
up.

Option B<--cache-update> can be used to force update cache even if the
valid cache file exits.

=cut

package App::Greple::bm;

use utf8;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw(part bmcache join_block tag);
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Data::Dumper;
use Carp;
use File::stat;

use App::Greple::Common;

my $use_json = 0;
my $mod_json;
if ($use_json) {
    eval "use JSON";
    $mod_json = not $@;
} else {
    $mod_json = 0;
}

my $sane_json = do {
    my $dpair   = qr/\[\d+,\d+\]/;
    my $list    = qr/\[ (?: $dpair , )* $dpair ? \]/x;
    my $hashent = qr/"\w+" : $list/x;
    my $hash    = qr/\{ (?: $hashent , )* $hashent ? \}/x;
    qr/\A $hash \Z/x;
};

unless ($mod_json) {
    eval q{
	sub to_json {
	    my $obj = shift;
	    local $_ = Dumper $obj;
	    s/\s+//g;
	    s/'([a-zA-Z_]+)'/"$1"/g;
	    s/'(\d+)'/$1/g;
	    s/=>/:/g;
	    $_;
	}
	sub from_json {
	    local $_ = shift;
	    /$sane_json/ or die "json format error";
	    s/:/=>/g;
	    eval;
	}
    };
    die $@ if $@;
}

my $target = -1;
my %part;
my $use_cache = 1;

#
# [\p{East_Asian_Width=Wide}\p{East_Asian_Width=FullWidth}]
# 第一版中、英文の中に句読点や「・」が出てくることがある。
# 「う」に濁点がフォントによっては表示できない。
#
my $wchar_re = qr{
    [\p{Han}ぁ-んゔァ-ンヴ]
}x;

sub part {
    my %arg = @_;
    my $file = delete $arg{&FILELABEL} or die;

    if ($target != \$_) {
	setdata($file);
	$target = \$_;
    }

    regions(grep { $arg{$_} } keys %arg);
}

sub regions {
    sort { $a->[0] <=> $b->[0] }
    map  { @{ $part{$_} } }
    grep { $part{$_} }
    @_;
}

sub setdata {
    my $file = shift;
    my $nocache = @_ ? shift : 0;

  CACHECHECK:
    {
	last if $nocache;
	last unless $use_cache;
	last unless cache_valid($file);
	my $obj = get_json(cachename($file)) or last;
	if ($obj->{all} and $obj->{all}[0][1] != length) {
	    warn "File length mismatch, cache disabled.\n";
	    last;
	}
	%part = %{ $obj };
	return;
    }

    %part = ( egtxt => [], jptxt => [],
	      eg => [], jp => [],
	      both => [],
	      comment => [],
	      all => [ [ 0, length ] ],
	) ;

    my $lang = 'null';

    ##
    ## comment, eg, jp, both
    ##
    while (m{ ^ ( (?:.+\n)+ (?:.*\z)? )  }mgx) {
#	my($from, $to) = ( $-[1], $+[1] );
	my $to = pos();
	my $from = $to - length $1;
	my $para = $1;

	next if $para =~ /\A-\*-/;

	if ($para =~ /\A※/) {
	    push @{$part{comment}}, [ $from, $to ];
	    $part{$lang}->[-1][1] = $to;
	    $part{both}->[-1][1] = $to;
	    next;
	}
	if ($lang eq 'eg') {
	    $lang = 'jp';
	    $part{both}->[-1][1] = $to;
	} else {
	    if ($para =~ /$wchar_re/) {
		warn("Unexpected wide char in english part:\n",
		     $para,
		     "***\n");
		if ($lang ne 'eg' and $lang ne 'jp') {
		    $lang = 'jp';
		    @{$part{jp}}    or @{$part{jp}}    = ([0, 0]);
		    @{$part{jptxt}} or @{$part{jptxt}} = ([0, 0]);
		    @{$part{both}}  or @{$part{both}}  = ([0, 0]);
		}
		$part{$lang}->[-1][1] = $to;
		$part{both}->[-1][1] = $to;

		next;
	    }
	    else {
		$lang = 'eg';
		push @{$part{both}}, [ $from, $to ];
	    }
	}
	push @{$part{$lang}}, [ $from, $to ];
	push @{$part{"${lang}txt"}}, [ $from, $to ];

	#if ($lang eq 'eg' and $para =~ /$wchar_re/) {
	#    die "Unexpected wide char in english part:\n", $para;
	#}
    }

    ##
    ## table, figure, example
    ##
    while (m{^(<blockquote\s+class=(\w+)>(?s:.*?)\n</blockquote>)}mg) {
	my $pos = pos();
	push @{$part{$2}}, [ $pos - length($1), $pos ];
    }
}

sub tag {
    my %arg = @_;
    my $file = delete $arg{&FILELABEL} or die;
    my $tag = join '|', keys %arg;
    my $re = qr{
	<(?<tag>$tag)\b[^>]*>
	(?(?=\n\n) #if
	  \n{2,} <\g{tag}\b[^>]*> (?s:.*?) </\g{tag}>\n{2,}</\g{tag}>\n
	  |
	  (?s:.*?) </\g{tag}>
	)
    }x;
    main::match_regions(pattern => $re);
}

sub bmcache {
    my %arg = @_;
    my $file = delete $arg{&FILELABEL} or die;
    my $cache_file = cachename($file);

    if ($arg{list}) {
	printf "%s: %s\n", $cache_file, -f $cache_file ? "yes" : "no";
    }

    $arg{nocache} and $use_cache = 0;

    $arg{nojson} and $mod_json = 0;

    if ($arg{clean}) {
	if (-f $cache_file) {
	    warn "remove $cache_file\n";
	    unlink $cache_file or warn "$cache_file: $!\n";
	}
    }

    if (($file ne '-' and -f $file)
	and
	($arg{force} or not cache_valid($file))
	and
	($arg{create} or ($arg{update} and -f $cache_file)))
    {
	warn "updating $cache_file\n";
	setdata($file, $arg{force});
	my $json_text =
	    to_json(\%part,
		    { pretty => 0,
		      indent_length => 2,
		      allow_blessed => 0,
		      convert_blessed => 1,
		      allow_nonref => 0,
		    });
	if (open CACHE, ">$cache_file") {
	    print CACHE $json_text, "\n";
	    close CACHE;
	} else {
	    warn "$cache_file: $!\n";
	}
    }
}

sub nocache { bmcache @_, nocache => 1 }
sub nojson  { bmcache @_, nojson => 1  }
sub create  { bmcache @_, create => 1  }
sub update  { bmcache @_, update => 1  }
sub cache   { bmcache @_, update => 1  }
sub clean   { bmcache @_, clean => 1   }
sub list    { bmcache @_, list => 1    }

sub cache_valid {
    my $file = shift;
    my $cache_file = cachename($file);
    my $sc = stat $cache_file;
    my $sf = stat $file;
    $sc and $sf and $sc->mtime > $sf->mtime;
}

sub cachename {
    my $file = shift;
    my($path, $name) = $file =~ m/((?:.*\/)?)(.*)/;
    my $suffix = ".greple.bm.json";
    $path . "." . $name . $suffix;
}

sub get_json {
    my $file = shift;
    open(FH, $file) or die;
    my $json_text = do { local $/; <FH> };
    close FH;
    from_json($json_text, {utf8 => 1});
}

######################################################################

my $skip_re =
    qr{
	\n?<blockquote.*?</blockquote>\n?
	|
	\n?<pre>.*?\</pre\>\n?
	|
	<div\s+class=quote\>.*?</div>
    }six;

sub join_block {
    s{
	( (?:^.+\n)+ )
    }{
	remove_newlines($1)
    }mgex;
    $_;
}

sub remove_newlines {
    local $_ = shift;

    my @list = split /($skip_re)/;

    for my $line (grep !/$skip_re/, @list) {
	my $buf = '';
	for (split /\n/, $line) {
	    $buf = append_line($buf, $_);
	}
	$line = $buf;
    }

    $_ = join '', @list;
    $_ .= "\n" unless /\n\z/;
    $_;
}

my $zenkaku =
    qr/[\p{East_Asian_Width=Wide}\p{East_Asian_Width=FullWidth}]/;

sub append_line {
    my($orig, $apnd) = @_;
    my $space = ' ';
    if ($orig ne '' and $orig !~ /\n\Z/ and
	(
	 $orig =~ m{</(?:table|blockquote)>\Z} or
	 $apnd =~ /\A(?:<(?:li)>|<\/(?:ol)>)|<\/?(?:table|tr|th|td|blockquote)/
	)
       ){
	$space = "\n";
    }
    elsif ($orig eq ''
	   or $orig =~   /[、。（）　]\Z/
	   or $apnd =~ /\A[、。（）　]/
	   # 全角で終り全角で始まる
	   or ($orig =~ /$zenkaku\Z/ and $apnd =~ /\A$zenkaku/)
	  ) {
	$space = '';
    }
    $orig . $space . $apnd;
}

1;

__DATA__

option default --cache-auto

option --part &part($<shift>)

option --cdedit --chdir $ENV{SCCC2DIR}/Edit
option --ed1 --cdedit --glob ../SCCC1/*.bm1
option --ed2 --cdedit --glob *.bm1

option --com  --nocolor -nH --re ^※+		// find all comments
option --com1 --nocolor -nH --re ^※(?!※)	// find comment level 1
option --com2 --nocolor -nH --re ^※※(?!※)	// find comment level 2
option --com3 --nocolor -nH --re ^※※※		// find comment level 3
option --com2+ --nocolor -nH --re ^※※		// find comment level 2 or <

option --injp    --inside &part(jp)		// match in Japanese part
option --injptxt --inside &part(jptxt)		// match in Japanese text part
option --jp      --block  &part(jp)		// display Japanese block
option --jptxt   --block  &part(jptxt)		// display Japanese text block

option --ineg    --inside &part(eg)		// match in English part
option --inegtxt --inside &part(egtxt)		// match in English text part
option --eg      --block  &part(eg)		// display English block
option --egtxt   --block  &part(egtxt)		// display English text block

option --both --block &part(both)		// display jp/eg combined block

option --table   --inside &part(table)		// search inside table  
option --figure  --inside &part(figure)		// search inside figure 
option --example --inside &part(example)	// search inside example
option --comment --inside &part(comment)	// display comment block

option --extable   --exclude &part(table)	// exclude table	 
option --exfigure  --exclude &part(figure)	// exclude figure 
option --exexample --exclude &part(example)	// exclude example
option --excomment --exclude &part(comment)	// exclude comment

define (#quote)    ^(?!※)(.+\n)+\n+(※.*(ママ|3010).*\n)(.+\n)*
option --exquote   --exclude (#quote)
option --quote     --re (#quote) --cm 0 --blockend=--

define (#cert-c-std-mark)	[A-Z]{3}\d\d-[A-Z]\.
define (#cert-c-std-title-1)	「(#cert-c-std-mark)[^「」]*
define (#cert-c-std-title-2)	^(#cert-c-std-mark).*
define (#cert-c-std-title)	(#cert-c-std-title-1)|(#cert-c-std-title-2)
option --exstd	--exclude (#cert-c-std-title)
option --std	--re (#cert-c-std-title)

define (#nev) (?=never)match
option --cache-auto   --begin bmcache(update)	// automatic cache update
option --cache-create --re (#nev) --begin bmcache(create)	// create cache
option --cache-clean  --re (#nev) --begin bmcache(clean)	// remove cache
option --cache-update --re (#nev) --begin bmcache(force,update) \
						// force to update cache

define (#list)	^<blockquote>\n<pre>\n(?s:.*?)\n</pre>\n</blockquote>\n
option --exlist --exclude (#list)

option --nocache      --begin bmcache(nocache)	// disable cache

option --cache        --cache-auto	// ignore
option --cache_create --cache-create	// ignore
option --cache_clean  --cache-clean	// ignore
option --cache_update --cache-update	// ignore

option --join-block --begin join_block()	// join block into single line

define (#oldcite) \[(?:[\w.]+\s+)+\d{2}\]
define (#newcite) \[(?:[\w.]+\s+)+\d{4}\]
define (#cite)    \[(?:[\w.]+\s+)+\d{2}(?:\d{2})?\]
defopt (#citepair) ((#cite))\n?+(?:.+\n)+(?:\n.+)*\g{-1}
defopt (#citeunpair) ((#cite))\n?+(?:.+\n)+(?!(?:\n.+)*\g{-1})

option --oldcite --re (#oldcite)	// old style 2digit citation
option --newcite --re (#newcite)	// new style 4digit citation
option --cite --re (#cite)		// citacion

option	--puretxt --excomment --exquote

option	--wordcheck \
	-f $ENV{SCCC2DIR}/Edit/ERROR_WORDS \
	--puretxt \
	--exstd \
	-n --uniqcolor
