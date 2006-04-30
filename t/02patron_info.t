#!/usr/bin/perl
# patron_info: test Patron Information Response

use strict;
use warnings;

use Sip::Constants qw(:all);

use SIPtest qw($datepat);

my @tests = (
	     $SIPtest::login_test,
	     $SIPtest::sc_status_test,
	     { id => 'valid Patron Info no details',
	       msg => '6300020060329    201700          AOUWOLS|AAdjfiander|',
	       pat => qr/^64 [ Y]{13}\d{3}$datepat(\d{4}){6}/,
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
			  { field    => FID_HOLD_ITEMS_LMT,
			    pat      => qr/^\d{4}$/,
			    required => 0, },
			  { field    => FID_OVERDUE_ITEMS_LMT,
			    pat      => qr/^\d{4}$/,
			    required => 0, },
			  { field    => FID_CHARDED_ITEMS_LMT,
			    pat      => qr/^\d{4}$/,
			    required => 0, },
			  { field    => FID_VALID_PATRON,
			    pat      => qr/^Y$/,
			    # Not required by the spec, but by the test
			    required => 1, },
			  { field    => FID_CURRENCY,
			    pat      => qr/^CAD$/,
			    required => 0, },
			  ], },
	     );

SIPtest::run_sip_tests(@tests);

1;
