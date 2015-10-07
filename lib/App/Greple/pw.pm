=head1 NAME

pw - Module to get password from file


=head1 SYNOPSIS

greple -Mpw pattern file


=head1 DESCRIPTION

This module searches id and password information those written in text
file, and displays them interactively.  Passwords are not shown on
display by default, but you can copy them into clipboard by specifying
item mark.

PGP encrypted file can be handled by B<greple> standard feature.
Command "B<gpg>" is invoked for files with "I<.gpg>" suffix by
default.  Option B<--pgp> is also available, then you can type
passphrase only once for searching from multiple files.  Consult
B<--if> option if you are using other encryption style.

Terminal scroll buffer and screen is cleared when command exits, and
content of clipboard is replaced by prepared string, so that important
information does not remain on the terminal.

Id and password is collected from text using some keywords like
"user", "account", "password", "pin" and so on.  To see actual data,
use B<pw_status> function described below.

Some bank use random number matrix as a countermeasure for tapping.
If the module successfully guessed the matrix area, it blackout the
table and remember them.

    | A B C D E F G H I J
  --+--------------------
  0 | Y W 0 B 8 P 4 C Z H
  1 | M 0 6 I K U C 8 6 Z
  2 | 7 N R E Y 1 9 3 G 5
  3 | 7 F A X 9 B D Y O A
  4 | S D 2 2 Q V J 5 4 T

Enter the field position to get the cell items like:

    > E3 I0 C4

and you will get the answer:

    9 Z 2

Case is ignored and while space is not necessary, so you can type like
this as well:

    > e3i0c4


=head1 INTERFACE

=over 7

=item B<pw_print>

Data print function.  This function is set for B<--print> option of
B<greple> by default, and user doesn't have to care about it.

=item B<pw_epilogue>

Epilogue function.  This function is set for B<--end> option of
B<greple> by default, and user doesn't have to care about it.

=item B<pw_option>

Several parameters can be set by B<pw_option> function.  If you do not
want to clear screen after command execution, call B<pw_option> like:

    greple -Mpw::pw_option(clear_screen=0)

or:

    greple -Mpw --begin pw_option(clear_screen=0)

with appropriate quotation.

Currently following options are available:

    clear_clipboard
    clear_string
    clear_screen
    clear_buffer
    goto_home
    browser
    timeout
    parse_matrix
    parse_id
    parse_pw
    id_keys
    id_chars
    id_color
    id_label_color
    pw_keys
    pw_chars
    pw_color
    pw_label_color
    pw_blackout
    debug

Password is not blacked out when B<pw_blackout> is 0.  If it is 1, all
password characters are replaced by 'x'.  If it is greater than 1,
password is replaced by sequence of 'x' indicated by that number.

B<id_keys> and B<pw_keys> are list, and list members are separated by
whitespaces.  When the value start with 'B<+>' mark, it is appended to
current list.

=item B<pw_status>

Print option status.  Next command displays defaults.

    greple -Mpw::pw_status= dummy /dev/null

=back

=cut


package App::Greple::pw;

use strict;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT      = qw(&pw_print &pw_epilogue &pw_option &pw_status);
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Carp;
use Data::Dumper;
use App::Greple::Common;
use App::Greple::PwBlock;

my $execution = 0;

sub pw_print {
    my %attr = @_;
    my @pass;

    $execution++;

    my $pw = new App::Greple::PwBlock $_;

    print $pw->masked;

    command_loop($pw) or do { pw_epilogue(); exit };

    return '';
}

our $debug = 0;
our $clear_clipboard = 1;
our $clear_string = 'Hasta la vista.';
our $clear_screen = 1;
our $clear_buffer = 1;
our $goto_home = 0;
our $browser = 'chrome';
our $timeout = 300;

my @flags = (
    clear_clipboard => \$clear_clipboard,
    clear_string    => \$clear_string,
    clear_screen    => \$clear_screen,
    clear_buffer    => \$clear_buffer,
    goto_home       => \$goto_home,
    browser         => \$browser,
    timeout         => \$timeout,
    parse_matrix    => \$App::Greple::PwBlock::parse_matrix,
    parse_id        => \$App::Greple::PwBlock::parse_id,
    parse_pw        => \$App::Greple::PwBlock::parse_pw,
    id_keys         => \@App::Greple::PwBlock::id_keys,
    id_chars        => \$App::Greple::PwBlock::id_chars,
    id_color        => \$App::Greple::PwBlock::id_color,
    id_label_color  => \$App::Greple::PwBlock::id_label_color,
    pw_keys         => \@App::Greple::PwBlock::pw_keys,
    pw_chars        => \$App::Greple::PwBlock::pw_chars,
    pw_color        => \$App::Greple::PwBlock::pw_color,
    pw_label_color  => \$App::Greple::PwBlock::pw_label_color,
    pw_blackout     => \$App::Greple::PwBlock::pw_blackout,
    debug           => \$debug,
    );
my %flags = @flags;
my @label = @flags[grep { $_ % 2 == 0 } 0 .. $#flags];

sub pw_option {
    my %arg = @_;
    delete $arg{&FILELABEL}; # no entry when called from -M otption.

    while (my($k, $v) = each %arg) {
	my $target = $flags{$k};
	if (not defined $target) {
	    warn "$k: Option unknown.\n";
	    next;
	}
	if (ref $target eq 'ARRAY') {
	    $v =~ s/^\+// or @$target = ();
	    push @$target, split /\s+/, $v;
	} else {
	    $$target = $v;
	}
    }
}

sub pw_status {
    binmode STDOUT, ":encoding(utf8)";
    for my $key (@label) {
	my $val = $flags{$key};
	print($key, ": ",
	      ref $val eq 'ARRAY' ? "@$val" : $$val,
	      "\n");
    }
}

use constant { CSI => "\e[" };

sub pw_epilogue {
    $execution == 0 and return;
    copy($clear_string) if $clear_clipboard;
    print STDERR CSI, "H" if $goto_home;
    print STDERR CSI, "2J" if $clear_screen;
    print STDERR CSI, "3J" if $clear_buffer;
}

sub pw_timeout {
    if ($debug) {
	warn "pw_timeout() called.\n";
	sleep 1;
    }
    pw_epilogue();
    exit;
}

sub command_loop {
    my $pw = shift;

    open TTY, "/dev/tty" or die;

    require Term::ReadLine;
    my $term = Term::ReadLine->new(__PACKAGE__, *TTY, *STDOUT);

    binmode TTY, ":encoding(utf8)";
    binmode STDOUT, ":encoding(utf8)";

    while ($_ = $term->readline("> ")) {
	if ($timeout) {
	    $SIG{ALRM} = \&pw_timeout;
	    alarm $timeout;
	    warn "Set timeout to $timeout seconds\n" if $debug;
	}
	/\S/ or next;
	$term->addhistory($_);
	s/\s+\z//;
	$_ = kana2alpha($_);

	if (my $id = $pw->id($_)) {
	    if (copy($id)) {
		printf "ID [%s] was copied to clipboard.\n", $id;
	    }
	    next;
	}
	elsif (my $pass = $pw->pw($_)) {
	    if (copy($pass)) {
		printf "Password [%s] was copied to clipboard.\n", $_;
	    }
	    next;
	}

	if (0) {}
	elsif (/^dump\b/)  { print Dumper $pw }
	elsif (/^N/i) { last }
	elsif (/^P/i) { print $pw->masked }
	elsif (/^Q/i) { return 0 }
	elsif (/^V/i) {
	    s/^.\s*//;
	    my @option = split /\s+/;
	    if (@option == 0) {
		print $pw->orig;
	    } else {
		my @values = map { $pw->any($_) // '[N/A]' } @option;
		print "@values\n";
	    }
	}
	elsif (/^show\b/i) {
	    print $pw->masked;
	}
	elsif (/^orig\b/i) {
	    print $pw->orig;
	}
	##
	## INPUT to browser
	##
	elsif (s/^input\s*//i) {
	    my %field = do {
		map {
		    m{
			( (?: name: | id: )? \w+ )
			(?|
			  \s+ (.*) # '=' がなければ残り全部
			  |
			  = ( \/.+\/ | \w+ (?:,\w+)* )
			)
		    }xg
		}
		$pw->orig =~ /^INPUT\s+(.+)/mg;
	    };
	    warn Dumper \%field if $debug;
	    my @arg = do {
		map { /^([a-z]\d\s*){2,}$/i ? /([a-z]\d)/gi : $_ }
		map { m{^/(.+)/$} ? get_pattern($1) : $_ }
		map { $field{$_} or $_ }
		map { split /[\s=]+/ }
		map { $field{$_} or $_ }
		split /\s+/;
	    };
	    warn "@arg\n" if $debug;
	    while (@arg >= 2) {
		my $label = shift @arg;
		my @fields = split /[,]/, $label;
		for my $field (@fields) {
		    my $item = shift @arg;
		    my $value = $pw->any($item) // $item;
		    set_browser_field($field, $value);
		}
	    }
	}
	elsif (/^set$/) {
	    for my $var (sort keys %flags) {
		print "$var: ";
		if (ref $flags{$var} eq 'SCALAR') {
		    print ${$flags{$var}};
		} else {
		    my @val = @{$flags{$var}};
		    print qq("@val");
		}
		print "\n";
	    }
	}
	elsif (s/^set\s+//) {
	    my($var, $val) = split /\s+/, $_, 2;
	    if (my $ref = $flags{$var}) {
		if (ref $ref eq 'SCALAR') {
		    $$ref = $val;
		}
		elsif (ref $ref eq 'ARRAY') {
		    @$ref = split /\s+/, $val;
		}
		else {
		    die;
		}
	    } else {
		warn "Unknown variable: $var";
	    }
	}
	elsif (/^([A-J]\d\s*)+$/i) {
	    my @chars;
	    while (/([A-J])(\d)/gi) {
		push @chars, $pw->cell(uc($1), $2) // 'ERROR';
	    }
	    print "@chars\n";
	}
	else {
	    print "Command error.\n";
	}
    }
    close TTY;

    return 1;
}

my %kana2alpha = (
    ア => 'A', イ => 'B', ウ => 'C', エ => 'D', オ => 'E',
    カ => 'F', キ => 'G', ク => 'H', ケ => 'I', コ => 'J',
    );

sub kana2alpha {
    local $_ = shift;
    s/([アイウエオカキクケコ])/$kana2alpha{$1}/g;
    $_;
}

my $clipboard;
BEGIN {
    eval "use Clipboard";
    if (not $@) {
	$clipboard = "Clipboard";
    }
    elsif (-x "/usr/bin/pbcopy") {
	$clipboard = "pbcopy";
    }
    else {
	warn("==========================================\n",
	     "Clipboard is not available on this system.\n",
	     "Install Clipboard module from CPAN.\n",
	     "==========================================\n");
    }
}

sub copy {
    my $text = shift;
    if (not $clipboard) {
	warn "Clipboard is not available.\n";
	return undef;
    }
    elsif ($clipboard eq "Clipboard") {
	Clipboard->copy($text);
    }
    elsif ($clipboard = "pbcopy") {
	dumpto($clipboard, $text);
    }
    1;
}

sub dumpto {
    my $command = shift;
    my $text = shift;
    open COM, "| $command" or die "$command: $!\n";
    print COM $text;
    close COM;
}

sub apple_script {
    my $app = shift;
    shift if $_[0] eq 'to';
    my $do = join "\n", @_;
    my $script = <<"    end_script";
	tell Application "$app"
	    $do
	end tell
    end_script
    warn $script if $debug;
    if ((open(CMD, "-|") // die) == 0) {
	exec 'osascript', '-e', $script or die;
    } else {
	my $result = do { local $/; <CMD> };
	close CMD;
	warn $result if $debug;
	return $result =~ /missing value/ ? undef : $result;
    }
}

my %js_subs = (
    chrome => \&js_chrome,
    safari => \&js_safari,
    );

sub js {
    (my $sub = $js_subs{$browser}) // do {
	warn "Unsupported browser: $browser";
	return;
    };
    goto $sub;
}

sub _js {
    goto &js_chrome;
}

sub js_chrome {
    my $js = shift;
    $js =~ s/"/\\"/g;
    $js =~ s/\n//g;
    my $script = <<"    end_script";
	tell active tab of window 1
	    execute javascript ("$js")
	end tell
    end_script
    apple_script 'Google Chrome', $script;
}

sub js_safari {
    my $js = shift;
    $js =~ s/"/\\"/g;
    apple_script 'Safari', <<"    end_script";
	tell current tab of window 1
	    do JavaScript ("$js")
	end tell
    end_script
}

sub set_browser_field {
    my $name = shift;
    my $value = shift;
    js "document.getElementsByName('$name')[0].value='$value'"
	if defined $value;
}

sub get_pattern {
    my $pattern = shift;
    js "document.body.textContent.match(/$pattern/)";
}    

1;


__DATA__

option default \
	--paragraph \
	--print pw_print \
	--end pw_epilogue

option --pw_option --begin pw_option($<shift>=$<shift>)

option --debug --pw_option debug 1

option --timeout --pw_option timeout

option --browser --pw_option browser
option --chrome --browser chrome
option --safari --browser safari
