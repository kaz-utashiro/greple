use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

sub lines {
    my($title, $expected, @argv) = @_;
    my $pattern = qr/\A(.*\n){$expected}\z/;
    like(run(@argv)->stdout, $pattern, $title);
}

lines "--inside", 1, << 'END';
    -e "o" --inside "fox" t/SAMPLE.txt
END

lines "--outside", 4, << 'END';
    -e o --outside '.*\P{Ascii}.*' t/SAMPLE.txt
END

lines "--include", 1, << 'END';
    -e o --inside '^[A-U].*' --include '^[A-EV-Z].*' t/SAMPLE.txt
END

lines "--exclude", 5, << 'END';
    -e o --inside '^[A-U].*' --exclude '^[A-E].*' t/SAMPLE.txt
END

lines "w/o --strict", 1, << 'END';
    -e fox --inside o t/SAMPLE.txt
END

lines "w/ --strict", 0, << 'END';
    -e fox --inside o --strict t/SAMPLE.txt
END


done_testing;
