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
# This file reads a SIPServer xml-format configuration file and dumps it
# to stdout.  Just to see what the structures look like.
#
# The 'new XML::Simple' option must agree exactly with the configuration
# in Sip::Configuration.pm
#
use strict;
use English;

use XML::Simple qw(:strict);
use Data::Dumper;

my $parser = new XML::Simple( KeyAttr   => { login => '+id',
					     institution => '+id',
					     service => '+port', },
			      GroupTags =>  { listeners => 'service',
					      accounts => 'login',
					      institutions => 'institution', },
			      ForceArray=> [ 'service',
					     'login',
					     'institution' ],
			      ValueAttr =>  { 'error-detect' => 'enabled',
					     'min_servers' => 'value',
					     'max_servers' => 'value'} );

my $ref = $parser->XMLin($ARGV[0]);

print Dumper($ref); 
