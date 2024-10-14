package App::Greple::Common;

use v5.14;
use warnings;

=encoding utf-8

=head1 NAME

App::Greple::Common - interface for common resources

=head1 SYNOPSIS

    use App::Greple::Common qw(@color_list)

=head1 DESCRIPTION

This module provides interface to access L<App::Greple> common
resources which can be accessed from the external modules.

=head1 EXPORTED VARIABLES

=head2 CONSTANTS

=over 7

=item B<FILELABEL>

A label corresponding to the filename passed in the
L<App::Greple::Func> interface.

=back

=head2 VARIABLES

=over 7

=item B<%color_list>

Indexed color pallet.

=item B<%color_hash>

Labeled color table.

=item B<%debug>

Debug flag.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Exporter 'import';
our @EXPORT      = ();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

use constant FILELABEL => '__file__';
push @EXPORT, qw(FILELABEL);

*debug      = \%::opt_d;	push @EXPORT_OK, qw(%debug);
*color_list = \@::colors;	push @EXPORT_OK, qw(@color_list);
*color_hash = \%::colormap;	push @EXPORT_OK, qw(%color_hash);

*setopt     = \&::setopt;	push @EXPORT_OK, qw(setopt);
*newopt     = \&::newopt;	push @EXPORT_OK, qw(newopt);

1;
