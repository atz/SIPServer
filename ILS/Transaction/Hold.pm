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
# status of a Hold transaction

package ILS::Transaction::Hold;

use warnings;
use strict;

use ILS;
use ILS::Transaction;

our @ISA = qw(ILS::Transaction);

my %fields = (
	      expiration_date => 0,
	      pickup_location => undef,
	      );

sub new {
    my $class = shift;;
    my $self = $class->SUPER::new();
    my $element;

    foreach $element (keys %fields) {
	$self->{_permitted}->{$element} = $fields{$element};
    }

    @{$self}{keys %fields} = values %fields;

    return bless $self, $class;
}

sub queue_position {
    my $self = shift;

    return $self->item->hold_queue_position($self->patron->id);
}

1;
