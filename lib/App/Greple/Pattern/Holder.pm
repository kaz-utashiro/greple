package App::Greple::Pattern::Holder;

use strict;
use warnings;
use Data::Dumper;

use Exporter 'import';
our @EXPORT      = ();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

use App::Greple::Pattern;

sub new {
    my $class = shift;
    my $obj = bless [], $class;
    $obj;
}

sub append {
    my $obj = shift;
    my $arg = ref $_[0] eq 'HASH' ? shift : {};

    return $obj unless @_;

    if ($arg->{flag} & FLAG_LEXICAL) {
	$arg->{flag} &= ~FLAG_LEXICAL;
	for (@_) {
	    $obj->lexical_opt($arg, $_);
	}
	return $obj;
    }

    if ($arg->{flag} & FLAG_OR) {
	$arg->{flag} &= ~FLAG_OR;
	@_ = (join '|',
	      map {
		  App::Greple::Pattern->new($_, flag => $arg->{flag})->cooked
	      } @_);
	$arg->{flag} |= FLAG_REGEX;
    }

    for (@_) {
	push @$obj, App::Greple::Pattern->new($_, flag => $arg->{flag});
    }

    $obj;
}

sub lexical_opt {
    my $obj = shift;
    my $arg = shift;
    my $opt = shift;
    
    my @or;

    for (split /(?<!\\) +/, $opt) {

	next if $_ eq "";

	my $flag = $arg->{flag};

	if (s/^\&//) {					# &func(...)
	    $flag |= FLAG_REGEX | FLAG_FUNCTION,
	}
	elsif (s/^-//) {				# -pattern
	    $flag |= FLAG_REGEX | FLAG_NEGATIVE,
	}
	elsif (s/^\?//) {				# ?pattern
	    push @or, $_;
	    $_ = '';
	}
	elsif (s/^\+//) {				# +pattern
	    $flag |= FLAG_REGEX | FLAG_REQUIRED,
	}
	else {						# else
	    $flag = FLAG_REGEX,
	}

	$obj->append({ flag => $flag }, $_) if $_ ne '';
    }

    if (@or) {
	my $flag = $arg->{flag} | FLAG_OR;
	$obj->append({ flag => $flag }, @or);
    }
}

sub patterns {
    my $obj = shift;
    @{ $obj };
}

1;
