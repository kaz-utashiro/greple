package App::Greple::Common;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = ();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

use constant FILELABEL => '__file__';
push @EXPORT, qw(FILELABEL);

use constant {
    MATCH_NEGATIVE => 0,
    MATCH_POSITIVE => 1,
    MATCH_MUST => 2,
};
push @EXPORT, qw(
    MATCH_NEGATIVE
    MATCH_POSITIVE
    MATCH_MUST
);

*opt_d  = \%main::opt_d;		push @EXPORT, qw(%opt_d);

*setopt = \&main::setopt;		push @EXPORT_OK, qw(setopt);
*newopt = \&main::newopt;		push @EXPORT_OK, qw(newopt);

1;
