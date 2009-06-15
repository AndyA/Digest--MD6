#!perl -w

use Test qw(plan ok);
plan tests => 2;

use Digest::MD6;

my $md6 = Digest::MD6->new;

if ($Digest::base::VERSION) {
    $md6->add_bits("01111111");
    ok($md6->hexdigest, "83acb6e67e50e31db6ed341dd2de1595");
    eval {
	$md6->add_bits("0111");
    };
    ok($@ =~ /must be multiple of 8/);
}
else {
    print "# No Digest::base\n";
    eval {
	$md6->add_bits("foo");
    };
    ok($@ =~ /^Can\'t locate Digest\/base\.pm in \@INC/);
    ok(1);  # dummy
}

