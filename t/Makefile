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
# 
# 

TESTS = 00sc_status.t 01patron_status.t 02patron_info.t 03checkout.t \
	04patron_status.t 05block_patron.t 06patron_enable.t 07hold.t \
	08checkin.t 09renew.t 10renew_all.t 11item_info.t

OILS_TESTS = 00sc_status.t 01patron_status.t 02patron_info.t 03checkout.t \
	08checkin.t 09renew.t 11item_info.t 05block_patron.t

test-openils:
	prove -I.. $(OILS_TESTS)

test:
	prove -I.. $(TESTS)
