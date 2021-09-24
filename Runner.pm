package Runner;

use strict;
use warnings;
use utf8;
use File::Spec;
use open IO => ':utf8';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $lib = File::Spec->rel2abs('lib');
my $dir = File::Spec->rel2abs('script');

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

sub run {
    my $obj = shift;
    use IO::File;
    my $pid = (my $fh = new IO::File)->open('-|') // die "open: $@\n";
    if ($pid == 0) {
	open STDERR, ">&STDOUT";
	$obj->execute;
	exit 1;
    }
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

sub execute {
    my $obj = shift;
    my $name = $obj->{COMMAND};
    my $command = $name =~ s/^(?!\/)/$dir/r;
    my @option = @{$obj->{OPTION}};
    exec $^X, "-I$lib", $command, @option;
}

1;
