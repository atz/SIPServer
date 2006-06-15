#!/usr/bin/perl
# renew: test Renew Response

use strict;
use warnings;
use Clone qw(clone);

use Sip::Constants qw(:all);

use SIPtest qw($datepat $textpat);

my $checkout_template = {
    id => 'Renew: prep: check out item',
    msg => '11YN20060329    203000                  AOUWOLS|AAdjfiander|AB1565921879|AC|',
    pat => qr/^121NNY$datepat/,
    fields => [],
};

my $checkin_template = {
    id => 'Renew: prep: check in item',
    msg => '09N20060102    08423620060113    084235APUnder the bed|AOUWOLS|AB1565921879|ACterminal password|',
    pat => qr/^10YYNN$datepat/,
    fields => [],
};

my $renew_test_template = {
    id => 'Renew: item id checked out to patron, renewal permitted, no 3rd party, no fees',
    msg => '29NN20060102    084236                  AOUWOLS|AAdjfiander|AB1565921879|',
    pat => qr/^301YNN$datepat/,
    fields => [
	       $SIPtest::field_specs{(FID_INST_ID)},
	       $SIPtest::field_specs{(FID_SCREEN_MSG)},
	       $SIPtest::field_specs{(FID_PRINT_LINE)},
	       { field    => FID_PATRON_ID,
		 pat      => qr/^djfiander$/,
		 required => 1, },
	       { field    => FID_ITEM_ID,
		 pat      => qr/^1565921879$/,
		 required => 1, },
	       { field    => FID_TITLE_ID,
		 pat      => qr/^Perl 5 desktop reference$/,
		 required => 1, },
	       { field    => FID_DUE_DATE,
		 pat      => qr/^$datepat$/,
		 required => 1, },
	       { field    => FID_SECURITY_INHIBIT,
		 pat      => qr/^[YN]$/,
		 required => 0, },
	       ],};

my @tests = (
	     $SIPtest::login_test,
	     $SIPtest::sc_status_test,
	     $checkout_template,
	     $renew_test_template,
	     );

my $test;

# Renew: item checked out, identify by title
$test = clone($renew_test_template);
$test->{id} = 'Renew: identify item by title';
$test->{msg} =~ s/AB1565921879\|/AJPerl 5 desktop reference|/;
# Everything else should be the same
push @tests, $test;

# Renew: item not checked out.  Basically the same, except
# for the leader test.
$test = clone($renew_test_template);
$test->{id} = 'Renew: item not checked out at all';
$test->{pat} = qr/^300NUN$datepat/;
foreach my $field (@{$test->{fields}}) {
    if ($field->{field} eq FID_TITLE_ID || $field->{field} eq FID_DUE_DATE) {
	$field->{pat} = qr/^$/;
    }
}

push @tests, $checkin_template, $test;

# Still need tests for
#     - renewing invalid item
#     - invalid patron id
#     - renewing a for-fee item
#     - patrons that are not permitted to renew
#     - renewing item with outstanding hold
#     - renewing item that has reached limit on number of renewals

SIPtest::run_sip_tests(@tests);

1;
