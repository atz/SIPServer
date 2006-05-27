#!/usr/bin/perl
# patron_enable: test  Patron Enable Response

use strict;
use warnings;
use Clone qw(clone);

use Sip::Constants qw(:all);

use SIPtest qw($datepat $textpat);

my $hold_test_template = {
    id => 'Place Hold: valid item, valid patron',
    msg => '15+20060415    110158BW20060815    110158|BSTaylor|BY2|AOUWOLS|AAdjfiander|AB1565921879|',
    pat => qr/^161N$datepat/,
    fields => [
	       $SIPtest::field_specs{(FID_INST_ID)},
	       $SIPtest::field_specs{(FID_SCREEN_MSG)},
	       $SIPtest::field_specs{(FID_PRINT_LINE)},
	       { field    => FID_PATRON_ID,
		 pat      => qr/^djfiander$/,
		 required => 1, },
	       { field    => FID_EXPIRATION,
		 pat      => $datepat,
		 required => 0, },
	       { field    => FID_QUEUE_POS,
		 pat      => qr/^[0-9]$/,
		 required => 1, },
	       { field    => FID_PICKUP_LOCN,
		 pat      => qr/^Taylor$/,
		 required => 1, },
	       { field    => FID_TITLE_ID,
		 pat      => $textpat,
		 required => 1, },
	       { field    => FID_ITEM_ID,
		 pat      => qr/^1565921879$/,
		 required => 1, },
    ],};
    
my @tests = (
	     $SIPtest::login_test,
	     $SIPtest::sc_status_test,
	     $hold_test_template,
	     );

SIPtest::run_sip_tests(@tests);

1;
