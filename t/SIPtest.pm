package SIPtest;

use Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(run_sip_tests no_tagged_fields
		    $datepat $text_field
		    $login_test $sc_status_test
		    $print_line $screen_msg);
use strict;
use warnings;

# The number of tests is set in run_sip_tests() below, based
# on the size of the array of tests.
use Test::More;

use IO::Socket::INET;
use Sip qw(:all);
use Sip::Checksum qw(verify_cksum);

# Pattern for a SIP datestamp, to be used by individual tests to
# match timestamp fields (duh).
our $datepat = '\d{8} {4}\d{6}';

# Pattern for a random text field
our $text_field = qr/^[^|]+$/;

# field definitions for screen msg and print line
our $screen_msg = { field    => 'AF',
		    pat      => $text_field,
		    required => 0, };

our $print_line = { field    => 'AG',
		    pat      => $text_field,
		    required => 0, };

# Login and SC Status are always the first two messages that
# the terminal sends to the server, so just create the test
# cases here and reference them in the individual test files.

our $login_test = { id => 'login',
		    msg => '9300CNscclient|COclientpwd|CPThe basement|',
		    pat => qr/^941/,
		    fields => [], };

our $sc_status_test = { id => 'SC status',
			msg => '9910302.00',
			pat => qr/^98[YN]{6}\d{3}\d{3}$datepat(2\.00|1\.00)/,
			fields => [
				   { field    => 'AO',
				     pat      => $text_field,
				     required => 1, },
				   { field    => 'AM',
				     pat      => $text_field,
				     required => 0, },
				   { field    => 'BX',
				     pat      => qr/^[YN]+$/,
				     required => 1, },
				   { field    => 'AN',
				     pat      => $text_field,
				     required => 0, },
				   $print_line,
				   $screen_msg,
				   ],
			};

sub one_msg {
    my ($sock, $test, $seqno) = @_;
    my $resp;
    my %fields;

    ok(write_msg({seqno => $seqno}, $test->{msg}, $sock), "send $test->{id}");
    ok($resp = <$sock>, "read $test->{id}");
    chomp($resp);
    ok(verify_cksum($resp), "checksum $test->{id}");
    like($resp, $test->{pat}, "match leader $test->{id}");

    # I'm assuming that even if the leader test fails, that the
    # leader is the correct length, so I can strip that off.
    $resp =~ $test->{pat};
    $resp = substr($resp, $+[0]);

    # split the $resp into (field name, field value, '') triples
    # then use grep to throw out the empty pattern matches, then
    # assign the name/value pairs into the hash.
    %fields = $resp =~ /(..)([^|]+)\|/go;

    if (!defined($test->{fields})) {
      TODO: {
	  local $TODO = "$test->{id} field tests not written yet";
	  
	  ok(0, "$test->{id} field tests not written");
      }
    } else {
	# If there are no tagged fields, then 'fields' should be an
	# empty list which will automatically skip this loop
	foreach my $ftest (@{$test->{fields}}) {
	    if ($ftest->{required}) {
		ok(exists($fields{$ftest->{field}}),
		   "$test->{id} required field '$ftest->{field}' exists");
	    }

	    if (exists($fields{$ftest->{field}})) {
		like($fields{$ftest->{field}}, $ftest->{pat},
		     "$test->{id} field test $ftest->{field}");
	    } else {
		# Don't skip the test, because there's nothing to test
		# but we need to get the number of tests right.
		ok(1, "$test->{id} field test $ftest->{field} undefined");
	    }
	}
    }
}

#
# _count_tests: Count the number of tests in a test array
#
# There's four tests for each message (send, recv, cksum, leader) plus
# one test for each labelled field, or one TODO test to indicate that
# the field tests haven't been written.  This function has to be
# kept in sync with the actual tests in run_sip_tests()
#
sub _count_tests {
    my $count = 4 * scalar @_;

    foreach my $test (@_) {
	if (defined($test->{fields})) {
	    # one test for each field, plus one extra test
	    # for each required field
	    foreach my $field (@{$test->{fields}}) {
		$count += 1 + $field->{required};
	    }
	} else {
	    $count += 1;
	}
    }
    return $count;
}

sub run_sip_tests {
    my ($sock, $seqno);

    $Sip::error_detection = 1;
    $/ = "\r";

    $sock = new IO::Socket::INET(PeerAddr => 'localhost:5300',
				 Type     => SOCK_STREAM);
    BAIL_OUT('failed to create connection to server') unless $sock;

    $seqno = 1;

    plan tests => _count_tests(@_);

    foreach my $test (@_) {
	one_msg($sock, $test, $seqno++);
    }
}

1;
