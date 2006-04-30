package SIPtest;

use Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(run_sip_tests no_tagged_fields
		    $datepat $textpat
		    $login_test $sc_status_test
		    %field_specs);
use strict;
use warnings;

#use Data::Dumper;

# The number of tests is set in run_sip_tests() below, based
# on the size of the array of tests.
use Test::More;

use IO::Socket::INET;
use Sip qw(:all);
use Sip::Checksum qw(verify_cksum);
use Sip::Constants qw(:all);

# Pattern for a SIP datestamp, to be used by individual tests to
# match timestamp fields (duh).
our $datepat = '\d{8} {4}\d{6}';

# Pattern for a random text field
our $textpat = qr/^[^|]+$/;

our %field_specs = (
		    (FID_SCREEN_MSG) => { field    => FID_SCREEN_MSG,
					  pat      => $textpat,
					  required => 0, },
		    (FID_PRINT_LINE) => { field    => FID_PRINT_LINE,
					  pat      => $textpat,
					  required => 0, },
		    (FID_INST_ID)    => { field    => FID_INST_ID,
					  pat      => qr/^UWOLS$/,
					  required => 1, },
		    (FID_HOLD_ITEMS_LMT)=> { field    => FID_HOLD_ITEMS_LMT,
					     pat      => qr/^\d{4}$/,
					     required => 0, },
		    (FID_OVERDUE_ITEMS_LMT)=> { field    => FID_OVERDUE_ITEMS_LMT,
						pat      => qr/^\d{4}$/,
						required => 0, },
		    (FID_CHARDED_ITEMS_LMT)=> { field    => FID_CHARDED_ITEMS_LMT,
						pat      => qr/^\d{4}$/,
						required => 0, },
		    (FID_VALID_PATRON) => { field    => FID_VALID_PATRON,
					    pat      => qr/^[NY]$/,
					    required => 0, },
		    (FID_VALID_PATRON_PWD)=> { field    => FID_VALID_PATRON_PWD,
					       pat      => qr/^[NY]$/,
					       required => 0, },
		    (FID_CURRENCY)   => { field    => FID_CURRENCY,
					  pat      => qr/^CAD$/,
					  required => 0, },
		    );

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
				   $field_specs{(FID_SCREEN_MSG)},
				   $field_specs{(FID_PRINT_LINE)},
				   $field_specs{(FID_INST_ID)},
				   { field    => 'AM',
				     pat      => $textpat,
				     required => 0, },
				   { field    => 'BX',
				     pat      => qr/^[YN]+$/,
				     required => 1, },
				   { field    => 'AN',
				     pat      => $textpat,
				     required => 0, },
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

    # Split the tagged fields of the response into (name, value)
    # pairs and stuff them into the hash.
    $resp =~ $test->{pat};
    %fields = substr($resp, $+[0]) =~ /(..)([^|]*)\|/go;

#    print STDERR Dumper(\%fields);
    if (!defined($test->{fields})) {
      TODO: {
	  local $TODO = "$test->{id} field tests not written yet";
	  
	  ok(0, "$test->{id} field tests not written");
      }
    } else {
	# If there are no tagged fields, then 'fields' should be an
	# empty list which will automatically skip this loop
	foreach my $ftest (@{$test->{fields}}) {
	    my $field = $ftest->{field};

	    if ($ftest->{required}) {
		ok(exists($fields{$field}),
		   "$test->{id} required field '$field' exists in '$resp'");
	    }

	    if (exists($fields{$field})) {
		like($fields{$field}, $ftest->{pat},
		     "$test->{id} field test $field matches in '$resp'");
	    } else {
		# Don't skip the test, because there's nothing to test
		# but we need to get the number of tests right.
		ok(1, "$test->{id} field test $field not received in '$resp'");
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

    $sock = new IO::Socket::INET(PeerAddr => 'localhost:6001',
				 Type     => SOCK_STREAM);
    BAIL_OUT('failed to create connection to server') unless $sock;

    $seqno = 1;

    plan tests => _count_tests(@_);

    foreach my $test (@_) {
	one_msg($sock, $test, $seqno++);
    }
}

1;
