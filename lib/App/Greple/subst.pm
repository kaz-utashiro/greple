=head1 NAME

subst - Greple module for text substitution

=head1 SYNOPSIS

greple -Msubst [ options ]

  --subst_file spec_file
  --subst_from string
  --subst_to   string

  --diff
  --diffcmd command
  --create
  --replace

=head1 DESCRIPTION

This B<greple> module supports word substitution in text data.

Substitution can be indicated by option B<--subst_from> and
B<--subst_to>, or specification file.

Next command replaces all string "FROM" to "TO".

  greple -Msubst --subst_from FROM --subst_to TO FROM

Of course, you should rather use B<sed> in this case.  Option
B<--subst_from> and B<--subst_to> can be repeated, and substitution is
done in order.

Using B<--subst_file> option, you can prepare these substitution list
in the file.  Suppose the file cotains following data:

    Monday     Mon.
    Tuesday    The.
    Wednesday  Wed.
    Thursday   Thu.
    Friday     Fri.
    Saturday   Sat.
    Sunday     Sun.

Next command converts day-of-week name to abbreviation form.

    greple -Msubst --subst_file SPEC '\b[A-Z][a-z]+' ...

Field "//" in spec file is ignored, so this file can be written like
this:

    Monday     //  Mon.
    Tuesday    //  The.
    Wednesday  //  Wed.
    Thursday   //  Thu.
    Friday     //  Fri.
    Saturday   //  Sat.
    Sunday     //  Sun.

You can use same file by B<greple>'s B<-f> option and string after
"//" is ignored as a comment in that case.

    greple -Msubst --subst_file SPEC -f SPEC ...

This is equivalent to search next pattern, and replace them.  This is
bad example, though.

    Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday   

Actually, it takes the second last field as a target, and the last
field as a substitution string.  All other fields are ignored.  This
behavior is useful when the pattern requires longer text than the
string to be converted.  See the next example:

    Black-\KMonday  // Monday  Friday

Pattern matches to string "Monday", but requires string "Black-" is
preceeding to it.  Substitution is done just for string "Monday",
which does not match to the original pattern.  As a matter of fact,
look-ahead and look-behind pattern is removed automatically, next
example works as expected.

    (?<=Black-)Monday  // Friday

Combining with B<greple>'s other options, it is possible to convert
strings in the specific area of the target files.

=over 7

=item B<--diff>

Produce diff output of original and converted text.

=item B<--diffcmd> I<command>

Specify diff command name used by B<--diff> option.  Default is "diff
-u".

=item B<--create>

Create new file and write the result.  Suffix ".new" is appended to
original filename.

=item B<--replace>

Replace the target file by converted result.  Original file is renamed
to backup name with ".bak" suffix.

=back

=head1 BUGS

This module is made for Japanese text processing, and it is difficult
to imagine the useful situation handling ascii.

=cut

package App::Greple::subst;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw(&subst_begin &subst &subst_diff &subst_create);
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Carp;
use Data::Dumper;
use Text::ParseWords qw(shellwords);
use App::Greple::Common;

our $debug = 0;
our $remember_data = 1;
our @opt_subst_from;
our @opt_subst_to;
our @opt_subst_file;
our $opt_subst_diffcmd = "diff -u";
our $opt_U;

my $initialized;
my $current_file;
my $contents;
my %fromto;
my @fromto;
my @subst_diffcmd;

sub debug {
    $debug = 1;
}

sub set_fromto ($$) {
    my($from, $to) = @_;

    if (exists $fromto{$from}) {
	if ($fromto{$from} eq $to) {
	    warn "[$from -> $to] duplicated\n";
	    return;
	} else {
	    warn "[$from -> $to] ignored\n";
	}
    } else {
	$fromto{$from} = $to;
    }
    # \Z is better than \z here
    push @fromto, [ qr/\A$from\Z/, $to ];
}

sub subst_initialize {

    @subst_diffcmd = shellwords $opt_subst_diffcmd;

    if (defined $opt_U) {
	@subst_diffcmd = ("diff", "-U$opt_U");
    }

    for my $spec (@opt_subst_file) {
	read_file($spec);
    }

    my($from, $to);
    while (defined ($from = shift @opt_subst_from)) {
	if (not defined ($to = shift @opt_subst_to)) {
	    warn __PACKAGE__ . ": ($from) Unmatched parameter.\n";
	    next;
	}
	set_fromto $from, $to;
    }
    map { warn __PACKAGE__ . ": ($_) Unmatched parameter.\n" } @opt_subst_to;

    $initialized = 1;
}

sub subst_begin {
    my %arg = @_;
    $current_file = delete $arg{&FILELABEL} or die;
    $contents = $_ if $remember_data;

    local $_; # for safety
    subst_initialize if not $initialized;
}

sub read_file {
    my $spec = shift;

    open SPEC, "<:encoding(utf8)", $spec or die "$spec: $!\n";

    local $_;
    while (<SPEC>) {
	chomp;
	s/^\s*#.*//;
	/\S/ or next;

	my @param = grep { not m{^//+$} } split ' ';
	next if @param < 2;
	my($from, $to) = splice @param, -2, 2;
	$from =~ s/\(\? \<? [=!] [^\)]* \)//gx; # rm look-behind/look-ahead
	set_fromto $from, $to;
    }
    close SPEC;
}

sub subst {
    for my $fromto (@fromto) {
	s/$fromto->[0]/$fromto->[1]/ and last;
    }
    $_;
}

sub subst_diff {
    my $orig = $current_file;
    my $io;

    if ($remember_data) {
	use IO::Pipe;
	$io = new IO::Pipe;
	my $pid = fork() // die "fork: $!\n";
	if ($pid == 0) {
	    $io->writer;
	    binmode $io, ":encoding(utf8)";
	    print $io $contents;
	    exit;
	}
	$io->reader;
    }

    # clear close-on-exec flag
    if ($io) {
	use Fcntl;
	my $fd = $io->fcntl(F_GETFD, 0) or die "fcntl F_GETFD: $!\n";
	$io->fcntl(F_SETFD, $fd & ~FD_CLOEXEC) or die "fcntl F_SETFD: $!\n";
	$orig = sprintf "/dev/fd/%d", $io->fileno;
    }

    exec @subst_diffcmd, $orig, "-";
    die "exec: $!\n";
}

sub subst_create {
    my %arg = @_;
    my $filename = delete $arg{&FILELABEL};

    my $suffix = $arg{suffix} || '.new';

    my $newname = do {
	my $tmp = $filename . $suffix;
	for (my $i = 1; -f $tmp; $i++) {
	    $tmp = $filename . $suffix . "_$i";
	}
	$tmp;
    };

    my $create = do {
	if ($arg{replace}) {
	    warn "rename $filename -> $newname\n";
	    rename $filename, $newname or die "rename: $!\n";
	    die if -f $filename;
	    $filename;
	} else {
	    warn "create $newname\n";
	    $newname;
	}
    };
	
    close STDOUT;
    open STDOUT, ">:encoding(utf8)", $create or die "open: $!\n";
}

1;

__DATA__

option --subst --begin subst_begin --colormap &subst
option --diff --subst --all --need 0 -h --of &subst_diff
option --create --subst --all --need 0 -h --begin subst_create
option --replace --subst --all --need 0 -h --begin subst_create(replace,suffix=.bak)

builtin subst_from=s @opt_subst_from
builtin subst_to=s   @opt_subst_to
builtin subst_file=s @opt_subst_file
builtin diffcmd=s    $opt_subst_diffcmd
builtin U=i          $opt_U
