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
# Transaction: Superclass of all the transactional status objects
#

package ILS::Transaction;

use Carp;
use strict;
use warnings;

my %fields = (
	      ok            => 0,
	      patron        => undef,
	      item          => undef,
	      desensitize   => 0,
	      alert         => '',
	      transation_id => undef,
	      sip_fee_type  => '01', # Other/Unknown
	      fee_amount    => undef,
	      sip_currency  => 'CAD',
	      screen_msg    => '',
	      print_line    => '',
	      );

our $AUTOLOAD;

sub new {
    my $class = shift;
    my $self = {
	_permitted => \%fields,
	%fields,
    };

    return bless $self, $class;
}

sub DESTROY {
    # be cool
}

sub AUTOLOAD {
    my $self = shift;
    my $class = ref($self) or croak "$self is not an object";
    my $name = $AUTOLOAD;

    $name =~ s/.*://;

    unless (exists $self->{_permitted}->{$name}) {
	croak "Can't access '$name' field of class '$class'";
    }

    if (@_) {
	return $self->{$name} = shift;
    } else {
	return $self->{$name};
    }
}

1;
