package App::Greple::Common;

use v5.14;
use warnings;

use Exporter 'import';
our @EXPORT      = ();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

use constant FILELABEL => '__file__';
push @EXPORT, qw(FILELABEL);

*opt_d  = \%main::opt_d;		push @EXPORT, qw(%opt_d);

*setopt = \&main::setopt;		push @EXPORT_OK, qw(setopt);
*newopt = \&main::newopt;		push @EXPORT_OK, qw(newopt);

1;
