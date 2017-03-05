=head1 NAME

dig - Greple module for recursive search

=head1 SYNOPSIS

greple -Mdig --dig directory ...

=head1 DESCRIPTION

=cut

package App::Greple::dig;

1;

__DATA__

expand (#repository)	( -name .git -o -name RCS )
expand (#no_dots)	! -name .*
expand (#no_version)	! -name *,v
expand (#no_backup)	! -name *~
expand (#no_image) 	! -iname *.jpg  ! -iname *.jpeg \
			! -iname *.gif  ! -iname *.png
expand (#no_archive)	! -iname *.tar  ! -iname *.tbz  ! -iname *.tgz
expand (#no_pdf)	! -iname *.pdf

option --dig -Mfind \
	$<shift> \
	(#repository) -prune -o \
	-type f \
	(#no_dots) \
	(#no_version) (#no_backup) \
	(#no_image) \
	(#no_archive) \
	(#no_pdf) \
	-print --
