#!/usr/bin/perl
# 
# patron_status: check status of valid patron and invalid patron

use strict;
use warnings;

use SIPtest qw($datepat);

my @tests = (
	     $SIPtest::login_test,
	     $SIPtest::sc_status_test,
	     { id => 'valid Patron Status',
	       msg => '2300120060101    084237AOUWOLS|AAdjfiander|AD6789|AC|',
	       pat => qr/^24 [ Y]{13}\d{3}$datepat/,
	       fields => [
			  { field    => 'AE',
			    pat      => qr/^David J\. Fiander$/,
			    required => 1, },
			  { field    => 'AA',
			    pat      => qr/^djfiander$/,
			    required => 1, },
			  { field    => 'BL',
			    pat      => qr/^Y$/,
			    required => 0, },
			  { field    => 'CQ',
			    pat      => qr/^Y$/,
			    required => 0, },
			  { field    => 'AO',
			    pat      => qr/^UWOLS$/,
			    required => 1, },
			  { field    => 'BH',
			    pat      => qr/^.{3}$/,
			    required => 0, },
			  { field    => 'BV',
			    pat      => qr/^[0-9.]+$/,
			    required => 0, },
			  $SIPtest::screen_msg,
			  $SIPtest::print_line,
			  ], },
	     { id => 'invalid password Patron Status',
	       msg => '2300120060101    084237AOUWOLS|AAdjfiander|AC|',
	       pat => qr/^24Y[ Y]{13}\d{3}$datepat/,
	       fields => undef, },
	     { id => 'invalid Patron Status',
	       msg => '2300120060101    084237AOUWOLS|AAwshakespeare|AC|',
	       pat => qr/^24Y[ Y]{13}\d{3}$datepat/,
	       fields => undef, },
	     );

SIPtest::run_sip_tests(@tests);

1;
