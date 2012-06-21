use strict;
use warnings;

package Gentoo::Overlay::Group::INI::MVP::Assembler;

# ABSTRACT:

use Moose;
extends 'Config::MVP::Assembler';
use namespace::autoclean;


__PACKAGE__->meta->make_immutable;
no Moose;

1;
