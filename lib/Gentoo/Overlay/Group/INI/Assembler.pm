use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Assembler;
BEGIN {
  $Gentoo::Overlay::Group::INI::Assembler::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Overlay::Group::INI::Assembler::VERSION = '0.1.0';
}

# ABSTRACT:

use Moose;
extends 'Config::MVP::Assembler';

sub expand_package {
  return "Gentoo::Overlay::Group::INI::Section::$_[1]";
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Gentoo::Overlay::Group::INI::Assembler - use Moose;

=head1 VERSION

version 0.1.0

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

