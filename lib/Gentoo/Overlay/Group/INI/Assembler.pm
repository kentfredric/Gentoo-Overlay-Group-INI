use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Assembler;

# ABSTRACT:

use Moose;
extends 'Config::MVP::Assembler';

sub expand_package {
  return "Gentoo::Overlay::Group::INI::Section::$_[1]";
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
