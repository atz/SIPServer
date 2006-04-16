#
# An object to handle checkout status
#

package ILS::Transaction::Checkout;

use warnings;
use strict;

use POSIX qw(strftime);

use ILS;
use ILS::Transaction;

our @ISA = qw(ILS::Transaction);

# Most fields are handled by the Transaction superclass
my %fields = (
	      security_inhibit => 0,
	      due              => undef,
	      );

sub new {
    my $class = shift;;
    my $self = $class->SUPER::new();
    my $element;

    foreach $element (keys %fields) {
	$self->{_permitted}->{$element} = $fields{$element};
    }

    @{$self}{keys %fields} = values %fields;
    $self->{'due'} = time() + (60*60*24*14); # two weeks hence
    
    return bless $self, $class;
}

sub renew_ok {
    my $self = shift;
    my $patron = $self->{patron};
    my $item = $self->{item};

    return ($item->{patron} eq $patron->{id});
}

1;
