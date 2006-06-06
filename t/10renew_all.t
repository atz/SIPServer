#!/usr/bin/perl
# renew_all: test Renew All Response

use strict;
use warnings;
use Clone qw(clone);

use Sip::Constants qw(:all);

use SIPtest qw($datepat $textpat);

my $enable_template = {
    id => 'Renew All: prep: enable patron permissions',
    msg => '2520060102    084238AOUWOLS|AAdjfiander|',
    pat => qr/^26 {4}[ Y]{10}000$datepat/,
};

my $checkout_template = {
    id => 'Renew All: prep: check out item',
    msg => '11YN20060329    203000                  AOUWOLS|AAdjfiander|AB1565921879|AC|',
    pat => qr/^121NNY$datepat/,
};

my $checkin_template = {
    id => 'Renew All: prep: check in item',
    msg => '09N20060102    08423620060113    084235APUnder the bed|AOUWOLS|AB1565921879|ACterminal password|',
    pat => qr/^10YYNN$datepat/,
};

my $renew_all_test_template = {
    id => 'Renew All: valid patron with one item checked out, no patron password',
    msg => '6520060102    084236AOUWOLS|AAdjfiander|',
    pat => qr/^66100010000$datepat/,
    fields => [
	       $SIPtest::field_specs{(FID_INST_ID)},
	       $SIPtest::field_specs{(FID_SCREEN_MSG)},
	       $SIPtest::field_specs{(FID_PRINT_LINE)},
	       { field    => FID_RENEWED_ITEMS,
		 pat      => qr/^1565921879$/,
		 required => 1, },
	       ],};

my @tests = (
	     $SIPtest::login_test,
	     $SIPtest::sc_status_test,
	     $enable_template,
	     $checkout_template,
	     $renew_all_test_template,
	     );

SIPtest::run_sip_tests(@tests);

1;
