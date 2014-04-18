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

    --call=bmcache(list)     Print cache filename
    --call=bmcache(clean)    Clean up cache file
    --call=bmcache(create)   Create cache file
    --call=bmcache(udpate)   Update cache file if it exists and necessary
    --call=bmcache(nojson)   Do not use JSON module
    --call=bmcache(nocache)  Do not use cache file

    -Mbm::cache()    Keep cache file always updated
    -Mbm::nocache()  Do not use cache

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
    @EXPORT      = qw(&part &bmcache) ;
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

    %part = ( eg => [], jp => [], comment => [], both => [] ) ;

    my $lang = 'null' ;

    ##
    ## comment, eg, jp, both
    ##
    while (m{ \G ( (?:^.+\n)+ ) \n+ }mgx) {
	my $para = $1 ;
	my($from, $to) = ( $-[1], $+[1] ) ;

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

	#if ($lang eq 'eg' and $para =~ /$wchar_re/) {
	#    die "Unexpected wide char in english part:\n", $para ;
	#}
    }

    ##
    ## table, figure, example
    ##
    while (m{^<blockquote\s+class=(\w+)>(?s:.*?)</\1>}mg) {
	push @{$part{$1}}, [ $-[0], $+[0] ];
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
	($arg{create} or ($arg{update} and -f $cache_file))) {
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
	    print CACHE $json_text ;
	    close CACHE ;
	} else {
	    warn "$cache_file: $!" ;
	}
    }
}

sub nocache { bmcache @_, nocache => 1 }
sub nojson  { bmcache @_, nojson => 1 }
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

1;

__DATA__

option --cdedit --chdir $ENV{SCCC2DIR}/Edit
option --ed1 --cdedit --glob ../SCCC1/*.bm1
option --ed2 --cdedit --glob *.bm1

option --com  --nocolor -nH --re '^※+'
option --com1 --nocolor -nH --re '^※(?!※)'
option --com2 --nocolor -nH --re '^※※(?!※)'
option --com3 --nocolor -nH --re '^※※※'
option --com2+ --nocolor -nH --re '^※※'

option --injp --inside '&part(jp)'
option --jp --block '&part(jp)'

option --ineg --inside '&part(eg)'
option --eg --block '&part(eg)'

option --both --block '&part(both)'

option --comment --block '&part(comment)'

option --table   --inside '&part(table)'
option --figure  --inside '&part(figure)'
option --example --inside '&part(example)'

option --notable   --exclude '&part(table)'
option --nofigure  --exclude '&part(figure)'
option --noexample --exclude '&part(example)'

help --com      find all comments
help --com1     find comment level 1
help --com2     find comment level 2
help --com3     find comment level 3
help --com2+    find comment level 2 and more
help --injp     match text in Japanese part
help --ineg     match text in English part
help --jp       display Japanese block
help --eg       display English block
help --both     display Japanese/English combined block
help --comment  display comment block
