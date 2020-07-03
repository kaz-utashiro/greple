=head1 NAME

find - Greple module to use find command

=head1 SYNOPSIS

greple -Mfind find-options -- greple-options ...

=head1 DESCRIPTION

Provide B<find> command option with ending '--'.

B<Greple> will invoke B<find> command with provided options and read
its output from STDIN, with option B<--readlist>.  So

    greple -Mfind . -type f -- pattern

is equivalent to:

    find . -type f | greple --readlist pattern

If the first argument start with `!', it is taken as a command name
and executed in place of B<find>.  You can search git managed files
like this:

    greple -Mfind !git ls-files -- pattern

=cut


package App::Greple::find;

use v5.14;
use warnings;
use Carp;
use Data::Dumper;

use App::Greple::Common;

my $path;
my $chdir;
my $debug;
my @pid;

sub set {
    my %arg = @_;
    $path = $arg{path} if defined $arg{path};
    $chdir = $arg{chdir} if defined $arg{chdir};
}

sub initialize {
    my $rc = shift;
    my $argv = shift;

    if ($chdir) {
	chdir $chdir or die "chdir: $!";
    }

    my @find;
    while (@$argv) {
	last if $argv->[0] =~ /^--(man|show)$/;
	my $arg = shift @$argv;
	last if $arg eq '--';
	push @find, $arg;
    }
    return unless @find;

    my $pid = open STDIN, '-|' // croak "process fork failed";
    push @pid, $pid;
    return if $pid;

    unless ($find[0] =~ s/^!//) {
	unshift @find, $path if defined $path;
	unshift @find, 'find';
    }
    if (@pid > 1) {
	print while <>;
    }
    exec @find or croak "Can't exec $find[0]";
}

1;

__DATA__

option default --readlist
