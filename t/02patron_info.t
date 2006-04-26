# 
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
			  ], },
	     );

SIPtest::run_sip_tests(@tests);

1;
