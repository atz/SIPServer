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
    fields => [],
};

my @checkout_templates = (
			  { id => 'Renew All: prep: check out Perl',
			    msg => '11YN20060329    203000                  AOUWOLS|AAdjfiander|AB1565921879|AC|',
			    pat => qr/^121NNY$datepat/,
			    fields => [],},
			  { id => 'Renew All: prep: check out Blue',
			    msg => '11YN20060329    203000                  AOUWOLS|AAdjfiander|AB0440242746|AC|',
			    pat => qr/^121NNY$datepat/,
			    fields => [],}
			 );

my @checkin_templates = (
			{ id => 'Renew All: prep: check in Perl',
			  msg => '09N20060102    08423620060113    084235APUnder the bed|AOUWOLS|AB1565921879|ACterminal password|',
			  pat => qr/^10YYNN$datepat/,
			  fields => [],},
			{ id => 'Renew All: prep: check in Blue',
			  msg => '09N20060102    08423620060113    084235APUnder the bed|AOUWOLS|AB0440242746|ACterminal password|',
			  pat => qr/^10YYNN$datepat/,
			  fields => [],}
		       );

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
#	     $enable_template,
	     $checkout_templates[0],
	     $renew_all_test_template,
	     $checkin_templates[0],	# check the book in, when done testing
	     );

my $test;

#$test = clone($renew_all_test_template);
#$test->{id} = 'Renew All: Valid patron, two items checked out';
#$test->{pat} = qr/^66000020000$datepat/;
#foreach my $i (0 .. (scalar @{$test->{fields}})-1) {
#    my $field =  $test->{fields}[$i];
#
#    if ($field->{field} eq FID_RENEWED_ITEMS) {
#	$field->{pat} = qr/^1565921879\|0440242746$/;
#    }
#}
#
#push @tests, $checkout_templates[0], $checkout_templates[1],
#  $renew_all_test_template, $checkin_templates[0], $checkin_templates[1];

$test = clone($renew_all_test_template);
$test->{id} = 'Renew All: valid patron, invalid patron password';
$test->{msg} .= (FID_PATRON_PWD) . 'badpwd|';
$test->{pat} = qr/^66000000000$datepat/;
delete $test->{fields};
$test->{fields} = [
	       $SIPtest::field_specs{(FID_INST_ID)},
	       $SIPtest::field_specs{(FID_SCREEN_MSG)},
	       $SIPtest::field_specs{(FID_PRINT_LINE)},
		  ];

push @tests, $checkout_templates[0], $test, $checkin_templates[0];

$test = clone($renew_all_test_template);
$test->{id} = 'Renew All: invalid patron';
$test->{msg} =~ s/AAdjfiander/AAberick/;
$test->{pat} = qr/^66000000000$datepat/;
delete $test->{fields};
$test->{fields} = [
	       $SIPtest::field_specs{(FID_INST_ID)},
	       $SIPtest::field_specs{(FID_SCREEN_MSG)},
	       $SIPtest::field_specs{(FID_PRINT_LINE)},
		  ];
push @tests, $test;

SIPtest::run_sip_tests(@tests);

1;
