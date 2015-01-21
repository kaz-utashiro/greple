package Getopt::EX::Loader;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Data::Dumper;
use Getopt::EX::Container;
use Getopt::EX::Func qw(parse_func);

sub new {
    my $class = shift;

    my $obj = bless {
	BUCKETS => [],
	BASECLASS => undef,
	MODULE_OPT => '-M',
	DEFAULT => 'default',
    }, $class;

    configure $obj @_ if @_;

    $obj;
}

sub configure {
    my $obj = shift;
    my %opt = @_;

    for my $opt (qw(BASECLASS MODULE_OPT DEFAULT)) {
	if (my $value = delete $opt{$opt}) {
	    $obj->{$opt} = $value;
	}
    }

    if (my $rc = delete $opt{RCFILE}) {
	my @rc = ref $rc eq 'ARRAY' ? @$rc : $rc;
	for (@rc) {
	    $obj->load(FILE => $_);
	}
    }

    warn "Unknown option: ", Dumper \%opt if %opt;

    $obj;
}

sub baseclass {
    my $obj = shift;
    @_  ? $obj->{BASECLASS} = shift
	: $obj->{BASECLASS};
}

sub buckets {
    my $obj = shift;
    @{ $obj->{BUCKETS} };
}

sub append {
    my $obj = shift;
    push @{ $obj->{BUCKETS} }, @_;
}

sub load {
    my $obj = shift;
    my $bucket = new Getopt::EX::Container @_, BASECLASS => $obj->baseclass;
    $obj->append($bucket);
    $bucket;
}

sub defaults {
    my $obj = shift;
    map { $_->default } $obj->buckets;
}

sub calls {
    my $obj = shift;
    map { $_->call } $obj->buckets;
}

sub builtins {
    my $obj = shift;
    map { $_->builtin } $obj->buckets;
}

sub deal_with {
    my $obj = shift;
    my $argv = shift;

    if (my $default = $obj->{DEFAULT}) {
	if (my $bucket = eval { $obj->load(MODULE => $default) }) {
	    $bucket->run_inits($argv);
	} else {
	    die $@ unless $! =~ /^No such file or directory/;
	}
    }
    $obj->modopt($argv, @_);
    unshift @$argv, $obj->defaults;
    $obj->expand($argv, @_);

    $obj;
}

sub modopt {
    my $obj = shift;
    my $argv = shift;

    my $start = $obj->{MODULE_OPT} // return ();
    $start eq '' and return ();
    my $start_re = qr/\Q$start\E/;
    my @modules;
    while (@$argv) {
	if ($argv->[0] =~ /^$start_re(?<module>.+)/) {
	    shift @$argv;
	    if (my $mod = $obj->parseopt($+{module}, $argv)) {
		push @modules, $mod;
	    }
	    next;
	}
	last;
    }
    @modules;
}

sub parseopt {
    my $obj = shift;
    my $mod = shift;
    my $argref = shift;
    my $base = $obj->baseclass;
    my $call;

    ##
    ## Check -Mmod::func(arg) or -Mmod::func=arg
    ##
    if ($mod =~ s{
	^ (?<name> .* ) ::
	  (?<call>
		\w+
		(?: (?<P>[(]) | = )  ## start with '(' or '='
		(?<arg> [^)]* )      ## optional arg list
		(?(<P>) [)] | )      ## close ')' or none
	  ) $
    }{$+{name}}x) {
	$call = $+{call};
    }

    my $bucket = eval { $obj->load(MODULE => $mod) } or die $@;

    if ($call) {
	$bucket->call(join '::', $bucket->module, $call);
    }

    ##
    ## If &getopt is defined in module, call it and replace @ARGV.
    ##
    $bucket->run_inits($argref);

    $obj;
}

sub expand {
    my $obj = shift;
    my $argv = shift;

    ##
    ## Process user defined option.
    ##
  ARGV:
    for (my $i = 0; $i < @$argv; $i++) {
	last if $argv->[$i] eq '--';
	my($opt, $value) = split /=/, $argv->[$i], 2;
	for my $bucket ($obj->buckets) {
	    if (my @s = $bucket->getopt($opt)) {
		my @module = $obj->modopt(\@s);
		splice @$argv, $i, 1, ($opt, $value) if defined $value;
		##
		## Convert $<n> and $<shift>
		##
		my @rest = splice @$argv, $i;
		s/\$<(\d+)>/$rest[$1]/ge foreach @s;
		shift @rest;
		s/\$<shift>/shift @rest/ge foreach @s;

		my @default = map { $_->defaults } @module;
		push @$argv, @default, @s, @rest;
		redo ARGV;
	    }
	}
    }
}

sub modules {
    my $obj = shift;
    my $base = $obj->baseclass or return ();
    $base =~ s/::/\//g;

    grep { /^[a-z]/ }
    map  { /(\w+)\.pm$/ }
    map  { glob "$_/$base/*.pm" }
    @INC;
}

1;
