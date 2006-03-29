#
# ILS::Patron.pm
# 
# A Class for hiding the ILS's concept of the patron from the OpenSIP
# system
#

package ILS::Patron;

use strict;
use warnings;
use Exporter;

use Sys::Syslog qw(syslog);
use Data::Dumper;

our (@ISA, @EXPORT_OK);

@ISA = qw(Exporter);

@EXPORT_OK = qw(invalid_patron);

our %patron_db = (
		  djfiander => {
		      name => "David J. Fiander",
		      id => 'djfiander',
		      password => '6789',
		      address => '2 Meadowvale Dr. St Thomas, ON',
		      home_phone => '(519) 555 1234',
		      email_addr => 'djfiander@hotmail.com',
		      charge_ok => 'Y',
		      renew_ok => 'Y',
		      recall_ok => 'N',
		      hold_ok => 'Y',
		      card_lost => 'N',
		      items_charged => 5,
		      claims_returned => 0,
		      fines => 100,
		      fees => 0,
		      recall_overdue => 0,
		      items_billed => 0,
		      screen_msg => '',
		      print_line => '',
		      items => [],
		      hold_items => [],
		      overdue_items => [],
		      fine_items => [],
		      recall_items => [],
		      unavail_holds => [],
		      fee_items => ['Computer Time'],
		  },
		  );

sub new {
    my ($class, $patron_id) = @_;
    my $type = ref($class) || $class;
    my $self;

    if (!exists($patron_db{$patron_id})) {
	return undef;
    }

    $self = $patron_db{$patron_id};
    bless $self, $type;
    return $self;
}

sub id {
    my $self = shift;

    return $self->{id};
}

sub name {
    my $self = shift;

    return $self->{name};
}

sub address {
    my $self = shift;

    return $self->{address};
}

sub email_addr {
    my $self = shift;

    return $self->{email_addr};
}

sub home_phone {
    my $self = shift;

    return $self->{home_phone};
}

sub charge_ok {
    my $self = shift;

    return $self->{charge_ok};
}

sub renew_ok {
    my $self = shift;

    return $self->{renew_ok};
}

sub recall_ok {
    my $self = shift;

    return $self->{recall_ok};
}

sub hold_ok {
    my $self = shift;

    return $self->{hold_ok};
}

sub card_lost {
    my $self = shift;

    return $self->{card_lost};
}

sub items_charged {
    my $self = shift;

    return scalar @{$self->{items}};
}

sub claims_returned {
    my $self = shift;

    return $self->{claims_returned};
}

sub fines {
    my $self = shift;

    return $self->{fines};
}

sub fees {
    my $self = shift;

    return $self->{fees};
}

sub recall_overdue {
    my $self = shift;

    return $self->{recall_overdue};
}

sub items_billed {
    my $self = shift;

    return $self->{items_billed};
}

sub check_password {
    my ($self, $pwd) = @_;

    return ($self->{password} eq $pwd);
}

sub currency {
    my $self = shift;

    return $self->{currency};
}

sub fee_amount {
    my $self = shift;

    return $self->{fee_amount} || undef;
}

sub screen_msg {
    my $self = shift;

    return $self->{screen_msg};
}

sub print_line {
    my $self = shift;

    return $self->{print_line};
}

sub too_many_charged {
    my $self = shift;

    return $self->{too_many_charged};
}

sub too_many_overdue {
    my $self = shift;

    return $self->{too_many_overdue};
}

sub too_many_renewal {
    my $self = shift;

    return $self->{too_many_renewal};
}

sub too_many_claim_return {
    my $self = shift;

    return $self->{too_many_claim_return};
}

sub too_many_lost {
    my $self = shift;

    return $self->{too_many_lost};
}

sub excessive_fines {
    my $self = shift;

    return $self->{excessive_fines};
}

sub excessive_fees {
    my $self = shift;

    return $self->{excessive_fees};
}

sub too_many_billed {
    my $self = shift;

    return $self->{too_many_billed};
}

#
# List of outstanding holds placed
#
sub hold_items {
    my ($self, $start, $end) = @_;

    $start = 1 if !defined($start);
    $end = $self->hold_items_count + 1 if !defined($end);

    return @{$self->{hold_items}}[$start-1 .. $end-1];
}

sub hold_items_count {
    my $self = shift;

    return scalar @{$self->{hold_items}};
}

sub overdue_items {
    my ($self, $start, $end) = @_;

    $start = 1 if !defined($start);
    $end = $self->overdue_items_count + 1 if !defined($end);

    return @{$self->{overdue_items}}[$start-1 .. $end-1];
}

sub overdue_items_count {
    my $self = shift;

    return scalar @{$self->{overdue_items}};
}

sub charged_items {
    my ($self, $start, $end) = shift;

    $start = 1 if !defined($start);
    $end = $self->charged_items_count + 1 if !defined($end);

    return @{$self->{items}}[$start-1 .. $end-1];
}

sub charged_items_count {
    my $self = shift;

    return scalar @{$self->{items}};
}

sub fine_items {
    my ($self, $start, $end) = @_;

    $start = 1 if !defined($start);
    $end = $self->fine_items_count + 1 if !defined($end);

    return @{$self->{fine_items}}[$start-1 .. $end-1];
}

sub fine_items_count {
    my $self = shift;

    return scalar @{$self->{fine_items}};
}

sub recall_items {
    my ($self, $start, $end) = @_;

    $start = 1 if !defined($start);
    $end = $self->recall_items_count + 1 if !defined($end);

    return @{$self->{recall_items}}[$start-1 .. $end-1];
}

sub recall_items_count {
    my $self = shift;

    return scalar @{$self->{recall_items}};
}

sub unavail_holds {
    my ($self, $start, $end) = @_;

    $start = 1 if !defined($start);
    $end = $self->unavail_holds_count + 1 if !defined($end);

    return @{$self->{unavail_holds}}[$start-1 .. $end-1];
}

sub unavail_holds_count {
    my $self = shift;

    return scalar @{$self->{unavail_holds}};
}

sub fee_items {
    my ($self, $start, $end) = @_;

    $start = 1 if !defined($start);
    $end = $self->fee_items_count + 1 if !defined($end);

    return @{$self->{fee_items}}[$start-1 .. $end-1];
}

sub fee_items_count {
    my $self = shift;

    return scalar @{$self->{fee_items}};
}
#
# Messages
#

sub invalid_patron {
    return "Please contact library staff";
}

sub charge_denied {
    return "Please contact library staff";
}

1;
