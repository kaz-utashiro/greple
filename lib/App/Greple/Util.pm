package App::Greple::Util;

use strict;
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

push @EXPORT, 'uniq';
sub uniq {
    my %seen;
    grep { not $seen{$_}++ } @_;
}

##
## Mimic Text::Glob because it is not in standard library.
##
push @EXPORT, 'match_glob';
sub match_glob {
    local $_ = shift;
    s/\?/./g;
    s/\*/.*/g;
    my $regex = qr/^$_$/;
    grep { $_ =~ $regex } @_;
}

1;


package UniqIndex;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $obj = bless {
	HASH => {},
	LIST => [],
    }, $class;
    configure $obj @_ if @_;
    $obj;
}

sub hash { shift->{HASH} }
sub list { shift->{LIST} }

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

    $obj->{HASH}->{$_} //= do {
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
}

1;
