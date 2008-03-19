#!/usr/bin/perl
#
# Copyright (C) 2006-2008  Georgia Public Library Service
# 
# Author: David J. Fiander
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public
# License as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#
# renew_all: test Renew All Response

use strict;
use warnings;
use Clone qw(clone);

use Sip::Constants qw(:all);

use SIPtest qw($datepat $textpat $instid $currency $user_barcode
	       $item_barcode $item_title $item_owner);

my $item_info_test_template = {
    id => 'Item Information: check information for available item',
    msg => "1720060110    215612AO$instid|AB$item_barcode|",
    pat => qr/^180[13]0201$datepat/, # status of 'other' or 'available'
    fields => [
	       $SIPtest::field_specs{(FID_SCREEN_MSG)},
	       $SIPtest::field_specs{(FID_PRINT_LINE)},
	       { field    => FID_ITEM_ID,
		 pat      => qr/^$item_barcode$/,
		 required => 1, },
	       { field    => FID_TITLE_ID,
		 pat      => qr/^$item_title\s*$/,
		 required => 1, },
	       { field    => FID_MEDIA_TYPE,
		 pat      => qr/^\d{3}$/,
		 required => 0, },
	       { field    => FID_OWNER,
		 pat      => qr/^$item_owner$/,
		 required => 0, },
	       ], };

my @tests = (
	     $SIPtest::login_test,
	     $SIPtest::sc_status_test,
	     clone($item_info_test_template),
	     );

SIPtest::run_sip_tests(@tests);

1;
