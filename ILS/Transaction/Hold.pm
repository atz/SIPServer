#
# status of a Hold transaction

package ILS::Transaction::Hold;

use warnings;
use strict;

use ILS;
use ILS::Transaction;

our @ISA = qw(ILS::Transaction);

# Most fields are handled by the Transaction superclass

sub expiration_date {
    my $self = shift;

    return $self->{expiration_date} || 0;
}

sub queue_position {
    my $self = shift;

    return $self->item->hold_queue_position($self->patron->id);
}

sub pickup_location {
    my $self = shift;

    return $self->{pickup_location};
}
1;
