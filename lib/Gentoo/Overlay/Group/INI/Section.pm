use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Section;

# ABSTRACT:

use Moose;
extends 'Config::MVP::Section';

sub construct {
  my ($self)    = @_;
  my $class     = $self->package;
  my (%payload) = %{ $self->payload };
  return $class->new(%payload);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
