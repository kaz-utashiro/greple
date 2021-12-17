use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';

use Data::Dumper;
use Runner qw(get_path);

my $greple_path = get_path('greple', 'App::Greple') or die Dumper \%INC;

sub greple {
    Runner->new($greple_path, @_);
}

1;
