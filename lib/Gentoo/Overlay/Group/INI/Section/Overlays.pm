use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Section::Overlays;

# ABSTRACT:

use Moose;

sub mvp_multivalue_args {
  return qw( directory );
}

has '_directories' => ( 
  init_arg => 'directory',
  isa => 'ArrayRef[ Str ]',
  is => 'rw',
  traits => [qw( Array )],
  handles => {
    directories => elements =>,
  },
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
