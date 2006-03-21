#
# An object to handle checkout status
#

package ILS::Transaction::Checkout;

use Exporter;
use warnings;
use strict;

use POSIX qw(strftime);

use ILS;
use ILS::Transaction;

our @ISA = qw(Exporter ILS::Transaction);

# Most fields are handled by the Transaction superclass

sub new {
    my ($class, $obj) = @_;
    my $type = ref($class) || $class;

    $obj = {};

    $obj->{'due'} = time() + (60*60*24*14); # two weeks hence

    return bless $obj, $type;
}

sub security_inhibit {
    return 0;
}

sub due_date {
    my $self = shift;
    return(strftime("%F %H:%M:%S", localtime($self->{due})));
}

sub renew_ok {
    my $self = shift;
    my $patron = $self->{patron};
    my $item = $self->{item};

    return ($item->{patron} eq $patron->{id});
}
1;
