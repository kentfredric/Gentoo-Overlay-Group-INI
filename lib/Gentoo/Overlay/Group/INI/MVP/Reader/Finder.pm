use strict;
use warnings;

package Gentoo::Overlay::Group::INI::MVP::Finder;

# ABSTRACT: Reader for INI Files

use Moose;
use Config::MVP::Reader 2.101540; # if_none
extends 'Config::MVP::Reader::Finder';
use namespace::autoclean;
 
use Gentoo::Overlay::Group::INI::MVP::Assembler;
 
sub default_search_path {
  # Look for readers 
  #
  #  INI -> Config::MVP::Reader::INI
  #  Perl -> Gentoo::Overlay::Group::INI::MVP::Reader::Perl
  #
  #
  return qw(Gentoo::Overlay::Group::INI::MVP::Reader Config::MVP::Reader);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
