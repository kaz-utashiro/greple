package App::Greple::Util;

use v5.14;
use warnings;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

use App::Greple::Common;


##
## easy implementation. don't be serious.
##
push @EXPORT, 'shellquote';
sub shellquote {
    my $quote = qr/[\s\\(){}\|\*?]/;
    map { /^(-+\w+=)(.*$quote.*)$/
	      ? "$1\'$2\'"
	      :  /^(.*$quote.*)$/
	      ? "\'$1\'"
	      : $_ }
    @_;
}

1;


package UniqIndex;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $obj = bless {
	HASH  => {},
	LIST  => [],
	COUNT => [],
    }, $class;
    configure $obj @_ if @_;
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

1;
