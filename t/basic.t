use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Path::Class qw( dir file );
use FindBin;
use autodie;

my $base = dir("$FindBin::Bin/../corpus");

my @overlays = ( $base->subdir("overlay_4")->stringify, $base->subdir("overlay_5")->stringify,, );

use File::Tempdir;

my $tmpdir = File::Tempdir->new();
my $homedir = File::Tempdir->new();

my $dir = dir( $tmpdir->name );

open my $fh, '>', $dir->file('config.ini')->stringify;
$fh->print("[Overlays]\n");
$fh->print("directory = $_\n") for @overlays;
$fh->flush;
$fh->close;

local $ENV{GENTOO_OVERLAY_GROUP_INI_PATH} = $dir->stringify;
local $ENV{HOME} = $homedir->name;

# FILENAME: basic.t
# CREATED: 22/06/12 07:13:46 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test basic functionality

use Gentoo::Overlay::Group::INI;

is(
  exception {

    Gentoo::Overlay::Group::INI::_cf_paths();

  },
  undef,
  "Setup is success!"
);
is(
  exception {

    Gentoo::Overlay::Group::INI::_enumerate_file_list();

  },
  undef,
  "File list is success!"
);
my $first;

is(
  exception {
    $first = Gentoo::Overlay::Group::INI::_first_config_file();
  },
  undef,
  'Can find config'
);

note "Found File : " . $first->stringify;

my $config = Gentoo::Overlay::Group::INI->load();

isa_ok( $config, 'Gentoo::Overlay::Group' );
done_testing;

