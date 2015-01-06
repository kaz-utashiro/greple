package App::Greple::Common;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw(FILELABEL);
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(setopt newopt);

use constant FILELABEL => '__file__';

*setopt = \&main::setopt;
*newopt = \&main::newopt;

1;
