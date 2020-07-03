package App::Greple::Filter;

use v5.14;
use warnings;

use Exporter 'import';
our @EXPORT      = ();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

use Getopt::EX::Func qw(parse_func);
use App::Greple::Common;


sub new {
    my $class = shift;
    my $obj = bless [], $class;

    append $obj @_ if @_;

    $obj;
}

sub parse {
    my $obj = shift;
    push @$obj, map { /([^:]+):(.*)/ ? [ $1, $2 ] : $_ } @_;
    $obj;
}

sub append {
    my $obj = shift;
    push @$obj, @_;
    $obj;
}

sub get_filters {
    my $obj = shift;
    my $filename = shift;

    my @f;
    local $_ = $filename;
    for (my $remember = ""; $remember ne $_; ) {
	$remember = $_;
	for my $p (@$obj) {
	    if (ref $p eq 'ARRAY') {
		my($exp, $command) = @$p;
		if (ref $exp eq 'CODE' ? &$exp : eval $exp) {
		    $command =~ s/{}/$filename/g;
		    push @f, $command;
		    last if $_ ne $remember;
		}
	    } else {
		push @f, $p;
	    }
	}
    }
    @f;
}

push @EXPORT, qw(push_output_filter);
sub push_output_filter {
    my %arg = ref $_[0] eq 'HASH' ? %{+shift} : ();
    my $fh = shift;
    my $pkg = caller;
    for my $filter (reverse @_) {
	$opt_d{m} and warn "Push output Filter: \"$filter\"\n";
	my $pid = open($fh, '|-') // die "$filter: $!\n";
	if ($pid == 0) {
	    if ($filter =~ /^&/ and
		my $f = parse_func({ PACKAGE => $pkg }, $filter)) {
		local @ARGV;
		open STDIN, '<&', 0 if eof STDIN;
		$f->call;
	    } else {
		do { exec $filter } ;
		warn $@ if $@;
	    }
	    exit;
	}
    }
}

push @EXPORT, qw(push_input_filter);
sub push_input_filter {
    my %arg = ref $_[0] eq 'HASH' ? %{+shift} : ();
    my $pkg = caller;
    for my $filter (@_) {
	$opt_d{m} and warn "Push input Filter: \"$filter\"\n";
	if ($filter =~ /^&/ and
	    my $f = parse_func({ PACKAGE => $pkg }, $filter)) {
	    if ($arg{&FILELABEL}) {
		$f->append(&FILELABEL => $arg{&FILELABEL});
	    }
	    ##
	    ## intput filter function is responsible for process fork
	    ##
	    $f->call;
	} else {
	    my $pid = open(STDIN, '-|') // die "$filter: $!\n";
	    if ($pid == 0) {
		do { exec $filter } ;
		warn $@ if $@;
		exit;
	    }
	}
    }
}

1;
