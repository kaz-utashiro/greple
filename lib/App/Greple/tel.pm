=encoding utf8

=head1 NAME

tel - Module to support simple telephone/address data file

=head1 SYNOPSIS

greple -Mtel [ options ]

=head1 SAMPLES

greple -Mtel pattern

=head1 DESCRIPTION

Sample module for B<greple> command supporting simple telephone /
address data file.

=head1 FORMAT

NAME, TEL, ADDRESS fields are separated by tab.

The line start with space is continuous line.

[ keyword1, keyword2, ... ]

< string to be printed >

    [travel,airline]UA Reservations         800-241-6522
    [travel,airline]UA Premier Reservations
            03-3817-4441    Japan
            800-356-8900    US and Canada
            008-025-808     Australia
            810-1308        Hong Kong
            02-325-9914     Korea
            09-358-3500     New Zealand
            810-4356        Philippines
            321-8888        Singapore
            02-325-9914     Taiwan
    [travel,airline]UA Premier Exective
            800-225-8900    Reservations
            800-325-0046    Service Desk

    Kokkai Gijidou, The National Diet <国会議事堂>
            03-5521-7445    100-0014 東京都千代田区永田町1-7-1

=cut

package App::Greple::tel;

use strict;
use warnings;

use utf8;
use Encode;
use Carp;
use Data::Dumper;

use parent qw(Exporter);
our @EXPORT = qw(&tel_prologue &tel_epilogue &tel_print);

our $opt_csv;
our $opt_tbl;
our $opt_count;
our $opt_verbose;
our @opt_keys;
our @opt_ignore;
our @opt_require;
my %opt_keys;
my %opt_ignore;
my %opt_require;

my $module = "My::Addr";

sub tel_prologue {
    %opt_keys    = map { ($_ => 1) } map { /([\w_-]+)/g } @opt_keys;
    %opt_ignore  = map { ($_ => 1) } map { /([\w_-]+)/g } @opt_ignore;
    %opt_require = map { ($_ => 1) } map { /([\w_-]+)/g } @opt_require;

    my @sub_module = sub {
	return ("CSV") if $opt_csv;
	return ("TBL") if $opt_tbl;
	("DISPLAY");
    }->();
    $module = join('::', $module, @sub_module) if @sub_module;

    if ($module->can('header')) {
	print $module->header;
    }
}

sub tel_epilogue {
    if ($module->can('footer')) {
	print $module->footer;
    }
}

use List::Util qw(first);
sub in_hash {
    my $list = shift;
    first { $list->{$_} } @_;
}

sub tel_print {
    my %attr = @_;
    my $data = $module->new($_);

    if (not $data->keycheck(match   => \%opt_keys,
			    require => \%opt_require,
			    ignore  => \%opt_ignore)) {
	return undef;
    }

    $data->to_text;
}

package My::Addr {
    sub new {
	my $class = shift;
	local $_ = shift;

	s/^\s*#.*\n//mg;

	my @record = split /\n/;
	my($name, $jname, $ename, @keys);

	my($fname, $tel, $addr) = split /\t+/, $record[0];
	shift @record unless defined $tel;
	$fname =~ s/\s*<(.*)>\s*// and $jname = $1;
	$fname =~ s/\s*\[(.*?)\]\s*// and @keys = split (/\s*,\s*/, $1);
	$name = $jname || $fname;
	($ename = $fname) =~ s/^\s*(.*)\s*/$1/;

	my @data;
	if ($tel and $addr) {
	    push @data, { tel => $tel, addr => $addr};
	}

	for my $data (@record) {
	    my($dummy, $tel, $addr) = split(/\t+/, $data);
	    $tel = '' if not defined $tel or length($tel) <= 2;
	    push @data, { tel => $tel, addr => $addr//'' };
	}

	my $obj = bless {
	    name  => $name,
	    jname => $jname,
	    ename => $ename,
	    keys  => \@keys,
	    data  => \@data,
	}, $class;
    }
    sub to_text {
	use Data::Dumper;
	$Data::Dumper::Sortkeys = 1;
	Dumper $_[0];
    }
    sub keycheck {
	my $obj = shift;
	my %opt = @_;
	my @keys = @{$obj->keys};
	my $hash;

	if (($hash = $opt{require}) and %{$hash}) {
	    my %keys = map { ( $_ => 1 ) } @keys;
	    use List::Util qw(all);
	    all { $keys{$_} } CORE::keys %$hash or return undef;
	}

	if (($hash = $opt{match}) and %{$hash}) {
	    grep { $hash->{$_} } @keys or return undef;
	}

	if ($hash = $opt{ignore}) {
	    grep { $hash->{$_} } @keys and return undef;
	}

	return 1;
    }
    sub name  { $_[0]->{name}  }
    sub jname { $_[0]->{jname} }
    sub ename { $_[0]->{ename} }
    sub keys  { $_[0]->{keys}  }
    sub data  { $_[0]->{data}  }
}

package My::Addr::DISPLAY {
    our @ISA = qw(My::Addr);

    use Text::VisualWidth::PP qw/vwidth/;
    use Text::VisualPrintf qw/vsprintf/;

    sub to_text {
	my $obj = shift;
	my $s = '';
	my $count = $opt_count || -1;

	my $name = $obj->name;
	if (vwidth($name) > 18) {
	    $s .= "$name\n";
	    $name = '';
	}

	for my $data (@{$obj->data}) {
	    my($tel, $addr) = ($data->{tel}, $data->{addr});
	    if ($opt_verbose and (my @keys = @{$obj->keys})) {
		$addr = sprintf("[%s] %s", join(',', @keys), $addr);
	    }
	    $tel = '' if not defined $tel or length($tel) <= 2;
	    $s .= vsprintf("%-18s %-16s %s\n", $name, $tel, $addr || '');
	    last if --$count == 0;
	    $name = '';
	}
	$s;
    }
}

package My::Addr::CSV {
    our @ISA = qw(My::Addr);

    sub header {
	my @lables = qw(氏名 よみ 連名 郵便番号 住所_1 住所_2);
	join("\t", @lables) . "\n";
    }

    sub to_text {
	my $obj = shift;

	my $top = $obj->data->[0];
	my ($tel, $addr) = ($top->{tel}, $top->{addr});

	my $renmei = '';
	my $roman = '';
	my $zip = '';

	my $jname = $obj->name;

	if ($jname =~ s/,(.*)//) {
	    $renmei = $1;
	    $renmei =~ s/\s+//g;
	    $renmei =~ s/\s*,\s*/・/g;
	}
	$jname =~ s/ +/　/g;

	require 'romkan.pl';
      romkan: {
	  $_ = $obj->ename;
	  while (s/^[\s,]*([\w']+)//) {
	      my $orig = $1;
	      my $tmp = &main::romkan($orig);
	      unless ($tmp) {
		  $tmp = $orig;
	      }
	      $roman .= " " if $roman ne "";
	      $roman .= $tmp;
	  }
	}

	use Unicode::EastAsianWidth;
	if ($addr =~ /\p{InFullwidth}/ && $addr =~ s/^(\d{3})(-(\d{2,4}))?\s+//) {
	    $zip = $1;
	    if ($3) {
		$zip .= " $3";
	    }
	}

	my($addr1, $addr2);
	if ($addr !~ /\p{InFullwidth}/) {
	    ($addr1, $addr2) = ($addr, '');
	} else {
	    my @addr = split ' ', $addr;
	    while (@addr > 1 and $addr[1] =~ /^([\d\-]+|丁目|番|番地|号|の)+$/) {
		my @tmp = splice @addr, 0, 2;
		unshift @addr, join('', @tmp);
	    }
	    $addr1 = shift @addr;
	    $addr2 = join ' ', @addr;
	    $addr2 =~ s/(\D) (\d)/$1$2/g;
	}

	join("\t", $jname, $roman, $renmei, $zip, $addr1, $addr2) . "\n";
    }
}

1;

package My::Addr::TBL {
    our @ISA = "My::Addr";

    sub header {
	<<"	EOC" =~ s/^\t//gmr;
	.sp 0.5c
	.ps 6
	.vs 6.5
	.ft H
	.TS
	box;
	cw(2c) c cw(4c)
	lw(1.7c) l l.
	Name	Tel	Notes
	_
	EOC
    }
    
    sub footer {
	".TE\n";
    }

    sub to_text {
	my $obj = shift;
	my $s = "";
	my $name = $obj->jname || $obj->ename;
	for my $data (@{$obj->data}) {
	    my($tel, $addr) = ($data->{tel}, $data->{addr});
	    $tel = '' if not defined $tel or length($tel) <= 2;
	    $s .= $name;
	    $s .= "\t$tel" if $tel ne "" || $addr ne "";
	    if ($addr) {
		if (length($addr) > 45) {
		    $s .= "\tT{\n$addr\nT}";
		} else {
		    $s .= "\t$addr";
		}
	    }
	    $s .= "\n";
	    $name = "";
	}
	$s;
    }

}

__DATA__

option default \
	--icode=guess --ignore-case \
	--block='^(?!#)\S.*\n(?:(?=[\s#]).*\n)*' \
	--inside='^(?!#)\S[^\[\n]*' \
	--prologue tel_prologue \
	--epilogue tel_epilogue \
	--print    tel_print \
	--chdir ~/lib --glob telephone --glob tel.*[a-z0-9]

builtin csv       $opt_csv
builtin tbl       $opt_tbl
builtin key=s     @opt_keys
builtin ignore=s  @opt_ignore
builtin require=s @opt_require
builtin c|count=i $opt_count
builtin v|verbose $opt_verbose
