use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

like(run('-e "thorn" t/Checker.pm')->stdout,
     qr/^SKIP/m, "default");

like(run('-e "thorn" --error=skip t/Checker.pm')->stdout,
     qr/^SKIP/m, "--error=skip");

like(run('-e "thorn" -wall t/Checker.pm')->stdout,
     qr/^SKIP/m, "-wall");

is(run('-e "thorn" --warn all=0 t/Checker.pm')->stdout,
     '', "empty");

like(run('-e "thorn" --error=retry t/Checker.pm')->stdout,
     qr/thorn/, "--error=retry");

like(run('-e "thorn" --error=retry --warn=retry t/Checker.pm')->stdout,
     qr/^RETRY/, "--error=retry w/warn");

{
my $x = run('-e "thorn" --error=fatal t/Checker.pm');
isnt($x->status, 0, "--error=fatal");
like($x->stdout, qr/^ABORT/, "--error=fatal ABORT message");
}

like(run('-e "thorn" --error=ignore t/Checker.pm')->stdout,
     qr/thorn/, "--error=ignore");

isnt(run('-e "thorn" --error=something t/Checker.pm')->status,
     0, "--error=something");

done_testing;
