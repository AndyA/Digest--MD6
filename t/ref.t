#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Digest::MD6 qw( md6_hex md6_base64 );

$Digest::MD6::HASH_LENGTH = 256;
is md6_hex( 'abc' ),
 '230637d4e6845cf0d092b558e87625f03881dd53a7439da34cf3b94ed0d8b2c5',
 'hex hash of abc';

is md6_base64( 'abc' ), 'IwY31OaEXPDQkrVY6HYl8DiB3VOnQ52jTPO5TtDYssU',
 'base64 hash of abc'

 # vim:ts=2:sw=2:et:ft=perl

