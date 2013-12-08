test.md: greple Makefile
	tr '`' "'" < greple | \
	sed 's/=item/=head4/' | \
	perl -pe 's/^/=head2 / if /^B\<[A-Z ]+\>$$/' | \
	perl pod2markdown > $@
