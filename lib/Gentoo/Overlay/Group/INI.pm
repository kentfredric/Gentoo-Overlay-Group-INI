use strict;
use warnings;

package Gentoo::Overlay::Group::INI;

# ABSTRACT: Load a list of overlays defined in a configuration file.

use Moose;
use Path::Class::Dir;
use File::HomeDir;
use Gentoo::Overlay::Exceptions;

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

Format of the INI files is as follows:

  [Overlays]
  directory = /usr/portage
  directory = /usr/local/portage

=cut

=pkg_var $CFG_PATHS

An array ref of Path::Class::Dir objects to scan for config files.

=cut

our $CFG_PATHS;

=p_func _cf_paths

Fetch C<$CFG_PATHS>, and initialize $CFG_PATHS if it isn't initialized.

  my $path_list = _cf_paths();

=cut

sub _cf_paths {
  return $CFG_PATHS if defined $CFG_PATHS;
  return ( $CFG_PATHS = _init_cf_paths() );
}

=p_func _init_cf_paths

Return the hard-coded array ref of paths to use, or parses C<$ENV{GENTOO_OVERLAY_GROUP_INI_PATH}>.

  my $path_list = _init_cf_paths();

=cut

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

=p_func _enumerate_file_list

Returns a list of file paths to check, in the order they should be checked.

  my @list = _enumerate_file_list();

=cut

sub _enumerate_file_list {
  return map { $_->file('config.ini'), $_->file('Gentoo-Overlay-Group-INI.ini') } @{ _cf_paths() };
}

=p_func _first_config_file

Returns the path to the first file that exists.

  my $first = _first_config_file();

=cut

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

=c_method

Returns a working Overlay::Group object.

  my $group = Gentoo::Overlay::Group::INI->load();


=cut

sub load {
  my ($self) = shift;
  require Config::MVP::Reader;
  require Config::MVP::Reader::INI;
  require Gentoo::Overlay::Group::INI::Assembler;
  require Gentoo::Overlay::Group::INI::Section;
  my $reader = Config::MVP::Reader::INI->new();

  my $asm = Gentoo::Overlay::Group::INI::Assembler->new( section_class => 'Gentoo::Overlay::Group::INI::Section', );

  my $cnf = _first_config_file();

  my $seq = $reader->read_config( $cnf, { assembler => $asm } );
  require Gentoo::Overlay::Group;
  my $group = Gentoo::Overlay::Group->new();
  $group->add_overlay($_) for $seq->{sections}->{Overlays}->construct->directories;
  return $group;

}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
