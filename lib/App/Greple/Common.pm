package App::Greple::Common;

use strict;
use warnings;

use Exporter qw(import);

BEGIN {
    use Exporter   () ;
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS) ;

    @ISA         = qw(Exporter) ;
    @EXPORT      = qw(FILELABEL) ;
    %EXPORT_TAGS = ( ) ;
    @EXPORT_OK   = qw() ;
}

use constant FILELABEL => '__file__';

1;
