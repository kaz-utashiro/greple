package App::Greple;

use strict;
use warnings;

=head1 NAME

App::Greple

=head1 VERSION

Version 7.2

=cut

our $VERSION = '7.2';

=head1 SYNOPSIS

B<greple> [B<-M>I<module>] [ B<-options> ] pattern [ file... ]

  PATTERN
    pattern              'and +must -not ?alternative &function'
    -e pattern           regex pattern match across line boundary
    -r pattern           regex pattern cannot be compromised
    -v pattern           regex pattern not to be matched
    --le pattern         lexical expression (same as bare pattern)
    --re pattern         regular expression
    --fe pattern         fixed expression
    --file file          file contains search pattern
  MATCH
    -i                   ignore case
    --need=[+-]n         required positive match count
    --allow=[+-]n        acceptable negative match count
  STYLE
    -l                   list filename only
    -c                   print count of matched block only
    -n                   print line number
    -h                   do not display filenames
    -H                   always display filenames
    -o                   print only the matching part
    -A[n]                after match context
    -B[n]                before match context
    -C[n]                after and before match context
    --join               delete newline in the matched part
    --joinby=string      replace newline in the matched text by string
    --filestyle=style    how filename printed (once, separate, line)
    --linestyle=style    how line number printed (separate, line)
    --separate           set filestyle and linestyle both "separate"
  FILE
    --glob=glob          glob target files
    --chdir              change directory before search
    --readlist           get filenames from stdin
  COLOR
    --color=when         use terminal color (auto, always, never)
    --nocolor            same as --color=never
    --colormap=color     R, G, B, C, M, Y etc.
    --colorful           use default multiple colors
    --ansicolor=s        ANSI color 16, 256 or 24bit
    --[no]256            same as --ansicolor 256 or 16
    --regioncolor        use different color for inside/outside regions
    --uniqcolor          use different color for unique string
    --random             use random color each time
    --face               set/unset vidual effects
  BLOCK
    -p                   paragraph mode
    --all                print whole data
    --block=pattern      specify the block of records
    --blockend=s         specify the block end mark (Default: "--\n")
  REGION
    --inside=pattern     select matches inside of pattern
    --outside=pattern    select matches outside of pattern
    --include=pattern    reduce matches to the area
    --exclude=pattern    reduce matches to outside of the area
    --strict             strict mode for --inside/outside --block
  CHARACTER CODE
    --icode=name         specify file encoding
    --ocode=name         specify output encoding
  FILTER
    --if=filter          input filter command
    --of=filter          output filter command
    --pf=filter          post process filter command
    --noif               disable default input filter
  RUNTIME FUNCTION
    --print=func         print function
    --continue           continue after print function
    --begin=func         call function before search
    --end=func           call function after search
  OTHER
    --norc               skip reading startup file
    --man                display command or module manual page
    --show               display module file
    -d flags             display info (f:file d:dir c:color m:misc s:stat)


=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE AND COPYRIGHT

Copyright (c) 1991-2017 Kazumasa Utashiro

Use and redistribution for ANY PURPOSE are granted as long as all copyright notices are retained. Redistribution with modification is allowed provided that you make your modified version obviously distinguishable from the original one. THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.

=cut

1; # End of App::Greple
