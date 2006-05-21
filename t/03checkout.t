#!/usr/bin/perl
# checkout: test Checkout Response

use strict;
use warnings;
use Clone qw(clone);

use Sip::Constants qw(:all);

use SIPtest qw($datepat $textpat);

my $checkout_test_template = {
    id => 'Checkout: valid item, valid patron',
    msg => '11YN20060329    203000                  AOUWOLS|AAdjfiander|AB1565921879|AC|',
    pat => qr/^121NNY$datepat/,
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
		 pat      => $textpat,
		 required => 1, },
	       { field    => FID_FEE_TYPE,
		 pat      => qr/^\d{2}$/,
		 required => 0, },
	       { field    => FID_SECURITY_INHIBIT,
		 pat      => qr/^[YN]$/,
		 required => 0, },
	       { field    => FID_CURRENCY,
		 pat      => qr/^[[:upper;]]{3}$/,
		 required => 0, },
	       { field    => FID_FEE_AMT,
		 pat      => qr/^[.0-9]+$/,
		 required => 0, },
	       { field    => FID_MEDIA_TYPE,
		 pat      => qr/^\d{3}$/,
		 required => 0, },
	       { field    => FID_ITEM_PROPS,
		 pat      => $textpat,
		 required => 0, },
	       { field    => FID_TRANSACTION_ID,
		 pat      => $textpat,
		 required => 0, },
	       ], };

my @tests = (
	     $SIPtest::login_test,
	     $SIPtest::sc_status_test,
	     clone($checkout_test_template),
	     );

my $test;

# Renewal OK
# Test this by checking out exactly the same book a second time.
# The only difference should be that the "Renewal OK" flag should now
# be 'Y'.
$test = clone($checkout_test_template);
$test->{id} = 'Checkout: patron renewal';
$test->{pat} = qr/^121YNY$datepat/;

push @tests, $test;

# Valid Patron, Invalid Item_id
$test = clone($checkout_test_template);

$test->{id} = 'Checkout: valid patron, invalid item';
$test->{msg} =~ s/AB1565921879/ABno-barcode/;
$test->{pat} = qr/^120NUN$datepat/;
delete $test->{fields};
$test->{fields} = [
		   $SIPtest::field_specs{(FID_INST_ID)},
		   $SIPtest::field_specs{(FID_SCREEN_MSG)},
		   $SIPtest::field_specs{(FID_PRINT_LINE)},
		   { field    => FID_PATRON_ID,
		     pat      => qr/^djfiander$/,
		     required => 1, },
		   { field    => FID_ITEM_ID,
		     pat      => qr/^no-barcode$/,
		     required => 1, },
		   { field    => FID_TITLE_ID,
		     pat      => qr/^$/,
		     required => 1, },
		   { field    => FID_DUE_DATE,
		     pat      => qr/^$/,
		     required => 1, },
		   { field    => FID_VALID_PATRON,
		     pat      => qr/^Y$/,
		     required => 1, },
		   ];

push @tests, $test;

# Invalid patron, valid item
$test = clone($checkout_test_template);
$test->{id} = 'Checkout: invalid patron, valid item';
$test->{msg} =~ s/AAdjfiander/AAberick/;
$test->{pat} = qr/^120NUN$datepat/;
delete $test->{fields};
$test->{fields} = [
		   $SIPtest::field_specs{(FID_INST_ID)},
		   $SIPtest::field_specs{(FID_SCREEN_MSG)},
		   $SIPtest::field_specs{(FID_PRINT_LINE)},
		   { field    => FID_PATRON_ID,
		     pat      => qr/^berick$/,
		     required => 1, },
		   { field    => FID_ITEM_ID,
		     pat      => qr/^1565921879$/,
		     required => 1, },
		   { field    => FID_TITLE_ID,
		     pat      => qr/^Perl 5 desktop reference$/,
		     required => 1, },
		   { field    => FID_DUE_DATE,
		     pat      => qr/^$/,
		     required => 1, },
		   { field    => FID_VALID_PATRON,
		     pat      => qr/^N$/,
		     required => 1, },
		   ];

push @tests, $test;

# Needed: tests for blocked patrons, patrons with excessive
# fines/fees, magnetic media, charging fees to borrow items.

SIPtest::run_sip_tests(@tests);

1;
