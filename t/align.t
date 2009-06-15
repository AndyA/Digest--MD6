BEGIN {
	if ($ENV{PERL_CORE}) {
	        chdir 't' if -d 't';
	        @INC = '../lib';
	}
}

# Test that md6 works on unaligned memory blocks

print "1..1\n";

use strict;
use Digest::MD6 qw(md6_hex);

my $str = "\100" x 20;
substr($str, 0, 1) = "";  # chopping off first char makes the string unaligned

#use Devel::Peek; Dump($str); 

print "not " unless md6_hex($str) eq "c7ebb510e59ee96f404f288d14cc656a";
print "ok 1\n";

