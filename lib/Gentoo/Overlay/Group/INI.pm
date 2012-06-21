use strict;
use warnings;

package Gentoo::Overlay::Group::INI;
BEGIN {
  $Gentoo::Overlay::Group::INI::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Overlay::Group::INI::VERSION = '0.1.0';
}

# ABSTRACT: Load a list of overlays defined in a configuration file.

use Moose;
use Path::Class::Dir;
use File::HomeDir;
use Gentoo::Overlay::Exceptions;




our $CFG_PATHS;


sub _cf_paths {
  return $CFG_PATHS if defined $CFG_PATHS;
  return ( $CFG_PATHS = _init_cf_paths() );
}


sub _init_cf_paths {

  my $cfg_paths = [
    Path::Class::Dir->new( File::HomeDir->my_dist_config('Gentoo-Overlay-Group-INI') ),
    Path::Class::Dir->new( File::HomeDir->my_data )->subdir( '.config', 'Gentoo-Overlay-Group-INI' ),
    Path::Class::Dir->new('/etc/Gentoo-Overlay-Group-INI'),
  ];

  return $cfg_paths if not exists $ENV{GENTOO_OVERLAY_GROUP_INI_PATH};

  $cfg_paths = [];

  for my $path ( split /:/, $ENV{GENTOO_OVERLAY_GROUP_INI_PATH} ) {
    if ( $path =~ /^~\// ) {
      $path =~ s{^~/}{};
      push @{$cfg_paths}, Path::Class::Dir->new( File::HomeDir->my_home )->dir($path);
      next;
    }
    push @{$cfg_paths}, Path::Class::Dir->new($path);
  }
  return $cfg_paths;
}
sub _enumerate_file_list {
  return map { $_->file('config.ini'), $_->file('Gentoo-Overlay-Group-INI.ini') } @{_cf_paths()};
}
sub _first_config_file {
  for my $file (_enumerate_file_list) {
    return $file if -e -f $file;
  }
  return exception(
    ident   => 'no config',
    message => qq{No config file could be found in any of the configured paths:\n%{paths}s\n},
    payload => { paths => ( join q{}, map { "    $_\n" } _enumerate_file_list ), }
  );
}
sub load {
  my ($self) = shift;
  require Config::MVP::Reader;
  require Config::MVP::Reader::INI;
  require Gentoo::Overlay::Group::INI::Assembler;
  require Gentoo::Overlay::Group::INI::Section;
  my $reader = Config::MVP::Reader::INI->new();

  my $asm    = Gentoo::Overlay::Group::INI::Assembler->new(
    section_class => 'Gentoo::Overlay::Group::INI::Section',
  );

  my $cnf = _first_config_file();

  my $seq = $reader->read_config( $cnf, { assembler => $asm } );
  require Gentoo::Overlay::Group;
  my $group = Gentoo::Overlay::Group->new();
  $group->add_overlay( $_ ) for $seq->{sections}->{Overlays}->construct->directories;
  return $group;

}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Gentoo::Overlay::Group::INI - Load a list of overlays defined in a configuration file.

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

Generates a L<< C<Gentoo::Overlay::B<Group>> object|Gentoo::Overlay::Group >> using a configuration file from your environment.

  require Gentoo::Overlay::Group::INI;
  my $group = Gentoo::Overlay::Group::INI->load();

Currently, the following paths are checked:

  ~/.perl/Gentoo-Overlay-Group-INI/config.ini
  ~/.perl/Gentoo-Overlay-Group-INI/Gentoo-Overlay-Group-INI.ini
  ~/.config/Gentoo-Overlay-Group-INI/config.ini
  ~/.config/Gentoo-Overlay-Group-INI/Gentoo-Overlay-Group-INI.ini
  /etc/Gentoo-Overlay-Group-INI/config.ini
  /etc/Gentoo-Overlay-Group-INI/Gentoo-Overlay-Group-INI.ini

If you have set C<GENTOO_OVERLAY_GROUP_INI_PATH>, it will be split by C<B<:>> and each part scanned:

  $ENV{GENTOO_OVERLAY_GROUP_INI_PATH} = "/a:/b"

  /a/config.ini
  /a/Gentoo-Overlay-Group-INI.ini
  /b/config.ini
  /b/Gentoo-Overlay-Group-INI.ini

If any of the path parts start with C<~/> , those parts will be expanded to your "Home" directory.

=head1 CLASS METHODS

=head2

Returns a working Overlay::Group object.

  my $group = Gentoo::Overlay::Group::INI->load();

=head1 PACKAGE VARIABLES

=head2 $CFG_PATHS

An array ref of Path::Class::Dir objects to scan for config files.

=head1 PRIVATE FUNCTIONS

=head2 _cf_paths

Fetch C<$CFG_PATHS>, and initialize $CFG_PATHS if it isn't initialized.

  my $path_list = _cf_paths();

=head2 _init_cf_paths

Return the hard-coded array ref of paths to use, or parses C<$ENV{GENTOO_OVERLAY_GROUP_INI_PATH}>.

  my $path_list = _init_cf_paths();

=head2 _enumerate_file_list

Returns a list of file paths to check, in the order they should be checked.

  my @list = _enumerate_file_list();

=head2 _first_config_file

Returns the path to the first file that exists.

  my $first = _first_config_file();

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

