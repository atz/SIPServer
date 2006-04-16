#
# Status of a Renew Transaction
#

package ILS::Transaction::Renew;

use warnings;
use strict;

use ILS;
use ILS::Transaction;

our @ISA = qw(ILS::Transaction);

# most fields are handled by the Transaction superclass

sub renewal_ok {
    my $self = shift;

    return $self->{renewal_ok} || 0;
}

1;
