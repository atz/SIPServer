#!/usr/bin/perl
# checkin: test Checkin Response

use strict;
use warnings;
use Clone qw(clone);

use Sip::Constants qw(:all);

use SIPtest qw($datepat $textpat);

my $checkin_test_template = {
    id => 'Checkin: Item is checked out',
    msg => '09N20060102    08423620060113    084235APUnder the bed|AOUWOLS|AB1565921879|ACterminal password|',
    pat => qr/^10YYNN$datepat/,
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
	       { field    => FID_PERM_LOCN,
		 pat      => $textpat,
		 required => 1, },
	       { field    => FID_TITLE_ID,
		 pat      => qr/^Perl 5 desktop reference$/,
		 required => 1, }, # not required by the spec.
	       ],};

my $checkout_template = {
    id => 'Checkin: prep: check out item',
    msg => '11YN20060329    203000                  AOUWOLS|AAdjfiander|AB1565921879|AC|',
    pat => qr/^121NNY$datepat/,
    fields => [],
};

my @tests = (
	     $SIPtest::login_test,
	     $SIPtest::sc_status_test,
	     $checkin_test_template,
	     );

my $test;

# Checkin item that's not checked out.  Basically, this
# is identical to the first case, except the header says that
# the ILS didn't check the item in, and there's no patron id.
$test = clone($checkin_test_template);
$test->{id} = 'Checkin: Item not checked out';
$test->{pat} = qr/^10NYNN$datepat/;
$test->{fields} = [grep $_->{field} ne FID_PATRON_ID, @{$test->{fields}}];

push @tests, $test;

# 
# Still need tests for magnetic media
# 

SIPtest::run_sip_tests(@tests);

1;
