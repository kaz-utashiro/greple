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
