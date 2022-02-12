package Runner;

use strict;
use warnings;
use utf8;
use File::Spec;
use open IO => ':utf8';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Exporter 'import';
our @EXPORT_OK = '&get_path';

sub new {
    my $class = shift;
    my $obj = bless {}, $class;
    $obj->{COMMAND} = shift;
    $obj->{OPTION} = do {
	if (@_ == 1) {
	    my $command = shift;
	    if (ref $command eq 'ARRAY') {
		$_[0];
	    } else {
		use Text::ParseWords;
		[ shellwords $command ];
	    }
	} else {
	    [ @_ ];
	}
    };
    $obj;
}

use Fcntl;
use IO::File;

sub run {
    my $obj = shift;
    use IO::File;
    my $pid = (my $fh = new IO::File)->open('-|') // die "open: $@\n";
    if ($pid == 0) {
	if (my $stdin = $obj->{STDIN}) {
	    open STDIN, "<&=", $stdin->fileno or die "open: $!\n";
	    $stdin->fcntl(F_SETFD, 0) or die "fcntl F_SETFD: $!\n";
	    binmode STDIN, ':encoding(utf8)';
	}
	open STDERR, ">&STDOUT";
	$obj->execute;
	exit 1;
    }
    $obj->{STDIN} = undef;
    binmode $fh, ':encoding(utf8)';
    $obj->{stdout} = do { local $/; <$fh> };
    my $child = wait;
    $child != $pid and die "child = $child, pid = $pid";
    $obj->{pid} = $pid;
    $obj->{result} = $?;
    $obj;
}

sub status {
    my $obj = shift;
    $obj->{result} >> 8;
}

sub stdout {
    my $obj = shift;
    $obj->{stdout};
}

*result = \&stdout; # for backward compatibility

sub setstdin {
    my $obj = shift;
    my $data = shift;
    my $stdin = $obj->{STDIN} //= do {
	my $fh = new_tmpfile IO::File or die "new_tmpfile: $!\n";
	$fh->fcntl(F_SETFD, 0) or die "fcntl F_SETFD: $!\n";
	binmode $fh, ':encoding(utf8)';
	$fh;
    };
    $stdin->seek(0, 0)  or die "seek: $!\n";
    $stdin->truncate(0) or die "truncate: $!\n";
    $stdin->print($data);
    $stdin->seek(0, 0)  or die "seek: $!\n";
    $obj;
}

##
## perl stuff
##

my $lib = File::Spec->rel2abs('lib');

sub execute {
    my $obj = shift;
    my $command = $obj->{COMMAND};
    my @option = @{$obj->{OPTION}};
    exec $^X, "-I$lib", $command, @option;
}

sub get_path {
    my($script, $module) = @_;

    # Find from beside module file
    my $pm_file = $module =~ s/::/\//gr . '.pm';
    require $pm_file;
    my $pm_path = $INC{$pm_file};
    my $install = ($pm_path =~ m{(^.*) \blib (?:/[^/]+){0,2} /\Q$pm_file\E$}x)[0];
    if (defined $install) {
	$install = '.' if $install eq '';
	for my $dir (qw(bin script)) {
	    my $file = "$install/$dir/$script";
	    return $file if -f $file;
	}
    }
    # Otherwise search from $PATH
    else {
	my @script = grep { -x $_ } map "$_/$script", split /:+/, $ENV{PATH};
	return $script[0] if @script > 0;
    }
    die $pm_path;
}

1;
