use strict;
use warnings;
use utf8;
use File::Spec;
use open IO => ':utf8', ':std';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use lib 't/runner';
use Runner qw(get_path);

my $greple_path = get_path('greple', 'App::Greple') or die Dumper \%INC;

sub greple {
    Runner->new($greple_path, @_);
}

sub run {
    greple(@_)->run;
}

sub line {
    qr/\A(?:.*\n){$_[0]}\z/;
}

1;
