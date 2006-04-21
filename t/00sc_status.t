#!/usr/bin/perl
# 
# sc_status: test basic connection, login, and response
# to the SC Status message, which has to be sent before
# anything else

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
	     );

SIPtest::run_sip_tests(@tests);

1;
