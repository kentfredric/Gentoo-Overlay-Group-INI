use strict;
use warnings;

package Gentoo::Overlay::Group::INI;

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
