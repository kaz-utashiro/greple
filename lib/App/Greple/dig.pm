=head1 NAME

dig - Greple module for recursive search

=head1 SYNOPSIS

greple -Mdig pattern --dig directories ...

greple -Mdig pattern --git ...

=head1 DESCRIPTION

Option B<--dig> searches all files under specified directories.  Since
it takes all following arguments, place at the end of all options.

It is possible to specify AND condition after directories, in B<find>
option format.  Next command will search all C source files under the
current directory.

    $ greple -Mdig pattern --dig . -name *.c

    $ greple -Mdig pattern --dig . ( -name *.c -o -name *.h )

If more compilicated file filtering is required, combine with
B<-Mselect> module.

You can use B<--dig> option without module declaration by setting it
as autoload module in your F<~/.greplerc>.

    autoload -Mdig --dig --git

=head1 OPTIONS

=over 7

=item B<--dig> I<directories> I<find-option>

Specify at the end of B<greple> options, because all the rest is taken
as option for L<find(1)> command.

=item B<--git> I<ls-files-option>

Search files under git control.  Specify at the end of B<greple>
options, because all the rest is taken as option for
L<git-ls-files(1)> command.


=back

=head1 SEE ALSO

L<App::Greple>

L<App::Greple::select>

L<find(1)>, L<git-ls-files(1)>

=cut

package App::Greple::dig;

1;

__DATA__

expand is_repository	( -name .git -o -name .svn -o -name RCS -o -name CVS )
expand is_environment	( -name .vscode )
expand is_temporary	( -name .build -o -name _build )
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
		( is_repository -o is_environment -o is_temporary ) \
		-prune -o \
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

option --git \
	-Mfind !git ls-files $<move> -- --warn skip=0
