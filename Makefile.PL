#!perl -w

require 5.008;

use strict;
use warnings;
use lib qw( inc );

use Config qw(%Config);
use ExtUtils::MakeMaker ();
use File::Spec;
use Devel::CheckLib;

# Check that we have a C compiler
check_lib_or_exit();

my @extra = ();
if ( $^O eq 'VMS' ) {
  if ( defined( $Config{ccname} ) ) {
    if ( grep( /VMS_VAX/, @INC ) && ( $Config{ccname} eq 'DEC' ) ) {
      # VAX compiler optimizer even as late as v6.4 gets stuck
      push( @extra, OPTIMIZE => "/Optimize=(NODISJOINT)" );
    }
  }
}

push(@extra, INSTALLDIRS => 'perl') if $] >= 5.008 && $] < 5.012;

my $oe = $Config{obj_ext};
my @obj = ( "MD6$oe", make_obj_list( 'src', $oe, 'md6sum.c' ) );

WriteMakefile(
  NAME             => 'Digest::MD6',
  VERSION_FROM     => 'MD6.pm',
  ABSTRACT         => 'Perl interface to the MD6 algorithm',
  AUTHOR           => 'Andy Armstrong <andy@hexten.net>',
  LICENSE          => 'perl',
  MIN_PERL_VERSION => 5.006,
  PREREQ_PM        => {
    'Digest::base' => '1.00',
    'File::Spec'   => 0,
    'Test::More'   => 0,
    'XSLoader'     => 0,
  },
  TEST_REQUIRES    => {
    'LWP::Simple' => 0,
  },
  META_MERGE       => {
    resources  => {
      repository => 'https://github.com/AndyA/Digest--MD6',
    }
  },
  @extra,
  #DIR => ['src'],
  #  OPTIMIZE => '-g',
  OBJECT => join( ' ', @obj ),
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub make_obj_list {
  my ( $dir, $ext, @exc ) = @_;
  my $exc = join '|', map { "(?:\Q$_\E)" } @exc;
  opendir my $dh, $dir or die "Can't read $dir: $!\n";
  return map { File::Spec->catfile( $dir, $_ ) }
   map { $_ =~ s/\.c$/$ext/ && $_ }
   grep { /\.c$/i }
   grep { !/^$exc$/ }
   grep { !/^\./ } readdir $dh;
}

BEGIN {
  # compatibility with older versions of MakeMaker
  my $developer = -d ".git";
  my %mm_req = (
    LICENCE          => 6.31,
    TEST_REQUIRES    => 6.45,
    META_MERGE       => 6.45,
    META_ADD         => 6.45,
    MIN_PERL_VERSION => 6.48,
  );
  undef(*WriteMakefile);
  *WriteMakefile = sub {
    my %arg = @_;
    for (keys %mm_req) {
      unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
        warn "$_ $@" if $developer;
        delete $arg{$_};
      }
    }
    ExtUtils::MakeMaker::WriteMakefile(%arg);
  };
}

{
  package MY;

  use Config;

  sub const_cccmd {
    my $ret = shift->SUPER::const_cccmd(@_);
    return q{} unless $ret;

    if ( $Config{cc} =~ /^cl\b/i ) {
      warn 'you are using MSVC... we may not have gotten some options quite right.';
      $ret .= ' /Fo$@';
    }
    else {
      $ret .= ' -o $@';
    }

    return $ret;
  }
}
