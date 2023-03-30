[![Actions Status](https://github.com/kaz-utashiro/greple/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple.svg)](https://metacpan.org/release/App-Greple)
# NAME

greple - extensible grep with lexical expression and region control

# VERSION

Version 9.04

# SYNOPSIS

**greple** \[**-M**_module_\] \[ **-options** \] pattern \[ file... \]

    PATTERN
      pattern              'and +must -not ?optional &function'
      -x, --le   pattern   lexical expression (same as bare pattern)
      -e, --and  pattern   pattern match across line boundary
      -r, --must pattern   pattern cannot be compromised
      -t, --may  pattern   pattern may be exist
      -v, --not  pattern   pattern not to be matched
          --re   pattern   regular expression
          --fe   pattern   fixed expression
      -f, --file file      file contains search pattern
      --select index       select indexed pattern from -f file
    MATCH
      -i                   ignore case
      --need=[+-]n         required positive match count
      --allow=[+-]n        acceptable negative match count
      --matchcount=n[,m]   required match count for each block
    STYLE
      -l                   list filename only
      -c                   print count of matched block only
      -n                   print line number
      -H, -h               do or do not display filenames
      -o                   print only the matching part
      --all                print entire data
      -m, --max=n[,m]      max count of blocks to be shown
      -A,-B,-C [n]         after/before/both match context
      --join               delete newline in the matched part
      --joinby=string      replace newline in the matched text by string
      --nonewline          do not add newline character at block end
      --filestyle=style    how filename printed (once, separate, line)
      --linestyle=style    how line number printed (separate, line)
      --separate           set filestyle and linestyle both "separate"
      --format LABEL=...   define line number and file name format
      --frame-top          top frame
      --frame-middle       middle frame
      --frame-bottom       bottom frame
    FILE
      --glob=glob          glob target files
      --chdir=dir          change directory before search
      --readlist           get filenames from stdin
    COLOR
      --color=when         use terminal color (auto, always, never)
      --nocolor            same as --color=never
      --colormap=color     R, G, B, C, M, Y etc.
      --colorsub=...       shortcut for --colormap="sub{...}"
      --colorful           use default multiple colors
      --colorindex=flags   color index method: Ascend/Descend/Block/Random
      --ansicolor=s        ANSI color 16, 256 or 24bit
      --[no]256            same as --ansicolor 256 or 16
      --regioncolor        use different color for inside/outside regions
      --uniqcolor          use different color for unique string
      --uniqsub=func       preprocess function before check uniqueness
      --random             use random color each time
      --face               set/unset visual effects
    BLOCK
      -p, --paragraph      paragraph mode
      --border=pattern     border pattern
      --block=pattern      block of records
      --blockend=s         block end mark (Default: "--")
      --join-blocks        join back-to-back consecutive blocks
    REGION
      --inside=pattern     select matches inside of pattern
      --outside=pattern    select matches outside of pattern
      --include=pattern    reduce matches to the area
      --exclude=pattern    reduce matches to outside of the area
      --strict             strict mode for --inside/outside --block
    CHARACTER CODE
      --icode=name         file encoding
      --ocode=name         output encoding
    FILTER
      --if,--of=filter     input/output filter command
      --pf=filter          post process filter command
      --noif               disable default input filter
    RUNTIME FUNCTION
      --print=func         print function
      --continue           continue after print function
      --callback=func      callback function for matched string
      --begin=func         call function before search
      --end=func           call function after search
      --prologue=func      call function before command execution
      --epilogue=func      call function after command execution
      --postgrep=func      call function after each grep operation
    OTHER
      --usage[=expand]     show this message
      --exit=n             command exit status
      --norc               skip reading startup file
      --man                display command or module manual page
      --show               display module file
      --path               show module file path
      --persist            same as --error=retry
      --error=action       action after read error
      --warn=type          run time error control
      --alert [name=#]     set alert parameter (size/time)
      -d flags             display info (f:file d:dir c:color m:misc s:stat)

# INSTALL

## CPANMINUS

    $ cpanm App::Greple

# DESCRIPTION

## MULTIPLE KEYWORDS

### AND

**greple** can take multiple search patterns with the `-e` option, but
unlike the [egrep(1)](http://man.he.net/man1/egrep) command, it will search them in AND context.
For example, the next command print lines those containing all of
`foo` and `bar` and `baz`.

    greple -e foo -e bar -e baz ...

Each word can appear in any order and any place in the string.  So
this command find all of following lines.

    foo bar baz
    baz bar foo
    the foo, bar and baz

If you want to use OR syntax, use regular expression.

    greple -e foo -e bar -e baz -e 'yabba|dabba|doo'

This command will print lines those contains all of `foo`, `bar` and
`baz` and one or more of `yabba`, `dabba` or `doo`.

### NOT

Use option `-v` to specify keyword which should not found in the data
record.  Next example will show lines those contain both `foo` and
`bar` but none of `yabba`, `dabba` or `doo`.

    greple -e foo -e bar -v yabba -v dabba -v doo
    greple -e foo -e bar -v 'yabba|dabba|doo'

### MAY

When you are focusing on multiple words, there may be words those are
not necessary but would be of interest if there were.

Use option `--may` or `-t` (tentative) to specify that kind of
words.  They will be a subject of search, and highlighted if exist,
but are optional.

Next command print all lines including `foo` and `bar`, and
highlight `baz` as well.

    greple -e foo -e bar -t baz

### MUST

Option `--must` or `-r` is another way to specify optional keyword.
If required keyword exists, all other positive match keyword becomes
optional.  Next command is equivalent to the above example.

    greple -r foo -r bar -e baz

## LEXICAL EXPRESSION

**greple** takes the first argument as a search pattern specified by
`--le` option.  In the `--le` pattern, you can set multiple keywords
in a single parameter.  Each keyword is separated by spaces, and the
first letter describes its type.

    none  And pattern            : --and  -e
    +     Required pattern       : --must -r
    -     Negative match pattern : --not  -v
    ?     Optional pattern       : --may  -t

Just like internet search engines, you can simply provide `foo bar
baz` to search lines including all of them.

    greple 'foo bar baz'

Next command show lines which include `foo`, but does not include
`bar`, and highlight `baz` if exists.

    greple 'foo -bar ?baz'

## PHRASE SEARCH

**greple** searches a given pattern across line boundaries.  This is
especially useful to handle Asian multi-byte text, more specifically
Japanese.  Japanese text can be separated by newline almost any place
in the text.  So the search pattern may spread out onto multiple
lines.

As for ascii word list, space character in the pattern matches any
kind of space including newline.  Next example will search the word
sequence of `foo`, `bar` and `baz`, even they spread out to
multiple lines.

    greple -e 'foo bar baz'

Option `-e` is necessary because space is taken as a token separator
in the bare or `--le` pattern.

## FLEXIBLE BLOCKS

Default data block **greple** search and print is a line.  Using
`--paragraph` (or `-p` in short) option, series of text separated by
empty line is taken as a record block.  So next command will print
whole paragraph which contains the word `foo`, `bar` and `baz`.

    greple -p 'foo bar baz'

Block also can be defined by pattern.  Next command treat the data as
a series of 10-line unit.

    greple -n --border='(.*\n){1,10}'

You can also define arbitrary complex blocks by writing script.

    greple --block '&your_original_function' ...

## MATCH AREA CONTROL

Using option `--inside` and `--outside`, you can specify the text
area to be matched.  Next commands search only in mail header and body
area respectively.  In these cases, data block is not changed, so
print lines which contains the pattern in the specified area.

    greple --inside '\A(.+\n)+' pattern

    greple --outside '\A(.+\n)+' pattern

Option `--inside`/`--outside` can be used repeatedly to enhance the
area to be matched.  There are similar option
`--include`/`--exclude`, but they are used to trim down the area.

These four options also take user defined function and any complex
region can be used.

## MODULE AND CUSTOMIZATION

User can define default and original options in `~/.greplerc`.  Next
example enables colored output always, and define new option using
macro processing.

    option default --color=always

    define :re1 complex-regex-1
    define :re2 complex-regex-2
    define :re3 complex-regex-3
    option --newopt --inside :re1 --exclude :re2 --re :re3

Specific set of function and option interface can be implemented as
module.  Modules are invoked by `-M` option immediately after command
name.

For example, **greple** does not have recursive search option, but it
can be implemented by `--readlist` option which accept target file
list from standard input.  Using **find** module, it can be written
like this:

    greple -Mfind . -type f -- pattern

Also **dig** module implements more complex search.  It can be used as
simple as this:

    greple -Mdig pattern --dig .

but this command is finally translated into following option list.

    greple -Mfind . ( -name .git -o -name .svn -o -name RCS ) -prune -o
        -type f ! -name .* ! -name *,v ! -name *~
        ! -iname *.jpg ! -iname *.jpeg ! -iname *.gif ! -iname *.png
        ! -iname *.tar ! -iname *.tbz  ! -iname *.tgz ! -iname *.pdf
        -print -- pattern

## INCLUDED MODUES

This release include some sample modules.  Read document in each
modules for detail.  You can read the document by `--man` option or
[perldoc](https://metacpan.org/pod/perldoc) command.

    greple -Mdig --man

    perldoc App::Greple::dig

When it does not work, use `perldoc App::Greple::dig`.

- **colors**

    Color variation module.
    See [App::Greple::colors](https://metacpan.org/pod/App%3A%3AGreple%3A%3Acolors).

- **find**

    Module to use [find(1)](http://man.he.net/man1/find) command to help recursive search.
    See [App::Greple::find](https://metacpan.org/pod/App%3A%3AGreple%3A%3Afind).

- **dig**

    Module for recursive search using **find** module.  Defines `--dig`,
    `--git` and `--git-r` options. See [App::Greple::dig](https://metacpan.org/pod/App%3A%3AGreple%3A%3Adig).

- **pgp**

    Module to search **pgp** files.
    See [App::Greple::pgp](https://metacpan.org/pod/App%3A%3AGreple%3A%3Apgp).

- **select**

    Module to select files.
    See [App::Greple::select](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aselect).

- **perl**

    Sample module to search from perl source files.
    See [App::Greple::perl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aperl).

Other modules are available at CPAN, or git repository
[https://github.com/kaz-utashiro/](https://github.com/kaz-utashiro/).

# OPTIONS

## PATTERNS

If no specific option is given, **greple** takes the first argument as
a search pattern specified by `--le` option.  All of these patterns
can be specified multiple times.

Command itself is written in Perl, and any kind of Perl style regular
expression can be used in patterns.  See [perlre(1)](http://man.he.net/man1/perlre) for detail.

Note that multiple line modifier (`m`) is set when executed, so put
`(?-m)` at the beginning of regex if you want to explicitly disable
it.

Order of capture group in the pattern is not guaranteed.  Please avoid
to use direct index, and use relative or named capture group instead.
For example, if you want to search repeated characters, use
`(\w)\g{-1}` or `(?<c>\w)\g{c}` rather than
`(\w)\1`.

- **-e** _pattern_, **--and**=_pattern_

    Specify the positive match pattern.  Next command print lines contains
    all of `foo`, `bar` and `baz`.

        greple -e foo -e bar -e baz

- **-t** _pattern_, **--may**=_pattern_

    Specify the optional (tentative) match pattern.  Next command print
    lines contains `foo` and `bar`, and highlight `baz` if exists.

        greple -e foo -e bar -t baz

- **-r** _pattern_, **--must**=_pattern_

    Specify the required match pattern.  If one or more required pattern
    exist, other positive match pattern becomes optional.

        greple -r foo -r bar -e baz

    Because `-t` promote all other `-e` patterns required, next command
    do the same thing.  Mixing `-r`, `-e` and `-t` is not recommended,
    though.

        greple -r foo -e bar -t baz

- **-v** _pattern_, **--not**=_pattern_

    Specify the negative match pattern.  Because it does not affect to the
    bare pattern argument, you can narrow down the search result like
    this.

        greple foo file
        greple foo file -v bar
        greple foo file -v bar -v baz

In the above pattern options, space characters are treated specially.
They are replaced by the pattern which matches any number of white
spaces including newline.  So the pattern can expand to multiple
lines.  Next commands search the series of word `foo` `bar` `baz`
even if they are separated by newlines.

    greple -e 'foo bar baz'

This is done by converting pattern `foo bar baz` to
`foo\s+bar\+baz`, so that word separator can match one or more white
spaces.

As for Asian wide characters, pattern is cooked as zero or more white
spaces can be allowed between any characters.  So Japanese string
pattern `日本語` will be converted to `日\s*本\s*語`.

If you don't want these conversion, use `--re` option.

- **-x** _pattern_, **--le**=_pattern_

    Treat the pattern string as a collection of tokens separated by
    spaces.  Each token is interpreted by the first character.  Token
    start with `-` means **negative** pattern, `?` means **optional**, and
    `+` does **required**.

    Next example print lines which contain `foo` and `yabba`, and none
    of `bar` and `dabba`, with highlighting `baz` and `doo` if they
    exist.

        greple --le='foo -bar ?baz yabba -dabba ?doo'

    This is the summary of start character for `--le` option:

        +  Required pattern
        -  Negative match pattern
        ?  Optional pattern
        &  Function call (see next section)

- `-x` \[**+?-**\]**&**_function_, `--le`=\[**+?-**\]**&**_function_

    If the pattern start with ampersand (`&`), it is treated as a
    function, and the function is called instead of searching pattern.
    Function call interface is same as the one for block/region options.

    If you have a definition of _odd\_line_ function in you `.greplerc`,
    which is described in this manual later, you can print odd number
    lines like this:

        greple -n '&odd_line' file

    Required (`+`), optional (`?`) and negative (`-`) mark can be used
    for function pattern.

    **CALLBACK FUNCTION**: Region list returned by function can have two
    extra elements besides start/end position.  Third element is index.
    Fourth element is a callback function pointer which will be called to
    produce string to be shown in command output.  Callback function is
    called with four arguments (start position, end position, index,
    matched string) and expected to return replacement string.

- **--re**=_pattern_

    Specify regular expression.  No special treatment for space and wide
    characters.

- **--fe**=_pattern_

    Specify the fixed string pattern, like fgrep.

- **-i**, **--ignore-case**

    Ignore case.

- **--need**=_n_
- **--allow**=_n_

    Option to compromise matching condition.  Option `--need` specifies
    the required match count, and `--allow` the number of negative
    condition to be overlooked.

        greple --need=2 --allow=1 'foo bar baz -yabba -dabba -doo'

    Above command prints the line which contains two or more from `foo`,
    `bar` and `baz`, and does not include more than one of `yabba`,
    `dabba` or `doo`.

    Using option `--need=1`, **greple** produces same result as **grep**
    command.

        grep   -e foo -e bar -e baz
        greple -e foo -e bar -e baz --need=1

    When the count _n_ is negative value, it is subtracted from default
    value.

    If the option `--need=0` is specified and no pattern was found,
    entire data is printed.  This is true even for required pattern.

- **--matchcount**=_count_ **--mc**=...
- **--matchcount**=_min_,_max_ **--mc**=...

    When option `--matchcount` is specified, only blocks which have given
    match count will be shown.  Minimum and maximum number can be given,
    connecting by comma, and they can be omitted.  Next commands print
    lines including semicolons; 3 or more, exactly 3, and 3 or less,
    respectively.

        greple --matchcount=3, ';' file

        greple --matchcount=3  ';' file

        greple --matchcount=,3 ';' file

    In fact, _min_ and _max_ can repeat to represent multiple range.
    Missing, negative or zero _max_ means infinite.  Next command find
    match count 0 to 10, 20 to 30, and 40-or-greater.

        greple --matchcount=,10,20,30,40

- **-f** _file_, **--file**=_file_

    Specifies the file containing the search pattern. If there are
    multiple lines in the file, each pattern is combined by an OR context.
    So the file:

        A
        B
        C

    makes the pattern as `A|B|C`.

    Blank line and the line starting with sharp (#) character is ignored.
    Two slashes (//) and following string are taken as a comment and
    removed with preceding spaces.

    In more detail, each of these patterns are evaluated under `(?^m)`
    flags.  This is a situation where only the `m` (Multiline) flag is
    enabled in the default environment. So if you enable some flags in a
    pattern, they are only valid within itself.

    If multiple files are specified, a separate group pattern is generated
    for each file.

    If the file name is followed by `[index]` string, it is treated as
    specified by `--select` option.  Next two commands are equivalent.

        greple -f pattern_file'[2,7:9]'

        greple -f pattern_file --select 2,7:9

    See [App::Greple::subst](https://metacpan.org/pod/App%3A%3AGreple%3A%3Asubst) module.

- **--select**=_index_

    When you want to choose specific line in the pattern file provided by
    `-f` option, use `--select` option.  _index_ is number list
    separated by comma (,) character and each number is interpreted by
    [Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers) module.  Take a look at the module document for
    detail.

    Next command use 2nd and 7,8,9th lines in the pattern file.

        greple -f pattern_file --select 2,7:9

## STYLES

- **-l**

    List filename only.

- **-c**, **--count**

    Print count of matched block.

- **-n**, **--line-number**

    Show line number.

- **-h**, **--no-filename**

    Do not display filename.

- **-H**

    Display filename always.

- **-o**, **--only-matching**

    Print matched string only.  Newline character is printed after matched
    string if it does not end with newline.  Use `--no-newline` option if
    you don't need extra newline.

- **--all**

    Print entire file.  This option does not affect to seach behavior or
    block treatment.  Just print all contents.

- **-m** _n_\[,_m_\], **--max-count**=_n_\[,_m_\]

    Set the maximum count of blocks to be shown to _n_.

    Actually _n_ and _m_ are simply passed to perl [splice](https://metacpan.org/pod/splice) function as
    _offset_ and _length_.  Works like this:

        greple -m  10      # get first 10 blocks
        greple -m   0,-10  # get last 10 blocks
        greple -m   0,10   # remove first 10 blocks
        greple -m -10      # remove last 10 blocks
        greple -m  10,10   # remove 10 blocks from 10th (10-19)

    This option does not affect to search performance and command exit
    status.

    Note that **grep** command also has same option, but it's behavior is
    different when invoked to multiple files.  **greple** produces given
    number of output for each file, while **grep** takes it as a total
    number of output.

- **-m** _\*_, **--max-count**=_\*_

    In fact, _n_ and _m_ can repeat as many as possible.  Next example
    removes first 10 blocks (by `0,10`), then get first 10 blocks from
    the result (by `10`).  Consequently, get 10 blocks from 10th (10-19).

        greple -m 0,10,10

    Next command get first 20 (by `20,`) and get last 10 (by `,-10`),
    producing same result.  Empty string behaves like absence for
    _length_ and zero for _offset_.

        greple -m 20,,,-10

- **-A**\[_n_\], **--after-context**\[=_n_\]
- **-B**\[_n_\], **--before-context**\[=_n_\]
- **-C**\[_n_\], **--context**\[=_n_\]

    Print _n_-blocks before/after matched string.  The value _n_ can be
    omitted and the default is 2.  When used with `--paragraph` or
    `--block` option, _n_ means number of paragraph or block.

    Actually, these options expand the area of logical operation.  It
    means

        greple -C1 'foo bar baz'

    matches following text.

        foo
        bar
        baz

    Moreover

        greple -C1 'foo baz'

    also matches this text, because matching blocks around `foo` and
    `bar` overlaps each other and makes single block.

- **--join**
- **--joinby**=_string_

    Convert newline character found in matched string to empty or specified
    _string_.  Using `--join` with `-o` (only-matching) option, you can
    collect searching sentence list in one per line form.  This is
    sometimes useful for Japanese text processing.  For example, next
    command prints the list of KATAKANA words, including those spread
    across multiple lines.

        greple -ho --join '\p{InKatakana}+(\n\p{InKatakana}+)*'

    Space separated word sequence can be processed with `--joinby`
    option.  Next example prints all `for *something*` pattern in pod
    documents within Perl script.

        greple -Mperl --pod -ioe '\bfor \w+' --joinby ' '

- **--\[no\]newline**

    Since **greple** can handle arbitrary blocks other than normal text
    lines, they sometimes do not end with newline character.  Option `-o`
    makes similar situation.  In that case, extra newline is appended at
    the end of block to be shown.  Option `--no-newline` disables this
    behavior.

- **--filestyle**=\[`line`,`once`,`separate`\], **--fs**

    Default style is _line_, and **greple** prints filename at the
    beginning of each line.  Style _once_ prints the filename only once
    at the first time.  Style _separate_ prints filename in the separate
    line before each line or block.

- **--linestyle**=\[`line`,`separate`\], **--ls**

    Default style is _line_, and **greple** prints line numbers at the
    beginning of each line.  Style _separate_ prints line number in the
    separate line before each line or block.

- **--separate**

    Shortcut for `--filestyle=separate` `--linestyle=separate`.
    This is convenient to use block mode search and visiting each location
    from supporting tool, such as Emacs.

- **--format** **LABEL**=_format_

    Define the format string of line number (LINE) and file name (FILE) to
    be displayed.  Default is:

        --format LINE='%d:'

        --format FILE='%s:'

    Format string is passed to `sprintf` function.  Tab character can be
    expressed as `\t`.

    Next example will show line numbers in five digits with tab space:

        --format LINE='%05d\t'

- **--frame-top**=_string_
- **--frame-middle**=_string_
- **--frame-bottom**=_string_

    Print surrounding frames before and after each block.  `top` frame is
    printed at the beginning, `bottom` frame at the end, `middle` frame
    between blocks.

## FILES

- **--glob**=_pattern_

    Get files matches to specified pattern and use them as a target files.
    Using `--chdir` and `--glob` makes easy to use **greple** for fixed
    common job.

- **--chdir**=_directory_

    Change directory before processing files.  When multiple directories
    are specified in `--chdir` option, by using wildcard form or
    repeating option, `--glob` file expansion will be done for every
    directories.

        greple --chdir '/usr/man/man?' --glob '*.[0-9]' ...

- **--readlist**

    Get filenames from standard input.  Read standard input and use each
    line as a filename for searching.  You can feed the output from other
    command like [find(1)](http://man.he.net/man1/find) for **greple** with this option.  Next example
    searches string from files modified within 7 days:

        find . -mtime -7 -print | greple --readlist pattern

    Using **find** module, this can be done like:

        greple -Mfind . -mtime -7 -- pattern

## COLORS

- **--color**=\[`auto`,`always`,`never`\], **--nocolor**

    Use terminal color capability to emphasize the matched text.  Default
    is `auto`: effective when STDOUT is a terminal and option `-o` is
    not given, not otherwise.  Option value `always` and `never` will
    work as expected.

    Option **--nocolor** is alias for **--color**=_never_.

    When color output is disabled, ANSI terminal sequence is not produced,
    but functional colormap, such as `--cm sub{...}`, still works.

- **--colormap**=_spec_, **--cm**=...

    Specify color map.  Because this option is mostly implemented by
    [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap) module, consult its document for detail and
    up-to-date specification.

    Color specification is combination of single uppercase character
    representing basic colors, and (usually brighter) alternative colors in
    lowercase:

        R  r   Red
        G  g   Green
        B  b   Blue
        C  c   Cyan
        M  m   Magenta
        Y  y   Yellow
        K  k   Black
        W  w   White

    or RGB value and 24 grey levels if using ANSI 256 color terminal:

        (255,255,255)      : 24bit decimal RGB colors
        #000000 .. #FFFFFF : 24bit hex RGB colors
        #000    .. #FFF    : 12bit hex RGB 4096 colors
        000 .. 555         : 6x6x6 RGB 216 colors
        L00 .. L25         : Black (L00), 24 grey levels, White (L25)

    >     Beginning # can be omitted in 24bit RGB notation.
    >
    >     When values are all same in 24bit or 12bit RGB, it is converted to 24
    >     grey level, otherwise 6x6x6 216 color.

    or color names enclosed by angle bracket:

        <red> <blue> <green> <cyan> <magenta> <yellow>
        <aliceblue> <honeydue> <hotpink> <mooccasin>
        <medium_aqua_marine>

    with other special effects:

        N    None
        Z  0 Zero (reset)
        D  1 Double strike (boldface)
        P  2 Pale (dark)
        I  3 Italic
        U  4 Underline
        F  5 Flash (blink: slow)
        Q  6 Quick (blink: rapid)
        S  7 Stand out (reverse video)
        H  8 Hide (concealed)
        X  9 Cross out
        E    Erase Line

        ;    No effect
        /    Toggle foreground/background
        ^    Reset to foreground

    If the spec includes `/`, left side is considered as foreground color
    and right side as background.  If multiple colors are given in same
    spec, all indicators are produced in the order of their presence.  As
    a result, the last one takes effect.

    Effect characters are case insensitive, and can be found anywhere and
    in any order in color spec string.  Character `;` does nothing and
    can be used just for readability, like `SD;K/544`.

    Example:

        RGB  6x6x6    12bit      24bit           color name
        ===  =======  =========  =============  ==================
        B    005      #00F       (0,0,255)      <blue>
         /M     /505      /#F0F   /(255,0,255)  /<magenta>
        K/W  000/555  #000/#FFF  000000/FFFFFF  <black>/<white>
        R/G  500/050  #F00/#0F0  FF0000/00FF00  <red>/<green>
        W/w  L03/L20  #333/#ccc  303030/c6c6c6  <dimgrey>/<lightgrey>

    Multiple colors can be specified separating by white space or comma,
    or by repeating options.  Those colors will be applied for each
    pattern keywords.  Next command will show word `foo` in red, `bar`
    in green and `baz` in blue.

        greple --colormap='R G B' 'foo bar baz'

        greple --cm R -e foo --cm G -e bar --cm B -e baz

    Coloring capability is implemented in [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap) module.

- **--colormap**=_field_=_spec_,...

    Another form of colormap option to specify the color for fields:

        FILE      File name
        LINE      Line number
        TEXT      Unmatched normal text
        BLOCKEND  Block end mark
        PROGRESS  Progress status with -dnf option

    In current release, `BLOCKEND` mark is colored with `E` effect
    recently implemented in [Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX) module, which allows to fill up
    the line with background color.  This effect uses irregular escape
    sequence, and you may need to define `LESSANSIENDCHARS` environment
    as "mK" to see the result with [less](https://metacpan.org/pod/less) command.

- **--colormap**=`&func`
- **--colormap**=`sub{...}`

    You can also set the name of perl subroutine name or definition to be
    called handling matched words.  Target word is passed as variable
    `$_`, and the return value of the subroutine will be displayed.

    Next command convert all words in C comment to upper case.

        greple --all '/\*(?s:.*?)\*/' --cm 'sub{uc}'

    You can quote matched string instead of coloring (this emulates
    deprecated option `--quote`):

        greple --cm 'sub{"<".$_.">"}' ...

    It is possible to use this definition with field names.  Next example
    print line numbers in seven digits.

        greple -n --cm 'LINE=sub{s/(\d+)/sprintf("%07d",$1)/e;$_}'

    Experimentally, function can be combined with other normal color
    specifications.  Also the form `&func;` can be repeated.

        greple --cm 'BF/544;sub{uc}'

        greple --cm 'R;&func1;&func2;&func3'

    When color for 'TEXT' field is specified, whole text including matched
    part is passed to the function, exceptionally.  It is not recommended
    to use user defined function for 'TEXT' field.

- **--colorsub**=`...`, **--cs**=`...`

    `--colorsub` or `--cs` is a shortcut for subroutine colormap.  It
    simply enclose the argument by `sub{ ... }` expression.  So

        greple -cm 'sub{uc}'

    can be written as simple as this.

        greple -cs uc

    You can not use this option for labeled color.

- **--\[no\]colorful**

    Shortcut for `--colormap`='`RD GD BD CD MD YD`' in ANSI 16 colors
    mode, and `--colormap`='`D/544 D/454 D/445 D/455 D/454 D/554`' and
    other combination of 3, 4, 5 for 256 colors mode.  Enabled by default.

    When single pattern is specified, first color in colormap is used for
    the pattern.  If multiple patterns and multiple colors are specified,
    each pattern is colored with corresponding color cyclically.

    Option `--regioncolor`, `--uniqcolor` and `--colorindex` change
    this behavior.

- **--colorindex**=_spec_, **--ci**=_spec_

    Specify color index method by combination of spec characters.  **A**
    (ascend) and **D** (descend) can be mixed with **B** (block) and/or **S**
    (shuffle) like `--ci=ABS`.  **R** (random) can be too but it does not
    make sense.  When **S** is used alone, colormap is shuffled with normal
    behavior.

    - A (Ascending)

        Apply different color sequentially according to the order of
        appearance.

    - D (Descending)

        Apply different color sequentially according to the reverse order of
        appearance.

    - B (Block)

        Reset sequential index on every block.

    - S (Shuffle)

        Shuffle indexed color.

    - R (Random)

        Use random color index every time.

    - N (Normal)

        Reset to normal behavior.  Because the last option takes effect,
        `--ci=N` can be used to reset the behavior set by previous options.

- **--random**

    Shortcut for `--colorindex=R`.

- **--ansicolor**=\[`16`,`256`,`24bit`\]

    If set as `16`, use ANSI 16 colors as a default color set, otherwise
    ANSI 256 colors.  When set as `24bit`, 6 hex digits notation produces
    24bit color sequence.  Default is `256`.

- **--\[no\]256**

    Shortcut for `--ansicolor`=`256` or `16`.

- **--\[no\]regioncolor**, **--\[no\]rc**

    Use different colors for each `--inside` and `--outside` region.

    Disabled by default, but automatically enabled when only single search
    pattern is specified.  Use `--no-regioncolor` to cancel automatic
    action.

- **--\[no\]uniqcolor**, **--\[no\]uc**

    Use different colors for different string matched.
    Disabled by default.

    Next example prints all words start by `color` and display them all
    in different colors.

        greple --uniqcolor 'colou?r\w*'

    When used with option `-i`, color is selected still in case-sensitive
    fashion.  If you want case-insensitive color selection, use next
    `--uniqsub` option.

- **--uniqsub**=_function_, **--us**=_function_

    Above option `--uniqcolor` set same color for same literal string.
    Option `--uniqsub` specify the preprocessor code applied before
    comparison.  _function_ get matched string by `$_` and returns the
    result.  For example, next command will choose unique colors for each
    word by their length.

        greple --uniqcolor --uniqsub 'sub{length}' '\w+' file

    If you want case-insensitive color selection, do like this.

        greple -i pattern --uc --uniqsub 'sub{lc}'

    Next command read the output from `git blame` command and set unique
    color for each entire line by their commit ids.

        git blame ... | greple .+ --uc --us='sub{s/\s.*//r}' --face=E-D

- **--face**=\[-+\]_effect_

    Set or unset specified _effect_ for all indexed color specs.  Use
    `+` (optional) to set, and `-` to unset.  Effect is a single
    character expressing S (Stand-out), U (Underline), D (Double-struck),
    F (Flash) and such.

    Next example remove D (double-struck) effect.

        greple --face -D

    Multiple effects can be set/unset at once.

        greple --face SF-D

## BLOCKS

- **-p**, **--paragraph**

    Print a paragraph which contains the pattern.  Each paragraph is
    delimited by two or more successive newlines by default.  Be aware
    that an empty line is not a paragraph delimiter if which contains
    space characters.  Example:

        greple -np 'setuid script' /usr/man/catl/perl.l

        greple -pe '^struct sockaddr' /usr/include/sys/socket.h

    It changes the unit of context specified by `-A`, `-B`, `-C`
    options.  Space gap between paragraphs are also treated as a block
    unit.  Thus, option `-pC2` will print target paragraph along with
    previous and next paragraph.  Option `-pC1` causes consecutive
    paragraphs to be output as the same block in an easy-to-read format.

    You can create original paragraph pattern by `--border` option.

- **--border**=_pattern_

    Specify record block border pattern.  Pattern match is done in the
    context of multiple line mode.

    Default block is a single line and use `/^/m` as a pattern.
    Paragraph mode uses `/(?:\A|\R)\K\R+/`, which means continuous
    newlines at the beginning of text or following another newline (`\R`
    means more general linebreaks including `\r\n`; consult
    [perlrebackslash](https://metacpan.org/pod/perlrebackslash) for detail).

    Next command treat the data as a series of 10-line unit.

        greple -n --border='(.*\n){1,10}'

    Contrary to the next `--block` option, `--border` never produce
    disjoint records.

    If you want to treat entire file as a single block, setting border to
    start or end of whole data is efficient way.  Next commands works
    same.

        greple --border '\A'    # beginning of file
        greple --border '\z'    # end of file

- **--block**=_pattern_
- **--block**=_&sub_

    Specify the record block to display.  Default block is a single line.

    Empty blocks are ignored.  When blocks are not continuous, the match
    occurred outside blocks are ignored.

    If multiple block options are given, overlapping blocks are merged
    into a single block.

    Please be aware that this option is sometimes quite time consuming,
    because it finds all blocks before processing.

- **--blockend**=_string_

    Change the end mark displayed after `-pABC` or `--block` options.
    Default value is "--".

- **--join-blocks**

    Join consecutive blocks together.  Logical operation is done for each
    individual blocks, but if the results are back-to-back connected, make
    them single block for final output.

## REGIONS

- **--inside**=_pattern_
- **--outside**=_pattern_

    Option `--inside` and `--outside` limit the text area to be matched.
    For simple example, if you want to find string `and` not in the word
    `command`, it can be done like this.

        greple --outside=command and

    The block can be larger and expand to multiple lines.  Next command
    searches from C source, excluding comment part.

        greple --outside '(?s)/\*.*?\*/'

    Next command searches only from POD part of the perl script.

        greple --inside='(?s)^=.*?(^=cut|\Z)'

    When multiple **inside** and **outside** regions are specified, those
    regions are mixed up in union way.

    In multiple color environment, and if single keyword is specified,
    matches in each `--inside`/`--outside` region is printed in different
    color.  Forcing this operation with multiple keywords, use
    `--regioncolor` option.

- **--inside**=_&function_
- **--outside**=_&function_

    If the pattern name begins by ampersand (&) character, it is treated
    as a name of subroutine which returns a list of blocks.  Using this
    option, user can use arbitrary function to determine from what part of
    the text they want to search.  User defined function can be defined in
    `.greplerc` file or by module option.

- **--include**=_pattern_
- **--exclude**=_pattern_
- **--include**=_&function_
- **--exclude**=_&function_

    `--include`/`--exclude` option behave exactly same as
    `--inside`/`--outside` when used alone.

    When used in combination, `--include`/`--exclude` are mixed in AND
    manner, while `--inside`/`--outside` are in OR.

    Thus, in the next example, first line prints all matches, and second
    does none.

        greple --inside PATTERN --outside PATTERN

        greple --include PATTERN --exclude PATTERN

    You can make up desired matches using `--inside`/`--outside` option,
    then remove unnecessary part by `--include`/`--exclude`

- **--strict**

    Limit the match area strictly.

    By default, `--block`, `--inside`/`outside`,
    `--include`/`--exclude` option allows partial match within the
    specified area.  For instance,

        greple --inside and command

    matches pattern `command` because the part of matched string is
    included in specified inside-area.  Partial match fails when option
    `--strict` provided, and longer string never matches within shorter
    area.

    Interestingly enough, above example

        greple --include PATTERN --exclude PATTERN

    produces output, as a matter of fact.  Think of the situation
    searching, say, `' PATTERN '` with this condition.  Matched area
    includes surrounding spaces, and satisfies both conditions partially.
    This match does not occur when option `--strict` is given, either.

## CHARACTER CODE

- **--icode**=_code_

    Target file is assumed to be encoded in utf8 by default.  Use this
    option to set specific encoding.  When handling Japanese text, you may
    choose from 7bit-jis (jis), euc-jp or shiftjis (sjis).  Multiple code
    can be supplied using multiple option or combined code names with
    space or comma, then file encoding is guessed from those code sets.
    Use encoding name `guess` for automatic recognition from default code
    list which is euc-jp and 7bit-jis.  Following commands are all
    equivalent.

        greple --icode=guess ...
        greple --icode=euc-jp,7bit-jis ...
        greple --icode=euc-jp --icode=7bit-jis ...

    Default code set are always included suspect code list.  If you have
    just one code adding to suspect list, put + mark before the code name.
    Next example does automatic code detection from euc-kr, ascii, utf8
    and UTF-16/32.

        greple --icode=+euc-kr ...

    If the string "**binary**" is given as encoding name, no character
    encoding is expected and all files are processed as binary data.

- **--ocode**=_code_

    Specify output code.  Default is utf8.

## FILTER

- **--if**=_filter_, **--if**=_EXP_:_filter_

    You can specify filter command which is applied to each file before
    search.  If only one filter command is specified, it is applied to all
    files.  If filter information include colon, first field will be perl
    expression to check the filename saved in variable $\_.  If it
    successes, next filter command is pushed.

        greple --if=rev perg
        greple --if='/\.tar$/:tar tvf -'

    If the command doesn't accept standard input as processing data, you
    may be able to use special device:

        greple --if='nm /dev/stdin' crypt /usr/lib/lib*

    Filters for compressed and gzipped file is set by default unless
    `--noif` option is given.  Default action is like this:

        greple --if='s/\.Z$//:zcat' --if='s/\.g?z$//:gunzip -c'

    File with `.gpg` suffix is filtered by **gpg** command.  In that case,
    pass-phrase is asked for each file.  If you want to input pass-phrase
    only once to find from multiple files, use `-Mpgp` module.

    If the filter start with `&`, perl subroutine is called instead of
    external command.  You can define the subroutine in `.greplerc` or
    modules.  **Greple** simply call the subroutine, so it should be
    responsible for process control.

- **--noif**

    Disable default input filter.  Which means compressed files will not
    be decompressed automatically.

- **--of**=_filter_
- **--of**=_&func_

    Specify output filter which process the output of **greple** command.
    Filter command can be specified in multiple times, and they are
    invoked for each file to be processed.  So next command reset the line
    number for each file.

        greple --of 'cat -n' string file1 file2 ...

    If the filter start with `&`, perl subroutine is called instead of
    external command.  You can define the subroutine in `.greplerc` or
    modules.

    Output filter command is executed only when matched string exists to
    avoid invoking many unnecessary processes.  No effect for option
    `-l` and `-c`.

- **--pf**=_filter_
- **--pf**=_&func_

    Similar to `--of` filter but invoked just once and takes care of
    entire output from **greple** command.

## RUNTIME FUNCTIONS

- **--print**=_function_
- **--print**=_sub{...}_

    Specify user defined function executed before data print.  Text to be
    printed is replaced by the result of the function.  Arbitrary function
    can be defined in `.greplerc` file or module.  Matched data is placed
    in variable `$_`.  Filename is passed by `&FILELABEL` key, as
    described later.

    It is possible to use multiple `--print` options.  In that case,
    second function will get the result of the first function.  The
    command will print the final result of the last function.

- **--continue**

    When `--print` option is given, **greple** will immediately print the
    result returned from print function and finish the cycle.  Option
    `--continue` forces to continue normal printing process after print
    function called.  So please be sure that all data being consistent.

- **--callback**=_function_(_..._)

    Callback function is called before printing every matched pattern with
    four labeled parameters: **start**, **end**, **index** and **match**,
    which corresponds to start and end position in the text, pattern
    index, and the matched string.  Matched string in the text is replaced
    by returned string from the function.

- **--begin**=_function_(_..._)
- **--begin**=_function_=_..._

    Option `--begin` specify the function executed at the beginning of
    each file processing.  This _function_ have to be called from **main**
    package.  So if you define the function in the module package, use the
    full package name or export properly.

    If the function dies with a message starting with a word "SKIP"
    (`/^SKIP/i`), that file is simply skipped.  So you can control if the
    file is to be processed using the file name or content.  To see the
    message, use `--warn begin=1` option.

    For example, using next function, only perl related files will be
    processed.

        sub is_perl {
            my %arg = @_;
            my $name = delete $arg{&FILELABEL} or die;
            $name =~ /\.(?:pm|pl|PL|pod)$/ or /\A#!.*\bperl/
                or die "skip $name\n";
        }

        1;

        __DATA__

        option default --filestyle=once --format FILE='\n%s:\n'

        autoload -Mdig --dig
        option --perl $<move> --begin &__PACKAGE__::is_perl --dig .

- **--end**=_function_(_..._)
- **--end**=_function_=_..._

    Option `--end` is almost same as `--begin`, except that the function
    is called after the file processing.

- **--prologue**=_function_(_..._)
- **--prologue**=_function_=_..._
- **--epilogue**=_function_(_..._)
- **--epilogue**=_function_=_..._

    Option `--prologue` and `--epilogue` specify functions called before
    and after processing.  During the execution, file is not opened and
    therefore, file name is not given to those functions.

- **-M**_module_::_function(...)_
- **-M**_module_::_function=..._

    Function can be given with module option, following module name.  In
    this form, the function will be called with module package name.  So
    you don't have to export it.  Because it is called only once at the
    beginning of command execution, before starting file processing,
    `FILELABEL` parameter is not given exceptionally.

- **--postgrep**=_function_(_..._)
- **--postgrep**=_function_=_..._

    Specify the function called after each search operation.  Funciton is
    called with `App::Greple::Grep` object which cotains all information
    about the search.  This interface highly depends on the internal
    structure, so use with the utmost cation.

For these run-time functions, optional argument list can be set in the
form of `key` or `key=value`, connected by comma.  These arguments
will be passed to the function in key => value list.  Sole key will
have the value one.  Also processing file name is passed with the key
of `FILELABEL` constant.  As a result, the option in the next form:

    --begin function(key1,key2=val2)
    --begin function=key1,key2=val2

will be transformed into following function call:

    function(&FILELABEL => "filename", key1 => 1, key2 => "val2")

As described earlier, `FILELABEL` parameter is not given to the
function specified with module option. So

    -Mmodule::function(key1,key2=val2)
    -Mmodule::function=key1,key2=val2

simply becomes:

    function(key1 => 1, key2 => "val2")

The function can be defined in `.greplerc` or modules.  Assign the
arguments into hash, then you can access argument list as member of
the hash.  It's safe to delete FILELABEL key if you expect random
parameter is given.  Content of the target file can be accessed by
`$_`.  Ampersand (`&`) is required to avoid the hash key is
interpreted as a bare word.

    sub function {
        my %arg = @_;
        my $filename = delete $arg{&FILELABEL};
        $arg{key1};             # 1
        $arg{key2};             # "val2"
        $_;                     # contents
    }

## OTHERS

- **--usage**\[=_expand_\]

    **Greple** print usage and exit with option `--usage`, or no valid
    parameter is not specified.  In this case, module option is displayed
    with help information if available.  If you want to see how they are
    expanded, supply something not empty to `--usage` option, like:

        greple -Mmodule --usage=expand

- **--exit**=_number_

    When **greple** executed normally, it exit with status 0 or 1 depending
    on something matched or not.  Sometimes we want to get status 0 even
    if nothing matched.  This option set the status code for normal
    execution.  It still exits with non-zero status when error occurred.

- **--man**, **--doc**

    Show manual page.
    Display module's manual page when used with `-M` option.

- **--show**, **--less**

    Show module file contents.  Use with `-M` option.

- **--path**

    Show module file path.  Use with `-M` option.

- **--norc**

    Do not read startup file: `~/.greplerc`.  This option have to be
    placed before any other options including `-M` module options.
    Setting `GREPLE_NORC` environment have same effect.

- **--conceal** _type_=_val_

    Use following `--warn` option in reverse context.  This option
    remains for backward compatibility and will be deprecated in the near
    future.

- **--persist**

    Same as `--error=retry`.  It may be deprecated in the future.

- **--error**=_action_

    As **greple** tries to read data as a character string, sometimes fails
    to convert them into internal representation, and the file is skipped
    without processing by default.  This works fine to skip binary
    data. (**skip**)

    Also sometimes encounters code mapping error due to character
    encoding.  In this case, reading the file as a binary data helps to
    produce meaningful output. (**retry**)

    This option specifies the action when data read error occurred.

    - **skip**

        Skip the file.  Default.

    - **retry**

        Retry reading the file as a binary data.

    - **fatal**

        Abort the operation.

    - **ignore**

        Ignore error and continue to read anyway.

    You may occasionally want to find text in binary data.  Next command
    will work like [string(1)](http://man.he.net/man1/string) command.

        greple -o --re '(?a)\w{4,}' --error=retry --uc /bin/*

    If you want read all files as binary data, use `--icode=binary`
    instead.

- **-w**, **--warn** _type_=\[`0`,`1`\]

    Control runtime message mainly about file operation related to
    `--error` option.  Repeatable.  Value is optional and 1 is assumed
    when omitted.  So `-wall` option is same as `-wall=1` and enables
    all messages, and `-wall=0` disables all.

    Types are:

    - **read**

        (Default 0) Errors occurred during file read.  Mainly unicode related
        errors when reading binary or ambiguous text file.

    - **skip**

        (Default 1) File skip message.

    - **retry**

        (Default 0) File retry message.

    - **begin**

        (Default 0) When `--begin` function died with `/^SKIP/i` message,
        the file is skipped without any notice.  Enables this to see the dying
        message.

    - **all**

        Set same value for all types.

- **--alert** \[ `size`=#, `time`=# \]

    Set alert parameter for large file.  **Greple** scans whole file
    content to know line borders, and it takes several seconds or more if
    it contains large number of lines.

    By default, if the target file contains more than **512 \* 1024
    characters** (_size_), **2 seconds** timer will start (_time_).  Alert
    message is shown when the timer expired.

    To disable this alert, set the size as zero:

        --alert size=0

- **-Mdebug**, **-d**_x_

    Debug option is described in [App::Greple::debug](https://metacpan.org/pod/App%3A%3AGreple%3A%3Adebug) module.

# ENVIRONMENT and STARTUP FILE

- **GREPLEOPTS**

    Environment variable GREPLEOPTS is used as a default options.  They
    are inserted before command line options.

- **GREPLE\_NORC**

    If set non-empty string, startup file `~/.greplerc` is not processed.

- **DEBUG\_GETOPT**

    Enable [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) debug option.

- **DEBUG\_GETOPTEX**

    Enable [Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX) debug option.

- **NO\_COLOR**

    If true, all coloring capability with ANSI terminal sequence is
    disabled.  See [https://no-color.org/](https://no-color.org/).

Before starting execution, **greple** reads the file named `.greplerc`
on user's home directory.  Following directives can be used.

- **option** _name_ string

    Argument _name_ of **option** directive is user defined option name.
    The rest are processed by `shellwords` routine defined in
    Text::ParseWords module.  Be sure that this module sometimes requires
    escape backslashes.

    Any kind of string can be used for option name but it is not combined
    with other options.

        option --fromcode --outside='(?s)\/\*.*?\*\/'
        option --fromcomment --inside='(?s)\/\*.*?\*\/'

    If the option named **default** is defined, it will be used as a
    default option.

    For the purpose to include following arguments within replaced
    strings, two special notations can be used in option definition.
    String `$<n>` is replaced by the _n_th argument after the
    substituted option, where _n_ is number start from one.  String
    `$<shift>` is replaced by following command line argument and
    the argument is removed from option list.

    For example, when

        option --line --le &line=$<shift>

    is defined, command

        greple --line 10,20-30,40

    will be evaluated as this:

        greple --le &line=10,20-30,40

- **expand** _name_ _string_

    Define local option _name_.  Command **expand** is almost same as
    command **option** in terms of its function.  However, option defined
    by this command is expanded in, and only in, the process of
    definition, while option definition is expanded when command arguments
    are processed.

    This is similar to string macro defined by following **define**
    command.  But macro expansion is done by simple string replacement, so
    you have to use **expand** to define option composed by multiple
    arguments.

- **define** _name_ string

    Define macro.  This is similar to **option**, but argument is not
    processed by _shellwords_ and treated just a simple text, so
    meta-characters can be included without escape.  Macro expansion is
    done for option definition and other macro definition.  Macro is not
    evaluated in command line option.  Use option directive if you want to
    use in command line,

        define (#kana) \p{InKatakana}
        option --kanalist --nocolor -o --join --re '(#kana)+(\n(#kana)+)*'
        help   --kanalist List up Katakana string

- **help** _name_

    If **help** directive is used for same option name, it will be printed
    in usage message.  If the help message is `ignore`, corresponding
    line won't show up in the usage.

- **builtin** _spec_ _variable_

    Define built-in option which should be processed by option parser.
    Arguments are assumed to be [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) style spec, and
    _variable_ is string start with `$`, `@` or `%`.  They will be
    replaced by a reference to the object which the string represent.

    See **pgp** module for example.

- **autoload** _module_ _options_ ...

    Define module which should be loaded automatically when specified
    option is found in the command arguments.

    For example,

        autoload -Mdig --dig --git

    replaces option "`--dig`" to "`-Mdig --dig`", so that **dig** module
    is loaded before processing `--dig` option.

Environment variable substitution is done for string specified by
`option` and `define` directives.  Use Perl syntax **$ENV{NAME}** for
this purpose.  You can use this to make a portable module.

When **greple** found `__PERL__` line in `.greplerc` file, the rest
of the file is evaluated as a Perl program.  You can define your own
subroutines which can be used by `--inside`/`--outside`,
`--include`/`--exclude`, `--block` options.

For those subroutines, file content will be provided by global
variable `$_`.  Expected response from the subroutine is the list of
array references, which is made up by start and end offset pairs.

For example, suppose that the following function is defined in your
`.greplerc` file.  Start and end offset for each pattern match can be
taken as array element `$-[0]` and `$+[0]`.

    __PERL__
    sub odd_line {
        my @list;
        my $i;
        while (/.*\n/g) {
            push(@list, [ $-[0], $+[0] ]) if ++$i % 2;
        }
        @list;
    }

You can use next command to search pattern included in odd number
lines.

    % greple --inside '&odd_line' pattern files...

# MODULE

You can expand the **greple** command using module.  Module files are
placed at `App/Greple/` directory in Perl library, and therefor has
**App::Greple::module** package name.

In the command line, module have to be specified preceding any other
options in the form of **-M**_module_.  However, it also can be
specified at the beginning of option expansion.

If the package name is declared properly, `__DATA__` section in the
module file will be interpreted same as `.greplerc` file content.  So
you can declare the module specific options there.  Functions declared
in the module can be used from those options, it makes highly
expandable option/programming interaction possible.

Using `-M` without module argument will print available module list.
Option `--man` will display module document when used with `-M`
option.  Use `--show` option to see the module itself.  Option
`--path` will print the path of module file.

See this sample module code.  This sample defines options to search
from pod, comment and other segment in Perl script.  Those capability
can be implemented both in function and macro.

    package App::Greple::perl;

    use Exporter 'import';
    our @EXPORT      = qw(pod comment podcomment);
    our %EXPORT_TAGS = ( );
    our @EXPORT_OK   = qw();
    
    use App::Greple::Common;
    use App::Greple::Regions;
    
    my $pod_re = qr{^=\w+(?s:.*?)(?:\Z|^=cut\s*\n)}m;
    my $comment_re = qr{^(?:[ \t]*#.*\n)+}m;
    
    sub pod {
        match_regions(pattern => $pod_re);
    }
    sub comment {
        match_regions(pattern => $comment_re);
    }
    sub podcomment {
        match_regions(pattern => qr/$pod_re|$comment_re/);
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

If special subroutine `initialize()` and `finalize()` are defined in
the module, they are called at the beginning with
[Getopt::EX::Module](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AModule) object as a first argument.  Second argument is
the reference to `@ARGV`, and you can modify actual `@ARGV` using
it.  See [App::Greple::find](https://metacpan.org/pod/App%3A%3AGreple%3A%3Afind) module as an example.

Calling sequence is like this.  See [Getopt::EX::Module](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AModule) for detail.

    1) Call initialize()
    2) Call function given in -Mmod::func() style
    3) Call finalize()

# HISTORY

Most capability of **greple** is derived from **mg** command, which has
been developing from early 1990's by the same author.  Because modern
standard **grep** family command becomes to have similar capabilities,
it is a time to clean up entire functionalities, totally remodel the
option interfaces, and change the command name. (2013.11)

# SEE ALSO

[grep(1)](http://man.he.net/man1/grep), [perl(1)](http://man.he.net/man1/perl)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX), [https://github.com/kaz-utashiro/Getopt-EX](https://github.com/kaz-utashiro/Getopt-EX)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 1991-2023 Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
