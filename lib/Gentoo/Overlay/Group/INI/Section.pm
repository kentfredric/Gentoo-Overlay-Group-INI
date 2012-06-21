use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Section;

# ABSTRACT: Storage container for Parsed/Decoded Config::MVP sections.

=head1 DESCRIPTION

Parsed Sections are blessed into this class structure.

=cut

use Moose;
extends 'Config::MVP::Section';

=method construct

  my $object = $section->construct();

Inflates the Object specification ( this section ) into the target object.

=cut

sub construct {
  my ($self)    = @_;
  my $class     = $self->package;
  my (%payload) = %{ $self->payload };
  return $class->new(%payload);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
