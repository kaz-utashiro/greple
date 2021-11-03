use strict;
use warnings;
use utf8;
use File::Spec;
use open IO => ':utf8', ':std';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use lib '.';
use t::Runner;

sub greple {
    Runner->new('greple', @_)->run;
}

sub line {
    qr/\A(?:.+\n){$_[0]}\z/;
}

1;
