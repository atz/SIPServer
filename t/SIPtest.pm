package SIPtest;

use Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(run_sip_tests no_tagged_fields);
use strict;
use warnings;

# The number of tests is set in run_sip_tests() below, based
# on the size of the array of tests.
use Test::More;

use IO::Socket::INET;
use Sip qw(:all);
use Sip::Checksum qw(verify_cksum);

# If a message has no tagged fields, we can just return true
# for that message's field test.
sub no_tagged_fields {
    return 1;
}

sub one_msg {
    my ($sock, $test, $seqno) = @_;
    my $resp;

    ok(write_msg({seqno => $seqno}, $test->{msg}, $sock), "send $test->{id}");
    ok($resp = <$sock>, "read $test->{id}");
    chomp($resp);
    ok(verify_cksum($resp), "checksum $test->{id}");
    like($resp, $test->{pat}, "match leader $test->{id}");
  TODO: {
      local $TODO = "$test->{id} field tests not written yet"
	  unless $test->{fields};

      ok($test->{fields} && &{$test->{fields}}($resp), "tagged fields $test->{id}");
  }
}

sub run_sip_tests {
    my ($sock, $seqno);

    $Sip::error_detection = 1;
    $/ = "\r";

    $sock = new IO::Socket::INET(PeerAddr => 'localhost:5300',
				 Type     => SOCK_STREAM);
    BAIL_OUT('failed to create connection to server') unless $sock;

    $seqno = 1;

    plan tests => scalar @_ * 5;
    foreach my $test (@_) {
	one_msg($sock, $test, $seqno++);
    }
}

1;
