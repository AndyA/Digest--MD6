#!perl

use strict;
use warnings;

use Data::Dumper;
use File::Spec;
use LWP::Simple qw( mirror is_success status_message $ua );

use constant BASE =>
 'http://groups.csail.mit.edu/cis/md6/revision-2009-04-15/KAT_MCT';
use constant CACHE => 'kat_mct';

-d CACHE or mkdir CACHE or die "Can't create ", CACHE, ": $!\n";

my @schedule = ();
for my $name ( 'ExtremelyLongMsgKAT', 'LongMsgKAT', 'ShortMsgKAT' ) {
  for my $bits ( 224, 256, 384, 512 ) {
    my $src = fetch( BASE, "${name}_${bits}.txt" );
    my @case = load_cases( $src, $bits );
    for my $c ( @case ) {
      test( $c );
    }
  }
}

print Data::Dumper->new( [ \@schedule ], ['@schedule'] )->Useqq( 1 )
 ->Terse( 1 )->Quotekeys( 0 )->Dump;

sub test {
  my $case = shift;
  if ( exists $case->{Len} && exists $case->{Msg} ) {
    return if $case->{Len} > 65;
    push @schedule,
     {
      in => substr(
        unpack( 'B*', pack( 'H*', $case->{Msg} ) ),
        0, $case->{Len}
      ),
      md   => lc $case->{MD},
      bits => $case->{_bits},
     };
  }
}

sub fetch {
  my ( $base, $name ) = @_;
  my $url  = "${base}/${name}";
  my $file = File::Spec->catfile( CACHE, $name );
  my $rc   = mirror( $url, $file );
  die status_message( $rc )
   unless is_success( $rc ) || $rc == 304;
  return $file;
}

sub load_cases {
  my ( $ref, $bits ) = @_;

  my @case = ();
  my $rec  = {};
  open my $fh, '<', $ref or die "Can't read $ref: $!\n";
  while ( <$fh> ) {
    chomp;
    next if /^\s*$/;
    next if /^#/;
    die "Bad line: $_\n" unless /^(\w+)\s*=\s*(.*)$/;
    my ( $k, $v ) = ( $1, $2 );
    $rec->{$k} = $v;
    if ( $k eq 'MD' ) {
      $rec->{_file} = $ref;
      $rec->{_line} = $.;
      $rec->{_bits} = $bits;
      push @case, $rec;
      $rec = {};
    }
  }
  return @case;
}

# vim:ts=2:sw=2:et:ft=perl

