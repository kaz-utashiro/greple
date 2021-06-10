use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

like(greple('-e "thorn" t/Checker.pm')->result,
     qr/^SKIP/m, "default");

like(greple('-e "thorn" --error=skip t/Checker.pm')->result,
     qr/^SKIP/m, "--error-skip");

like(greple('-e "thorn" -wall t/Checker.pm')->result,
     qr/^SKIP/m, "-wall");

is(greple('-e "thorn" --warn all=0 t/Checker.pm')->result,
     '', "empty");

like(greple('-e "thorn" --persist t/Checker.pm')->result,
     qr/thorn/, "--persist");

like(greple('-e "thorn" --error=retry t/Checker.pm')->result,
     qr/thorn/, "--error=retry");

like(greple('-e "thorn" --error=retry --warn=retry t/Checker.pm')->result,
     qr/^RETRY/, "--error=retry w/warn");

{
my $x = greple('-e "thorn" --error=fatal t/Checker.pm');
isnt($x->status, 0, "--error=fatal");
like($x->result, qr/^ABORT/, "--error=fatal ABORT message");
}

like(greple('-e "thorn" --error=ignore t/Checker.pm')->result,
     qr/thorn/, "--error=ignore");

isnt(greple('-e "thorn" --error=something t/Checker.pm')->status,
     0, "--error=something");

done_testing;
