#!/usr/bin/perl
# 
# patron_status: check status of valid patron and invalid patron

use strict;
use warnings;

use SIPtest;

my @tests = (
	     { id => 'login',
	       msg => '9300CNscclient|COclientpwd|CPThe basement|',
	       pat => qr/^941/,
	       fields => \&SIPtest::no_tagged_fields, },

	     { id => 'SC status',
	       msg => '9910302.00',
	       pat => qr/^98[YN]{6}\d{3}\d{3}.{18}[\d]\.\d\d/,
	       fields => undef, },
	     { id => 'valid Patron Status',
	       msg => '2300120060101    084237AOUWOLS|AAdjfiander|AD6789|AC|',
	       pat => qr/^24 [ Y]{13}\d{3}.{18}/,
	       fields => undef, },
	     { id => 'invalid password Patron Status',
	       msg => '2300120060101    084237AOUWOLS|AAdjfiander|AC|',
	       pat => qr/^24Y[ Y]{13}\d{3}.{18}/,
	       fields => undef, },
	     { id => 'invalid Patron Status',
	       msg => '2300120060101    084237AOUWOLS|AAwshakespeare|AC|',
	       pat => qr/^24Y[ Y]{13}\d{3}.{18}/,
	       fields => undef, },
	     );

SIPtest::run_sip_tests(@tests);

1;
