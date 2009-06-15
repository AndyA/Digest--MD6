use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Digest::MD6',
    license           => 'perl',
    dist_author       => 'Andy Armstrong <andy@hexten.net>',
    dist_version_from => 'lib/Digest/MD6.pm',
    requires          => {
        'Test::More' => 0,
    },
    add_to_cleanup => ['Digest-MD6-*'],
);

$builder->create_build_script();
