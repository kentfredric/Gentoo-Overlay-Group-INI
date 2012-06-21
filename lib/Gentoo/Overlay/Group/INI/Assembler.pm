use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Assembler;

# ABSTRACT: Glue record for Config::MVP

=head1 DESCRIPTION

This is a glue layer. We pass Config::MVP an instance of this class, and it tells Config::MVP
that top level section declarations are to be expanded as children of Gentoo::Overlay::Group::INI::Section::

=cut

use Moose;
extends 'Config::MVP::Assembler';

=method expand_package

  ini file:

[Moo]

-->

  $asm->expand_package('Moo'); # Gentoo::Overlay::Group::INI::Section::Moo

=cut

sub expand_package {
  return "Gentoo::Overlay::Group::INI::Section::$_[1]";
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
