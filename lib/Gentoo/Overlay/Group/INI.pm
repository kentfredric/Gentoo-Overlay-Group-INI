use strict;
use warnings;

package Gentoo::Overlay::Group::INI;

# ABSTRACT: Load a list of overlays defined in a configuration file.

use Moose;
use Path::Tiny;
use File::HomeDir;
use Gentoo::Overlay::Exceptions qw( :all );

=head1 SYNOPSIS

Generates a L<< C<Gentoo::Overlay::B<Group>> object|Gentoo::Overlay::Group >> using a configuration file from your environment.

  require Gentoo::Overlay::Group::INI;
  my $group = Gentoo::Overlay::Group::INI->load();

Currently, the following paths are checked:

  ~/.config/Perl/Gentoo-Overlay-Group-INI/config.ini #  'my_dist_config' dir
  ~/.config/Perl/Gentoo-Overlay-Group-INI/Gentoo-Overlay-Group-INI.ini
  ~/.local/share/Perl/dist/Gentoo-Overlay-Group-INI/config.ini  # 'my_dist_data' dir
  ~/.local/share/Perl/dist/Gentoo-Overlay-Group-INI/Gentoo-Overlay-Group-INI.ini
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

An array ref of Path::Tiny objects to scan for config files.

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

## no critic (RegularExpressions)
sub _init_cf_paths {
  my $cfg_paths = [
    Path::Tiny::path( File::HomeDir->my_dist_config( 'Gentoo-Overlay-Group-INI', { create => 1 } ) ),
    Path::Tiny::path( File::HomeDir->my_dist_data( 'Gentoo-Overlay-Group-INI', { create => 1 } ) ),
    Path::Tiny::path('/etc/Gentoo-Overlay-Group-INI'),
  ];

  return $cfg_paths if not exists $ENV{GENTOO_OVERLAY_GROUP_INI_PATH};

  $cfg_paths = [];

  for my $path ( split /:/, $ENV{GENTOO_OVERLAY_GROUP_INI_PATH} ) {
    if ( $path =~ /^~\// ) {
      $path =~ s{^~/}{};
      push @{$cfg_paths}, Path::Tiny::path( File::HomeDir->my_home )->child($path);
      next;
    }
    push @{$cfg_paths}, Path::Tiny::path($path);
  }
  return $cfg_paths;
}
##  use critic

=p_func _enumerate_file_list

Returns a list of file paths to check, in the order they should be checked.

  my @list = _enumerate_file_list();

=cut

sub _enumerate_file_list {
  return map { ( $_->child('config.ini'), $_->child('Gentoo-Overlay-Group-INI.ini') ) } @{ _cf_paths() };
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

=c_method load

Returns a working Overlay::Group object.

  my $group = Gentoo::Overlay::Group::INI->load();


=cut

sub load {
  my ($self) = @_;

  my $seq = $self->_parse();

  return $seq->section_named('Overlays')->construct->overlay_group;

}

=c_method load_named

Return an inflated arbitrary section:

  # A "self-named" overlay section
  my $section = Gentoo::Overlay::Group::INI->load_named('Overlay');
  # A 'custom named overlay section, ie:
  # [ Overlay / foo ]
  my $section = Gentoo::Overlay::Group::INI->load_named('foo');

=cut

sub load_named {
  my ( $self, $name, $config ) = @_;
  $config //= {};
  my $seq     = $self->_parse();
  my $section = $seq->section_named($name);
  return unless defined $section;
  if ( not defined $config->{'-inflate'} or $config->{'-inflate'} ) {
    return $section->construct;
  }
  return $section;
}

=c_method load_all_does

Return all sections in a config file that C<do> the given role.

  my ( @sections ) = Gentoo::Overlay::Group::INI->load_all_does('Some::Role');

=cut

sub load_all_does {
  my ( $self, $role, $config ) = @_;

  $config //= {};
  my $real_role = String::RewritePrefix->rewrite(
    {
      q{::} => q{Gentoo::Overlay::Group::INI::Section::},
      q{}   => q{},
    },
    $role,
  );

  my $seq = $self->_parse();
  my (@items) = grep { $_->package->does($real_role) } $seq->sections;
  if ( not defined $config->{'-inflate'} or $config->{'-inflate'} ) {
    return map { $_->construct } @items;
  }
  return @items;

}

=c_method load_all_isa

Return all sections in a config file that inherit the given class.

  my ( @sections ) = Gentoo::Overlay::Group::INI->load_all_isa('Gentoo::Overlay::Group::Section::Overlay');


=cut

sub load_all_isa {
  my ( $self, $class, $config ) = @_;
  require String::RewritePrefix;

  my $real_class = String::RewritePrefix->rewrite(
    {
      q{::} => q{Gentoo::Overlay::Group::INI::Section::},
      q{}   => q{},
    },
    $class,
  );
  $config //= {};
  my $seq = $self->_parse();
  my (@items) = grep { $_->package->isa($real_class) } $seq->sections;
  if ( not defined $config->{'-inflate'} or $config->{'-inflate'} ) {
    return map { $_->construct } @items;
  }
  return @items;

}

=p_method _parse

=cut

sub _parse {
  require Config::MVP::Reader;
  require Config::MVP::Reader::INI;
  require Gentoo::Overlay::Group::INI::Assembler;
  require Gentoo::Overlay::Group::INI::Section;

  my $reader = Config::MVP::Reader::INI->new();

  my $asm = Gentoo::Overlay::Group::INI::Assembler->new( section_class => 'Gentoo::Overlay::Group::INI::Section', );

  my $cnf = _first_config_file();

  return $reader->read_config( $cnf, { assembler => $asm } );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
