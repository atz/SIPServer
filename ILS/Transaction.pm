#
# Transaction: Superclass of all the transactional status objects
#

package ILS::Transaction;

use Exporter;
use strict;
use warnings;

our @ISA = qw(Exporter);

sub new {
    my ($class, $obj) = @_;
    my $type = ref($class) || $class;

    return bless {}, $type;
}

sub ok {
    my $self = shift;

    return $self->{ok} ? 1 : 0;	# normalize, just because
}

sub screen_msg {
    my $self = shift;

    return ($self->{screen_msg} || "");
}

sub print_line {
    my $self = shift;

    return ($self->{print_line} || "");
}

sub patron {
    my $self = shift;

    return $self->{patron};
}

sub item {
    my $self = shift;

    return $self->{item};
}

sub fee_amount {
    return 0;
}

sub sip_currency {
    return 'CAD';		# ;-)
}

sub sip_fee_type {
    my $self = shift;

    return $self->{sip_fee_type} || '01'; # "Other/Unknown"
}

sub desensitize {
    my $self = shift;

    return $self->{desensitize};
}

1;
