use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Section::Overlays;

# ABSTRACT: Final Target for [Overlays] sections.

use Moose;

=head1 SYNOPSIS

  [Overlays]
  directory = a
  directory = b
  directory = c

This is eventually parsed and decoded into one of these objects.

  my @directories = ( $object->directories ); # ( a, b, c )

=cut

=method mvp_multivalue_args

Tells Config::MVP that C<directory> can be specified multiple times.

=cut

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

=method overlay_group

Convert the data stored in this section into a Gentoo::Overlay::Group object.

  $group = $section->overlay_group;

=cut

sub overlay_group {
  my ( $self, @rest ) = @_;
  require Gentoo::Overlay::Group;
  my $group = Gentoo::Overlay::Group->new();
  for my $path ( $self->directories ) {
    $group->add_overlay($path);
  }
  return $group;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
