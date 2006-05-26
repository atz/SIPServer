#!/usr/bin/perl
# patron_enable: test  Patron Enable Response

use strict;
use warnings;
use Clone qw(clone);

use Sip::Constants qw(:all);

use SIPtest qw($datepat $textpat);

my $patron_enable_test_template = {
    id => 'Patron Enable: valid patron',
    msg => "2520060102    084238AOUWOLS|AAdjfiander|",
    pat => qr/^26 [ Y]{13}000$datepat/,
    fields => [
	       $SIPtest::field_specs{(FID_INST_ID)},
	       $SIPtest::field_specs{(FID_SCREEN_MSG)},
	       $SIPtest::field_specs{(FID_PRINT_LINE)},
	       { field    => FID_PATRON_ID,
		 pat      => qr/^djfiander$/,
		 required => 1, },
	       { field    => FID_PERSONAL_NAME,
		 pat      => qr/^David J\. Fiander$/,
		 required => 1, },
	       { field    => FID_VALID_PATRON,
		 pat      => qr/^Y$/,
		 # Not required by the spec, but by the test
		 required => 1, },
	       ], };

my @tests = (
	     $SIPtest::login_test,
	     $SIPtest::sc_status_test,
	     clone($patron_enable_test_template),
	     );

SIPtest::run_sip_tests(@tests);

1;
