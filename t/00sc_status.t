#!/usr/bin/perl
# 
# sc_status: test basic connection, login, and response
# to the SC Status message, which has to be sent before
# anything else

use strict;
use warnings;

use SIPtest qw($datepat $login_test $sc_status_test);

my @tests = ( $login_test, $sc_status_test );

SIPtest::run_sip_tests(@tests);

1;
