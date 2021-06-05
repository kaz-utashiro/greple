=head1 NAME

dig - Greple module for recursive search

=head1 SYNOPSIS

greple -Mdig [ options ] --dig directories ...

greple -Mdig --git ...

=head1 DESCRIPTION

Option B<--dig> searches all files under directories specified after
it.  Since it takes all following arguments as target files or
directories, use after all necessary options.

It is possible to specify AND condition after directories, in B<find>
option format.  Next command will search all C source files under the
current directory.

    $ greple -Mdig pattern --dig . -name *.c

    $ greple -Mdig pattern --dig . ( -name *.c -o -name *.h )

You can use B<--dig> option without module declaration by setting it
as autoload module in your F<~/.greplerc>.

    autoload -Mdig --dig --git

=head1 OPTIONS

=over 7

=item B<--dig> I<directories> I<find-option>

Specify at the end of B<greple> options.

=item B<--git>

Search files under git control.

=back

=cut

package App::Greple::dig;

1;

__DATA__

expand (#repository)	( -name .git -o -name .svn -o -name RCS )
expand (#no_dots)	! -name .*
expand (#no_version)	! -name *,v
expand (#no_backup)	! -name *~ ! -name *.swp
expand (#no_image) 	! -iname *.jpg  ! -iname *.jpeg \
			! -iname *.gif  ! -iname *.png  \
			! -iname *.ico  \
			! -iname *.heic ! -iname *.heif
expand (#no_archive)	! -iname *.tar  ! -iname *.tbz  ! -iname *.tgz \
			! -name *.a ! -name *.zip
expand (#no_pdf)	! -iname *.pdf
expand (#no_others)	! -name *.bundle ! -name *.dylib ! -name *.o

option --dig -Mfind \
	$<move> \
	( \
		(#repository) -prune -o \
		-type f \
	) \
	(#no_dots) \
	(#no_version) (#no_backup) \
	(#no_image) \
	(#no_archive) \
	(#no_pdf) \
	(#no_others) \
	-print --

option --git -Mfind !git ls-files -- --conceal skip=1
