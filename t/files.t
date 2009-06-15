BEGIN {
	if ($ENV{PERL_CORE}) {
        	chdir 't' if -d 't';
        	@INC = '../lib';
        }
}

print "1..3\n";

use strict;
use Digest::MD6 qw(md6 md6_hex md6_base64);

# To update the EBCDIC section even on a Latin 1 platform,
# run this script with $ENV{EBCDIC_MD6SUM} set to a true value.
# (You'll need to have Perl 5.7.3 or later, to have the Encode installed.)
# (And remember that under the Perl core distribution you should
#  also have the $ENV{PERL_CORE} set to a true value.)
# Similarly, to update MacOS section, run with $ENV{MAC_MD6SUM} set.

my $EXPECT;
if (ord "A" == 193) { # EBCDIC
    $EXPECT = <<EOT;
11e8028ee426273db6b6db270a8bb38c  README
6e556382813f67120863f4f91b7fcdc2  MD6.xs
276da0aa4e9a08b7fe09430c9c5690aa  rfc1321.txt
EOT
} elsif ("\n" eq "\015") { # MacOS
    $EXPECT = <<EOT;
c95549c6c5e1e1c078b27042f1dc850f  README
7aa380c810bc7c1a0bec22cf32bc50d4  MD6.xs
754b9db19f79dbc4992f7166eb0f37ce  rfc1321.txt
EOT
} else {
    # This is the output of: 'md6sum README MD6.xs rfc1321.txt'
    $EXPECT = <<EOT;
c95549c6c5e1e1c078b27042f1dc850f  README
7aa380c810bc7c1a0bec22cf32bc50d4  MD6.xs
754b9db19f79dbc4992f7166eb0f37ce  rfc1321.txt
EOT
}

if (!(-f "README") && -f "../README") {
   chdir("..") or die "Can't chdir: $!";
}

my $testno = 0;

my $B64 = 1;
eval { require MIME::Base64; };
if ($@) {
    print "# $@: Will not test base64 methods\n";
    $B64 = 0;
}

for (split /^/, $EXPECT) {
     my($md6hex, $file) = split ' ';
     my $base = $file;
#     print "# $base\n";
     if ($ENV{PERL_CORE}) {
         if ($file eq 'rfc1321.txt') { # Don't have it in core.
	     print "ok ", ++$testno, " # Skip: PERL_CORE\n";
	     next;
	 }
         use File::Spec;
	 my @path = qw(ext Digest-MD6);
	 my $path = File::Spec->updir;
	 while (@path) {
	   $path = File::Spec->catdir($path, shift @path);
	 }
	 $file = File::Spec->catfile($path, $file);
     }
#     print "# file = $file\n";
     unless (-f $file) {
	warn "No such file: $file\n";
	next;
     }
     if ($ENV{EBCDIC_MD6SUM}) {
         require Encode;
	 my $data = cat_file($file);	
	 Encode::from_to($data, 'latin1', 'cp1047');
	 print md6_hex($data), "  $base\n";
	 next;
     }
     if ($ENV{MAC_MD6SUM}) {
         require Encode;
	 my $data = cat_file($file);	
	 Encode::from_to($data, 'latin1', 'MacRoman');
	 print md6_hex($data), "  $base\n";
	 next;
     }
     my $md6bin = pack("H*", $md6hex);
     my $md6b64;
     if ($B64) {
	 $md6b64 = MIME::Base64::encode($md6bin, "");
	 chop($md6b64); chop($md6b64);   # remove padding
     }
     my $failed;
     my $got;

     if (digest_file($file, 'digest') ne $md6bin) {
	 print "$file: Bad digest\n";
	 $failed++;
     }

     if (($got = digest_file($file, 'hexdigest')) ne $md6hex) {
	 print "$file: Bad hexdigest: got $got expected $md6hex\n";
	 $failed++;
     }

     if ($B64 && digest_file($file, 'b64digest') ne $md6b64) {
	 print "$file: Bad b64digest\n";
	 $failed++;
     }

     my $data = cat_file($file);
     if (md6($data) ne $md6bin) {
	 print "$file: md6() failed\n";
	 $failed++;
     }
     if (md6_hex($data) ne $md6hex) {
	 print "$file: md6_hex() failed\n";
	 $failed++;
     }
     if ($B64 && md6_base64($data) ne $md6b64) {
	 print "$file: md6_base64() failed\n";
	 $failed++;
     }

     if (Digest::MD6->new->add($data)->digest ne $md6bin) {
	 print "$file: MD6->new->add(...)->digest failed\n";
	 $failed++;
     }
     if (Digest::MD6->new->add($data)->hexdigest ne $md6hex) {
	 print "$file: MD6->new->add(...)->hexdigest failed\n";
	 $failed++;
     }
     if ($B64 && Digest::MD6->new->add($data)->b64digest ne $md6b64) {
	 print "$file: MD6->new->add(...)->b64digest failed\n";
	 $failed++;
     }

     my @data = split //, $data;
     if (md6(@data) ne $md6bin) {
	 print "$file: md6(\@data) failed\n";
	 $failed++;
     }
     if (Digest::MD6->new->add(@data)->digest ne $md6bin) {
	 print "$file: MD6->new->add(\@data)->digest failed\n";
	 $failed++;
     }
     my $md6 = Digest::MD6->new;
     for (@data) {
	 $md6->add($_);
     }
     if ($md6->digest ne $md6bin) {
	 print "$file: $md6->add()-loop failed\n";
	 $failed++;
     }

     print "not " if $failed;
     print "ok ", ++$testno, "\n";
}


sub digest_file
{
    my($file, $method) = @_;
    $method ||= "digest";
    #print "$file $method\n";

    open(FILE, $file) or die "Can't open $file: $!";
    my $digest = Digest::MD6->new->addfile(*FILE)->$method();
    close(FILE);

    $digest;
}

sub cat_file
{
    my($file) = @_;
    local $/;  # slurp
    open(FILE, $file) or die "Can't open $file: $!";

    # For PerlIO in case of UTF-8 locales.
    eval 'binmode(FILE, ":bytes")' if $] >= 5.008;

    my $tmp = <FILE>;
    close(FILE);
    $tmp;
}

