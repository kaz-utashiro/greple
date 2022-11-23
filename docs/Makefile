index.md: ../script/greple Makefile
	> $@
	printf "%s\ntitle: Greple\nlayout: page\n%s\n\n" --- --- >> $@
	cat < ../script/greple | \
	pod2markdown | sed 's/^#/##/' >> $@
