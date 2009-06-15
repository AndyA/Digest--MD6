#!perl -w

require 5.008;

use strict;
use warnings;

use Config qw(%Config);
use ExtUtils::MakeMaker;

my @extra = ();
if ( $^O eq 'VMS' ) {
  if ( defined( $Config{ccname} ) ) {
    if ( grep( /VMS_VAX/, @INC ) && ( $Config{ccname} eq 'DEC' ) ) {
      # VAX compiler optimizer even as late as v6.4 gets stuck
      push( @extra, OPTIMIZE => "/Optimize=(NODISJOINT)" );
    }
  }
}

push( @extra, 'INSTALLDIRS' => 'perl' )
 if $] >= 5.008;
push @extra, 'LICENSE' => 'perl'
 if eval( $ExtUtils::MakeMaker::VERSION ) >= "6.30";

my $oe = $Config{obj_ext};
my @obj = map { $_ . $oe } qw(
 MD6 src/*
);

WriteMakefile(
  NAME         => 'Digest::MD6',
  AUTHOR       => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM => 'MD6.pm',
  PREREQ_PM    => {
    'Digest::base' => '1.00',
    'File::Spec'   => 0,
    'Test::More'   => 0,
    'XSLoader'     => 0,
  },
  @extra,
  DIR      => ['src'],
  OPTIMIZE => '-g',
  OBJECT   => join( ' ', @obj ),
  dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
