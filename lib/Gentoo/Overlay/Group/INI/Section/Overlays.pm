use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Section::Overlays;
BEGIN {
  $Gentoo::Overlay::Group::INI::Section::Overlays::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Overlay::Group::INI::Section::Overlays::VERSION = '0.1.0';
}

# ABSTRACT:

use Moose;

sub mvp_multivalue_args {
  return qw( directory );
}

has '_directories' => (
  init_arg => 'directory',
  isa      => 'ArrayRef[ Str ]',
  is       => 'rw',
  traits   => [qw( Array )],
  handles  => { directories => elements =>, },
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Gentoo::Overlay::Group::INI::Section::Overlays - use Moose;

=head1 VERSION

version 0.1.0

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

