=head1 NAME

bm - Greple module for bombay format

=head1 SYNOPSIS

greple -Mbm [ options ]

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
    --comment            display comment block
    --table              search inside table  
    --figure             search inside figure 
    --example            search inside example
    --notable            exclude table	 
    --nofigure           exclude figure 
    --noexample          exclude example
    --cache-auto         automatic cache update
    --cache-create       create cache
    --cache-clean        remove cache
    --cache-update       force to update cache
    --nocache            disable cache
    --join-block         join block into single line


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

To keep cache files always updated, use option B<-Mbm::cache()>.  It
will update cache file if it exits and necessary.

Use B<-Mbm::create()> to create cache file for the first time.

Option B<--call=bmcache(command)> is more generic interface.  Use
B<--call=bmcache(clean)> to clean up cache files, for instance.  Use
B<--call=bmcache(force,update)> to force update cache even if the
valid cache file exits.

=cut

package App::Greple::bm ;

use utf8 ;
use strict ;
use warnings ;

use Data::Dumper ;
use Carp ;
use File::stat ;

my $use_json = 0 ;
my $mod_json ;
if ($use_json) {
    eval "use JSON" ;
    $mod_json = not $@ ;
} else {
    $mod_json = 0 ;
}

$mod_json or eval q{
    sub to_json {
	my $obj = shift ;
	local $_ = Dumper $obj ;
	s/\s+//g ;
	s/'([a-zA-Z_]+)'/"$1"/g ;
	s/'(\d+)'/$1/g ;
	s/=>/:/g ;
	$_ ;
    }
    sub from_json {
	local $_ = shift ;
	s/:/=>/g ;
	eval $_ ;
    }
} ;

BEGIN {
    use Exporter   () ;
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS) ;

    $VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g ;

    @ISA         = qw(Exporter) ;
    @EXPORT      = qw(&part &bmcache &join_block) ;
    %EXPORT_TAGS = ( ) ;
    @EXPORT_OK   = qw() ;
}
our @EXPORT_OK ;

END { }

my $target = -1 ;
my %part ;
my $use_cache = 1 ;

#
# [\p{East_Asian_Width=Wide}\p{East_Asian_Width=FullWidth}]
# 第一版中、英文の中に句読点や「・」が出てくることがある。
# 「う」に濁点がフォントによっては表示できない。
#
my $wchar_re = qr{
    [\p{Han}ぁ-んゔァ-ンヴ]
}x;

sub part {
    my %arg = @_ ;

    if ($target != \$_) {
	setdata($arg{file}) ;
	$target = \$_ ;
    }

    regions(grep { $_ ne 'file' and $arg{$_} } keys %arg);
}

sub regions {
    sort { $a->[0] <=> $b->[0] }
    map  { @{ $part{$_} } }
    grep { $part{$_} }
    @_;
}

sub setdata {
    my $file = shift ;
    my $nocache = @_ ? shift : 0 ;

    if (!$nocache and $use_cache and cache_valid($file)) {
	if (my $obj = get_json(cachename($file))) {
	    %part = %{ $obj } ;
	    return ;
	}
    }

    %part = ( egtxt => [], jptxt => [],
	      eg => [], jp => [],
	      both => [],
	      comment => [],
	) ;

    my $lang = 'null' ;

    ##
    ## comment, eg, jp, both
    ##
    while (m{ ^ ( (?:.+\n)+ (?:.*\z)? )  }mgx) {
#	my($from, $to) = ( $-[1], $+[1] ) ;
	my $to = pos();
	my $from = $to - length $1;
	my $para = $1 ;

	next if $para =~ /\A-\*-/ ;

	if ($para =~ /\A※/) {
	    push @{$part{comment}}, [ $from, $to ] ;
	    $part{$lang}->[-1][1] = $to ;
	    $part{both}->[-1][1] = $to ;
	    next;
	}
	if ($lang eq 'eg') {
	    $lang = 'jp' ;
	    $part{both}->[-1][1] = $to ;
	} else {
	    if ($para =~ /$wchar_re/) {
		warn("Unexpected wide char in english part:\n",
		     $para,
		     "***\n") ;
		if ($lang ne 'eg' and $lang ne 'jp') {
		    $lang = 'jp';
		    @{$part{jp}}    or @{$part{jp}}    = ([0, 0]);
		    @{$part{jptxt}} or @{$part{jptxt}} = ([0, 0]);
		    @{$part{both}}  or @{$part{both}}  = ([0, 0]);
		}
		$part{$lang}->[-1][1] = $to ;
		$part{both}->[-1][1] = $to ;

		next ;
	    }
	    else {
		$lang = 'eg' ;
		push @{$part{both}}, [ $from, $to ] ;
	    }
	}
	push @{$part{$lang}}, [ $from, $to ] ;
	push @{$part{"${lang}txt"}}, [ $from, $to ] ;

	#if ($lang eq 'eg' and $para =~ /$wchar_re/) {
	#    die "Unexpected wide char in english part:\n", $para ;
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

sub bmcache {
    my %arg = @_ ;

    my $cache_file = cachename($arg{file}) ;

    if ($arg{list}) {
	printf "%s: %s\n", $cache_file, -f $cache_file ? "yes" : "no" ;
    }

    $arg{nocache} and $use_cache = 0 ;

    $arg{nojson} and $mod_json = 0 ;

    if ($arg{clean}) {
	if (-f $cache_file) {
	    warn "remove $cache_file\n" ;
	    unlink $cache_file or warn "$cache_file: $!\n" ;
	}
    }

    if (($arg{file} ne '-' and -f $arg{file})
	and
	($arg{force} or not cache_valid($arg{file}))
	and
	($arg{create} or ($arg{update} and -f $cache_file)))
    {
	warn "updating $cache_file\n" ;
	setdata($arg{file}, $arg{force}) ;
	my $json_text =
	    to_json(\%part,
		    { pretty => 0,
		      indent_length => 2,
		      allow_blessed => 0,
		      convert_blessed => 1,
		      allow_nonref => 0,
		    });
	if (open CACHE, ">$cache_file") {
	    print CACHE $json_text, "\n" ;
	    close CACHE ;
	} else {
	    warn "$cache_file: $!\n" ;
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
    my $file = shift ;
    my $cache_file = cachename($file) ;
    my $sc = stat $cache_file ;
    my $sf = stat $file ;
    $sc and $sf and $sc->mtime > $sf->mtime ;
}

sub cachename {
    my $file = shift ;
    my($path, $name) = $file =~ m/((?:.*\/)?)(.*)/ ;
    my $suffix = ".greple.bm.json" ;
    $path . "." . $name . $suffix ;
}

sub get_json {
    my $file = shift ;
    open(FH, $file) or die;
    my $json_text = do { local $/; <FH> } ;
    close FH ;
    from_json($json_text, {utf8 => 1}) ;
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
    my $_ = shift;

    my @list = split(/($skip_re)/, $_);

    for my $line (grep !/$skip_re/, @list) {
	my $buf = '';
	for (split(/\n/, $line)) {
	    $buf = append_line($buf, $_);
	}
	$line = $buf;
    }

    $_ = join('', @list);
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

option --comment --block &part(comment)		// display comment block

option --table   --inside &part(table)		// search inside table  
option --figure  --inside &part(figure)		// search inside figure 
option --example --inside &part(example)	// search inside example

option --notable   --exclude &part(table)	// exclude table	 
option --nofigure  --exclude &part(figure)	// exclude figure 
option --noexample --exclude &part(example)	// exclude example

define :nev: (?=never)match
option --cache-auto   --call bmcache(update)	// automatic cache update
option --cache-create --re :nev: --call bmcache(create)	// create cache
option --cache-clean  --re :nev: --call bmcache(clean)	// remove cache
option --cache-update --re :nev: --call bmcache(force,update) \
						// force to update cache
option --nocache      --call bmcache(nocache)	// disable cache

option --cache        --cache-auto	// ignore
option --cache_create --cache-create	// ignore
option --cache_clean  --cache-clean	// ignore
option --cache_update --cache-update	// ignore

option --join-block --call join_block()		// join block into single line

option --oldcite --re '\[([\w.]+\s+)+\d{2}\]'	// old style 2digit citation
option --newcite --re '\[([\w.]+\s+)+\d{4}\]'	// new style 4digit citation
option --cite --re '\[([\w.]+\s+)+\d{2,4}\]'	// citacion
