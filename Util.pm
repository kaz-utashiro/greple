use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';

use Data::Dumper;
use Command::Runner;

my $greple_path = sub {
    my($script, $module) = @_;
    # Find from $PATH
    for my $path (split /:+/, $ENV{PATH}) {
	$path .= "/$script";
	return $path if -x $path;
    }
    # Find from beside module file
    my $pm_file = $module =~ s/::/\//gr . '.pm';
    require $pm_file;
    my $pm_path = $INC{$pm_file};
    my $install =
	($pm_path =~ m{(^.*) /lib (?:/[^/]+){0,2} /\Q$pm_file\E$}x)[0]
	    or die $pm_path;
    for my $dir (qw(bin script)) {
	my $file = "$install/$dir/$script";
	return $file if -f $file;
    }
}->('greple', 'App::Greple') or die Dumper \%INC;

sub subst {
    Command::Runner->new(
	timeout => 2,
	command => [ $^X, '-Ilib', $greple_path, '-Msubst', @_ ],
	stderr  => sub { warn "err: $_[0]\n" },
	)->run;
}

1;
