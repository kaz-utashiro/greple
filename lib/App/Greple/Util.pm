package App::Greple::Util;

use v5.24;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(shellquote);

use App::Greple::Common;

##
## easy implementation. don't be serious.
##
sub shellquote {
    state $option  = qr/-++[-:\w]+=/;
    state $special = qr/[\s\\(){}\|\*?]/;
    map { s/^(${option}?)(.*${special}.*)\z/$1\'$2\'/sr } @_;
}

package #
    UniqIndex
{
    use strict;
    use warnings;

    sub new {
	my $class = shift;
	my $obj = bless {
	    HASH  => {},
	    LIST  => [],
	    COUNT => [],
	}, $class;
	$obj->configure(@_) if @_;
	$obj;
    }

    sub hash  { shift->{HASH}  }
    sub list  { shift->{LIST}  }
    sub count { shift->{COUNT} }

    sub configure {
	my $obj = shift;
	while (@_ >= 2) {
	    $obj->{$_[0]} = $_[1];
	    splice @_, 0, 2;
	}
    }

    sub index {
	my $opt = ref $_[0] eq 'HASH' ? shift : {};
	my $obj = shift;
	local $_ = shift;

	my $index = $obj->{HASH}->{$_} //= do {
	    if (my $prepare = $obj->{prepare}) {
		for my $sub (@$prepare) {
		    $_ = $sub->call();
		}
	    }
	    s/\n+//g    if $obj->{ignore_newline};
	    s/\s+//g    if $obj->{ignore_space};
	    s/\pS+//g   if $obj->{ignore_symbol};
	    s/\pP+//g   if $obj->{ignore_punct};
	    $_ = lc($_) if $obj->{ignore_case};
	    $obj->{HASH}->{$_} //= do {
		my $list = $obj->{LIST};
		push @$list, $_;
		$#{ $list };
	    };
	};

	$obj->{COUNT}->[$index] += 1;

	$index;
    }
}

package #
    Indexer
{
    sub new {
	my $class = shift;
	my $obj = { @_ };
	bless $obj, $class;
    }
    sub index   { shift->{index}->() }
    sub reset   { shift->{reset}->() }
    sub block   { shift->{block}     }
    sub reverse { shift->{reverse}   }
}

1;
