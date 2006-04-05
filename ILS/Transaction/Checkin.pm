#
# An object to handle checkin status
#

package ILS::Transaction::Checkin;

use Exporter;
use warnings;
use strict;

use POSIX qw(strftime);

use ILS;
use ILS::Transaction;

our @ISA = qw(Exporter ILS::Transaction);

sub new {
    my ($class, $obj) = @_;
    my $type = ref($class) || $class;
    my ($item, $patron);

    $obj = {};

    return bless $obj, $type;
}

sub resensitize {
    my $self = shift;

    return !$self->{item}->magnetic;
}

sub magnetic_media {
    my $self = shift;

    return $self->{item}->magnetic;
}

1;
