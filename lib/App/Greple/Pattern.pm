package App::Greple::Pattern;

use v5.14;
use warnings;
use Data::Dumper;

use Exporter 'import';
our @EXPORT      = ();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

use Getopt::EX::Func qw(parse_func);

##
## Flags
##
use constant {
    FLAG_NONE       => 0,
    FLAG_NEGATIVE   => 1,
    FLAG_REQUIRED   => 2,
    FLAG_REGEX      => 4,
    FLAG_IGNORECASE => 8,
    FLAG_COOK       => 16,
    FLAG_OR         => 32,
    FLAG_LEXICAL    => 64,
    FLAG_FUNCTION   => 128,
};
push @EXPORT, qw(
    FLAG_NONE
    FLAG_NEGATIVE
    FLAG_REQUIRED
    FLAG_REGEX
    FLAG_IGNORECASE
    FLAG_COOK
    FLAG_OR
    FLAG_LEXICAL
    FLAG_FUNCTION
);

sub new {
    my $class = shift;
    my $obj = bless {
	STRING   => undef,
	COOKED   => undef,
	FLAG     => undef,
	REGEX    => undef,
	CATEGORY => undef,
	FUNCTION => undef,
    }, $class;

    setup $obj @_ if @_;

    $obj;
}

sub setup {
    my $obj = shift;
    my $target = shift;
    my %opt = @_;

    $obj->flag($opt{flag} // FLAG_NONE);

    if ($obj->is_function) {
	if ($target->can('call')) {
	    $obj->string('*FUNCTION');
	    $obj->cooked('*FUNCTION');
	    $obj->function($target);
	} else {
	    $obj->string($target);
	    $obj->cooked($target);
	    $obj->function(parse_func({ PACKAGE => 'main' }, $target));
	}
    } else {
	$obj->string($target);
	$obj->cooked($obj->is_multiline
		     ? cook_pattern($target, flag => $obj->flag)
		     : $target);
	$obj->regex(
	    do {
		my $p = $obj->is_regex ? $obj->cooked : quotemeta($obj->cooked);
		$obj->is_ignorecase ? qr/$p/mi : qr/$p/m;
	    } );
    }

    $obj;
}

sub field {
    my $obj = shift;
    my $name = shift;
    if (@_) {
	$obj->{$name} = shift;
	$obj;
    } else {
	$obj->{$name};
    }
}

sub flag     { shift->field ( FLAG     => @_ ) // 0 }
sub string   { shift->field ( STRING   => @_ )      }
sub cooked   { shift->field ( COOKED   => @_ )      }
sub regex    { shift->field ( REGEX    => @_ )      }
sub category { shift->field ( CATEGORY => @_ )      }
sub function { shift->field ( FUNCTION => @_ )      }

sub is_positive   { !($_[0]->flag & FLAG_NEGATIVE)  };
sub is_negative   {   $_[0]->flag & FLAG_NEGATIVE   };
sub is_required   {   $_[0]->flag & FLAG_REQUIRED   };
sub is_regex      {   $_[0]->flag & FLAG_REGEX      };
sub is_ignorecase {   $_[0]->flag & FLAG_IGNORECASE };
sub is_multiline  {   $_[0]->flag & FLAG_COOK       };
sub is_function   {   $_[0]->flag & FLAG_FUNCTION   };

sub IsWide {
    return <<'END';
+utf8::East_Asian_Width=Wide
+utf8::East_Asian_Width=FullWidth
END
}

my $wclass_re = qr{ \[ \p{IsWide}+ (?: \- \p{IsWide}+ )* \] }x;
my $wstr_re   = qr{ (?: \p{IsWide} | $wclass_re )+ }x;

sub wstr {
    local $_ = shift;
    my @wchars = m{ \G ( $wclass_re | \X ) }gx or die;
    join '\\s*', @wchars;
}

sub cook_pattern {
    my $p = shift;
    my %opt = @_;

    if ($p =~ s/^\\Q//) {
	return quotemeta($p);
    }

  COOK:
    {
	$p =~ s{
	    (?<match>
	     (?<class>
	      \[[^\]]*\] [\?\*]?	# character-class
	     )
	     |
	     (?<ahead>
	      \(\?[=!][^\)]*\)		# look-ahead pattern
	     )
	     |
	     (?<behind>
	      \(\?\<[=!][^\)]*\)	# look-behind pattern
	     )
	     |
	     (?<wstr> $wstr_re)
	     |
	     (?<else> [A-Z0-9_]+ | . )
	    )
	}{
	    if (defined $+{ahead}) {
		$+{match}
		    =~ s{\A \( \? [=!] \K
			    ( (?: $wstr_re | \| )+ )
			}{
			    join '|', (map { wstr($_) } split /\|/, $1);
			}erx;
	    } elsif (defined $+{wstr}) {
		wstr($+{match});
	    } else {
		$+{match};
	    }
	}egx;

	# ( [
	$p =~ s/\p{IsWide} \K (?= [\(\[] )/\\s*+/gx;

	# ) ]
	$p =~ s{
	    (# look-behind ending wchar
	     \(\?<[=!][^\)]*\p{IsWide}\)	(?! [|] | $ )
	    )
	    |
	    (# skip look-ahead/behind
	     \(\?<?[=!][^\)]*\)
	    )
	    |
	    (# whcar before ) or ]
		\p{IsWide} [\)\]]+ [?]?+ (?! \\s\* | [|] | $ )
	    )
	}{
	    if (defined $1) {
		$1 . "\\s*+";
	    } elsif (defined $2) {
		$2;
	    } else {
		$3 . "\\s*+";
	    }
	}egx;

	# convert space not preceded by \ to \s+,
	# removing \s* and \s*+ arround it
	$p =~ s{
	    (?: \Q\s*\E \+?+ )*
	    (?: (?<!\\) [ ] )+
	    (?: \Q\s*\E \+?+ )*
	}{\\s+}gx;
    }

    $p;
}

1;
