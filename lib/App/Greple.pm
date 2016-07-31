package App::Greple;

use strict;
use warnings;

=head1 NAME

App::Greple

=head1 VERSION

Version 6.24

=cut

our $VERSION = '6.24';


=head1 SYNOPSIS

    package App::Greple::perl;
    
    BEGIN {
        use Exporter   ();
        our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    
        $VERSION = sprintf "%d.%03d", q$Revision: 6.24 $ =~ /(\d+)/g;
    
        @ISA         = qw(Exporter);
        @EXPORT      = qw(&pod &comment &podcomment);
        %EXPORT_TAGS = ( );
        @EXPORT_OK   = qw();
    }
    our @EXPORT_OK;
    
    END { }
    
    my $pod_re = qr{^=\w+(?s:.*?)(?:\Z|^=cut\s*\n)}m;
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
    
    define :comment: ^(\s*#.*\n)+
    define :pod: ^=(?s:.*?)(?:\Z|^=cut\s*\n)
    
    #option --pod --inside :pod:
    #option --comment --inside :comment:
    #option --code --outside :pod:|:comment:
    
    option --pod --inside '&pod'
    option --comment --inside '&comment'
    option --code --outside '&podcomment'

You can use the module like this:

    greple -Mperl --pod default greple

    greple -Mperl --colorful --code --comment --pod default greple

If special subroutine **getopt()** is defined in the module, it is
called at the beginning with `@ARGV` contents.  Actual `@ARGV` is
replaced by the result of **getopt()**.  See **find** module as a
sample.


=head1 AUTHOR

Kazumasa Utashiro

=head1 ACKNOWLEDGEMENTS



=head1 LICENSE AND COPYRIGHT

Copyright (c) 1991-2014 Kazumasa Utashiro

Use and redistribution for ANY PURPOSE are granted as long as all copyright notices are retained. Redistribution with modification is allowed provided that you make your modified version obviously distinguishable from the original one. THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.

=cut

1; # End of App::Greple
