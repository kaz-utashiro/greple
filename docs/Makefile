index.md: ../script/greple Makefile
	> $@
	printf "%s\ntitle: Greple\n%s\n\n" --- --- >> $@
	cat < ../script/greple | \
	pod2markdown | sed 's/^#/##/' >> $@
