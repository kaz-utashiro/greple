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

expand is_repository	( -name .git -o -name .svn -o -name RCS -o -name CVS )
expand is_dots		  -name .*
expand is_version	  -name *,v
expand is_backup	( -name *~ -o -name *.swp )
expand is_image 	( -iname *.jpg  -o -iname *.jpeg -o \
			  -iname *.gif  -o -iname *.png  -o \
			  -iname *.ico  -o \
			  -iname *.heic -o -iname *.heif -o \
			  -iname *.svg \
			)
expand is_archive	( -iname *.tar -o -iname *.tbz -o -iname *.tgz -o \
			  -name  *.a   -o -name  *.zip \
			)
expand is_pdf		  -iname *.pdf
expand is_db		( -name *.db -o -iname *.bdb )
expand is_others	( -name *.bundle -o -name *.dylib -o -name *.o -o \
			  -name *.fits )

option --dig -Mfind \
	$<move> \
	( \
		is_repository -prune -o \
		-type f \
	) \
	! is_dots \
	! is_version \
	! is_backup \
	! is_image \
	! is_archive \
	! is_pdf \
	! is_db \
	! is_others \
	-print --

option --git -Mfind !git ls-files -- --conceal skip=1
