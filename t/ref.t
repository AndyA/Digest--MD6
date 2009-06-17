#!perl

use strict;
use warnings;

use Test::More;
use Digest::MD6 qw( md6 md6_hex md6_base64 );
use Data::Hexdumper;

my $have_base64 = eval { require MIME::Base64 };

my @cases = (
  {
    out_b64 => 'UQww5CAqXN2KTyrpvuu29ZiBKIl5N2FdUubSKA',
    hl      => 224,
    out_hex => '510c30e4202a5cdd8a4f2ae9beebb6f598812889'
     . '7937615d52e6d228',
    in => 'abc'
  },
  {
    out_b64 => '0gkaoq0X84xRreJpfyTK/DiUxhfHf/4Q/ceryw',
    hl      => 224,
    out_hex => 'd2091aa2ad17f38c51ade2697f24cafc3894c617'
     . 'c77ffe10fdc7abcb',
    in => ''
  },
  {
    out_b64 => 'Bd6HkqluAkyAbrgV+fMAU8+fG1BmEEekk0Ehtw',
    hl      => 224,
    out_hex => '05de8792a96e024c806eb815f9f30053cf9f1b50'
     . '661047a4934121b7',
    in => 'a'
  },
  {
    out_b64 => 'YaycdginM64Gs369cp29I5XgiqPgjC5kX5luDA',
    hl      => 224,
    out_hex => '61ac9c7608a733ae06b37ebd729dbd2395e08aa3'
     . 'e08c2e645f996e0c',
    in => 0
  },
  {
    out_b64 => '4sbTHdiHLL1aEgdIHNrFgQVNE6TU/mhUMxzYzz58'
     . 'uvut3W4lF5crj/V83EgG0JGQ',
    hl      => 384,
    out_hex => 'e2c6d31dd8872cbd5a1207481cdac581054d13a4'
     . 'd4fe6854331cd8cf3e7cbafbaddd6e2517972b8f'
     . 'f57cdc4806d09190',
    in => 'abc'
  },
  {
    out_b64 => 'sLr//O6+hWwe/34bovU5aT+Ci1Muv2CunBbLw0mQ'
     . 'IEAblCrCWzELIieylUzKzC8f',
    hl      => 384,
    out_hex => 'b0bafffceebe856c1eff7e1ba2f539693f828b53'
     . '2ebf60ae9c16cbc3499020401b942ac25b310b22'
     . '27b2954ccacc2f1f',
    in => ''
  },
  {
    out_b64 => 'pAyNBZSVonj63TC5bjsiJ3WAkMdZuTQZcmW/Yyyr'
     . '+FR6dCnlMW1JbCod2ujSfofu',
    hl      => 384,
    out_hex => 'a40c8d059495a278fadd30b96e3b2227758090c7'
     . '59b934197265bf632cabf8547a7429e5316d496c'
     . '2a1ddae8d27e87ee',
    in => 'a'
  },
  {
    out_b64 => 'mpe5JlUrt7xhAV5D6UMOPEmnZyTG1uCzHBT5xbtM'
     . 'fb941cWDQBl22nE5gZ3BbFk0',
    hl      => 384,
    out_hex => '9a97b926552bb7bc61015e43e9430e3c49a76724'
     . 'c6d6e0b31c14f9c5bb4c7dbf78d5c583401976da'
     . '7139819dc16c5934',
    in => 0
  },
  {
    out_b64 => '6A',
    hl      => 8,
    out_hex => 'e8',
    in      => 'abc'
  },
  {
    out_b64 => 'Pg',
    hl      => 8,
    out_hex => '3e',
    in      => ''
  },
  {
    out_b64 => 'LA',
    hl      => 8,
    out_hex => '2c',
    in      => 'a'
  },
  {
    out_b64 => 'qA',
    hl      => 8,
    out_hex => 'a8',
    in      => 0
  },
  {
    out_b64 => 'LJE',
    hl      => 16,
    out_hex => '2c91',
    in      => 'abc'
  },
  {
    out_b64 => 'C5E',
    hl      => 16,
    out_hex => '0b91',
    in      => ''
  },
  {
    out_b64 => 'w5A',
    hl      => 16,
    out_hex => 'c390',
    in      => 'a'
  },
  {
    out_b64 => 'dZM',
    hl      => 16,
    out_hex => 7593,
    in      => 0
  },
  {
    out_b64 => 'z9iWeg',
    hl      => 32,
    out_hex => 'cfd8967a',
    in      => 'abc'
  },
  {
    out_b64 => '+iSySg',
    hl      => 32,
    out_hex => 'fa24b24a',
    in      => ''
  },
  {
    out_b64 => 'JJFhfg',
    hl      => 32,
    out_hex => '2491617e',
    in      => 'a'
  },
  {
    out_b64 => 'gDKOAw',
    hl      => 32,
    out_hex => '80328e03',
    in      => 0
  },
  {
    out_b64 => 'eqZhtL0YAoY',
    hl      => 64,
    out_hex => '7aa661b4bd180286',
    in      => 'abc'
  },
  {
    out_b64 => 'E9pXOPRFHbA',
    hl      => 64,
    out_hex => '13da5738f4451db0',
    in      => ''
  },
  {
    out_b64 => 'MtEwMKaBXpU',
    hl      => 64,
    out_hex => '32d13030a6815e95',
    in      => 'a'
  },
  {
    out_b64 => 'F9Bz1NOLVAA',
    hl      => 64,
    out_hex => '17d073d4d38b5400',
    in      => 0
  },
  {
    out_b64 => 'jbUNec9C/n0YB+uqFTKcYQ',
    hl      => 128,
    out_hex => '8db50d79cf42fe7d1807ebaa15329c61',
    in      => 'abc'
  },
  {
    out_b64 => 'Ay91s8oCo5MZaoGDKL0y6A',
    hl      => 128,
    out_hex => '032f75b3ca02a393196a818328bd32e8',
    in      => ''
  },
  {
    out_b64 => 'u2kcG/pLQ0UpLrNfNkkZ6g',
    hl      => 128,
    out_hex => 'bb691c1bfa4b4345292eb35f364919ea',
    in      => 'a'
  },
  {
    out_b64 => 'dGTLJCeksEvAypJlNxHjpQ',
    hl      => 128,
    out_hex => '7464cb2427a4b04bc0ca92653711e3a5',
    in      => 0
  },
  {
    out_b64 => 'IwY31OaEXPDQkrVY6HYl8DiB3VOnQ52jTPO5TtDY' . 'ssU',
    hl      => 256,
    out_hex => '230637d4e6845cf0d092b558e87625f03881dd53'
     . 'a7439da34cf3b94ed0d8b2c5',
    in => 'abc'
  },
  {
    out_b64 => 'vKOLJKgEqjfYIdMa8A9VmCMBIsW7/ExK1e1A5CWP' . 'BMo',
    hl      => 256,
    out_hex => 'bca38b24a804aa37d821d31af00f5598230122c5'
     . 'bbfc4c4ad5ed40e4258f04ca',
    in => ''
  },
  {
    out_b64 => 'KwppeggcISaVFGQKq010/6/rPAIS32jOkpIgh8ab' . 'Cnc',
    hl      => 256,
    out_hex => '2b0a697a081c21269514640aab4d74ffafeb3c02'
     . '12df68ce92922087c69b0a77',
    in => 'a'
  },
  {
    out_b64 => '2XlkK5Bgzi3CQYO/OsbZrktU8UTTrySTXpuLyQen' . 'K04',
    hl      => 256,
    out_hex => 'd979642b9060ce2dc24183bf3ac6d9ae4b54f144'
     . 'd3af24935e9b8bc907a72b4e',
    in => 0
  },
  {
    out_b64 => 'AJGCRSceN3p/+yArkPO9pUd9j+qxLYo6iZTrxV/m'
     . '50yoNBUgAy7uo/3viS8ogjePY2ISr0smg8z4C/Al'
     . 't9m0Vw',
    hl      => 512,
    out_hex => '00918245271e377a7ffb202b90f3bda5477d8fea'
     . 'b12d8a3a8994ebc55fe6e74ca8341520032eeea3'
     . 'fdef892f2882378f636212af4b2683ccf80bf025'
     . 'b7d9b457',
    in => 'abc'
  },
  {
    out_b64 => 'a38zghosBg7N2Brv3eov08RyAnDhhlT0ywjs5JzL'
     . 'Rp+L7u58gxIGvVd/nyYw2Rd5eSA6lInkfgTfTm3q'
     . 'oPjgwA',
    hl      => 512,
    out_hex => '6b7f33821a2c060ecdd81aefddea2fd3c4720270'
     . 'e18654f4cb08ece49ccb469f8beeee7c831206bd'
     . '577f9f2630d9177979203a9489e47e04df4e6dea'
     . 'a0f8e0c0',
    in => ''
  },
  {
    out_b64 => 'wOThistpzRp+WiCYH+bMb3tbcOgU06E7BawpKrp0'
     . 'wNjJ00whFBTnq3ValVnCchHNdJ/D6wmuZw4TiIF0'
     . 'O41QUQ',
    hl      => 512,
    out_hex => 'c0e4e18acb69cd1a7e5a20981fe6cc6f7b5b70e8'
     . '14d3a13b05ac292aba74c0d8c9d34c211414e7ab'
     . '755a9559c27211cd749fc3eb09ae670e13888174'
     . '3b8d5051',
    in => 'a'
  },
  {
    out_b64 => 'BX4cQEaKtWYd79vNO/Zx05gRY3PbLnqwrcawhx1g'
     . 'Pto5z3JVNhykVlQxV/vgmEe1AVhtcB1TVk+rZRvS'
     . '9J3NpA',
    hl      => 512,
    out_hex => '057e1c40468ab5661defdbcd3bf671d398116373'
     . 'db2e7ab0adc6b0871d603eda39cf7255361ca456'
     . '543157fbe09847b501586d701d53564fab651bd2'
     . 'f49dcda4',
    in => 0
  }
);

plan tests => @cases * ( $have_base64 ? 5 : 4 );

sub hd {
  my $data = shift;
  return "(no data)" unless length $data;
  return hexdump( data => $data );
}

sub ish($$$) {
  my ( $got, $want, $msg ) = @_;
  unless ( is( $got, $want, $msg ) ) {
    diag "got:\n",  hd( $got );
    diag "want:\n", hd( $want );
  }
}

for my $case ( @cases ) {
  my $name = join '/', @{$case}{ 'hl', 'in' };
  my $bin = pack 'H*', $case->{out_hex};

  {
    local $Digest::MD6::HASH_LENGTH = $case->{hl};

    is md6( $case->{in} ), $bin, "$name: bin";
    is md6_hex( $case->{in} ),    $case->{out_hex}, "$name: hex";
    is md6_base64( $case->{in} ), $case->{out_b64}, "$name: base64";
  }

  my $md6 = Digest::MD6->new( $case->{hl} );
  $md6->add( split //, $case->{in} );
  is $md6->hexdigest, $case->{out_hex}, "$name: hex via oo i/f";

  if ( $have_base64 ) {
    ( my $b64 = MIME::Base64::encode_base64( $bin, '' ) ) =~ s/=+$//;
    is $case->{out_b64}, $b64, "$name: our base64 rep is good";
  }
}

# vim:ts=2:sw=2:et:ft=perl

