#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use MIME::Base64;

use constant MD6SUM => 'tools/md6sum';

my @length = ( 224, 384, ( map { 2**$_ } 0 .. 9 ) );
my @message = ( 'abc', '', 'a', '0' );

my @cases = ();

for my $l ( @length ) {
  for my $m ( @message ) {
    my $hex = md6sum( $l, $m );
    ( my $b64 = encode_base64( pack( 'H*', $hex ), '' ) ) =~ s/=+$//;
    my $expect = ( $l + 5 ) / 6;
    $b64 = substr( $b64, 0, $expect );
    push @cases,
     {
      hl      => $l,
      in      => $m,
      out_hex => $hex,
      out_b64 => $b64,
     };
  }
}

my $ref = Data::Dumper->new( [ \@cases ], [qw($cases)] )->Useqq( 1 )
 ->Purity( 1 )->Terse( 1 )->Dump;
$ref =~ s/"/'/g;
$ref =~ s/'(\w+)'\s+=>/$1 =>/g;
1 while $ref =~ s/^([^']+)'([^']{50,50})([^']+)'/$1'$2'\n.'$3'/msg;
my @lines = split /\n/, $ref;
shift @lines;
pop @lines;
print join "\n", 'my @cases = (', @lines, ');';

sub md6sum {
  my ( $d, $M ) = @_;
  my @cmd = ( MD6SUM, "-d$d", "-M$M" );
  #  print join( ' ', @cmd ), "\n";
  my $sum = '';
  open my $fh, '-|', @cmd or die "Can't run md6sum: $?\n";
  while ( <$fh> ) {
    chomp;
    $sum = $1 if /^([0-9a-f]+)/;
  }
  close $fh or die "Can't run md6sum: $?\n";
  die "No sum found\n" unless $sum =~ /^[0-9a-f]+$/;
  return $sum;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

