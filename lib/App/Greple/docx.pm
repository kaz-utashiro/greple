=head1 NAME

docx - Greple module for access docx file

=head1 SYNOPSIS

greple -Mdocx

=head1 DESCRIPTION

=cut

package App::Greple::docx;

use strict;
use warnings;
use Carp;

use utf8;
use Encode;

use Exporter 'import';
our @EXPORT      = ();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = ();

use App::Greple::Common;
use List::Util qw( min max first sum );
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Data::Dumper;

# push @EXPORT, '&docx_begin_old';
sub docx_begin_old {
    my %arg = @_;
    my $file = delete $arg{&FILELABEL} or die;

    my $zip = Archive::Zip->new();
    $zip->read($file) == AZ_OK or die "zip read: $!\n";

    $_ = decode 'utf8', $zip->contents("word/document.xml");
}

my $zip;
my $zipdata;
my $stdout;
our $document = "word/document.xml";

push @EXPORT, '&docx_begin';
sub docx_begin {
    my %arg = @_;
    my $file = delete $arg{&FILELABEL} or die;

    if ($file =~ /\.docx$/ and $_ =~ /\A PK\003\004/x) {
	$zip = Archive::Zip->new();
	$zipdata = $_;
	my $fh = new IO::File;
	$fh->open(\$zipdata, "+<") or die "open: $!\n";
	$zip->readFromFileHandle($fh, $file) == AZ_OK or die "zip read: $!\n";
	$fh->close;

	$_ = decode 'utf8', $zip->contents($document);
	binmode STDOUT, ":encoding(utf8)";
    }
}

push @EXPORT, '&docx_divert';
sub docx_divert {
    close STDOUT;
    open STDOUT, ">", \$stdout or die "open: $!\n";
    binmode STDOUT, "encoding(utf8)";
}

push @EXPORT, '&docx_update';
sub docx_update {
    my %arg = @_;
    my $file = delete $arg{&FILELABEL} or die;
    my $newfile = $arg{file};

    if ($stdout eq "") {
	warn "$file: Empty output.";
	warn "$newfile is not created.\n" if $newfile;
	return;
    }

    if (not $zip) {
	warn "No zip data.\n";
	return;
    }

    $zip->contents($document, $stdout);

    if ($newfile) {
	if (-f $newfile and not $arg{force}) {
	    warn "File \"$newfile\" exists.\n";
	    return;
	}
	my $status = $zip->writeToFileNamed($newfile);
	die "$newfile: $!\n" if $status != AZ_OK;
    }

    warn "$newfile written.\n";
}

push @EXPORT, '&docx_text';
sub docx_text {
    my @s;
    for (m{<w:p [^>]*>(.*?)</w:p>}g) {
	s{<w:(delText)>.*?</w:\1>}{}g;
	s{<v:numPr>}{・}g;
	s{</?(?:[avw]|wp|pic)\d*:.*?>}{}g;
	push @s, "$_\n";
    }
    $_ = join '', @s;
}

push @EXPORT, '&docx_xml';
sub docx_xml {
    my $level = 0;
    my @nonewline = qw(t delText);
    my %nonewline;
    @nonewline{@nonewline} = (1) x @nonewline;

    my $indent_mark = "| ";
    s{
	(?<mark>
	  (?<single>
	    < w: (?<tag>\w+) [^/>]* />
	  )
	  |
	  (?<open>
	    < w: (?<tag>\w+) [^>]* >
	  )
	  |
	  (?<close>
	    < /w: (?<tag>\w+) >
	  )
	)
    }{
	my $s = "";
	if ($nonewline{$+{tag}}) {
	    $s = join("", $+{open} ? $indent_mark x $level : "",
			  $+{mark},
			  $+{close} ? "\n" : "");
	}
	else {
	    $+{close} and --$level;
	    $s = ($indent_mark x $level) . $+{mark} . "\n";
	    $+{open}  and ++$level;
	}
	$s;
    }gex;
}

1;

__DATA__

option default --persist --begin docx_begin

option --text --begin docx_text

define (#delText) <w:delText>.*?</w:delText>
option --pretty --begin docx_xml --exclude (#delText)

option --pretty2 --begin docx_xml2 --exclude (#delText)

option --plain --exclude (#delText) --nonewline

option --unzip \
	--if '/\.docx$/:unzip -p /dev/stdin word/document.xml' \
	--block '(?<=<w:t>).*?(?=</w:t>)'

option --create \
	--noline-number --no-filename --nonewline --all \
	--begin docx_divert \
	--end docx_update(file=$<shift>)
