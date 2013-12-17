=head1 NAME

perl - Greple module for perl script

=head1 SYNOPSIS

greple -Mperl [ options ]

=head1 SAMPLES

greple -Mperl option pattern
    --code        search from perl code outisde of pod document
    --pod         search from pod document
    --comment     search from comment part
    --allsection  search from all sections

=head1 DESCRIPTION

Sample module for B<greple> command supporting perl script.

=cut

package App::Greple::perl;

use strict;
use warnings;

use Carp;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&pod &comment &podcomment);
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = qw();
}
our @EXPORT_OK;

END { }

my $pod_re = qr{^=\w+(?s:.*?)(?:\Z|^=cut[ \t]*\n)}m;
my $comment_re = qr{^(?:[ \t]*#.*\n)+}m;

sub pod {
    my @list;
    while (/$pod_re/g) {
	push(@list, [ $-[0], $+[0] ] );
    }
    @list;
}
sub comment {
    my @list;
    while (/$comment_re/g) {
	push(@list, [ $-[0], $+[0] ] );
    }
    @list;
}

sub podcomment {
    my @list;
    while (/$pod_re|$comment_re/g) {
	push(@list, [ $-[0], $+[0] ] );
    }
    @list;
}

1;

__DATA__

define :comment: ^([ \t]*#.*\n)+
#define :comment: #.*
define :pod: ^=(?s:.*?)(?:\Z|^=cut[ \t]*\n)
define :podcomment: :pod:|:comment:

option --allsection --pod --comment --code

option --pod --inside :pod:
option --comment --inside :comment:
option --code --outside :podcomment:

#option --pod --inside '&pod'
#option --comment --inside '&comment'
#option --code --outside '&podcomment'
