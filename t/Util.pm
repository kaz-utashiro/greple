use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $lib    = File::Spec->rel2abs('lib');
my $greple = File::Spec->rel2abs('script/greple');

sub greple {
    Greple->new(@_)->run;
}

package Greple {
    use strict;
    use warnings;
    use utf8;
    use Data::Dumper;
    $Data::Dumper::Sortkeys = 1;

    sub new {
	my $class = shift;
	my $obj = bless {}, $class;
	my $command = shift;
	$obj->{OPTION} = do {
	    if (ref $command eq 'ARRAY') {
		$command;
	    } else {
		use Text::ParseWords;
		[ shellwords $command ];
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
	    close STDIN;
	    greple(@{$obj->{OPTION}});
	    exit 1;
	}
	binmode $fh, ':encoding(utf8)';
	$obj->{RESULT} = do { local $/; <$fh> };
	my $child = wait;
	$child != $pid and die "child = $child, pid = $pid";
	$obj->{STATUS} = $?;
	$obj;
    }
    sub status {
	my $obj = shift;
	$obj->{STATUS} >> 8;
    }
    sub result {
	my $obj = shift;
	$obj->{RESULT};
    }
    sub greple {
	exec $^X, "-I$lib", $greple, @_;
    }
}

1;
