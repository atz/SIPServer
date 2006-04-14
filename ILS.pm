#
# ILS.pm: Test ILS interface module
#

package ILS;

use Exporter;
use warnings;
use strict;
use Sys::Syslog qw(syslog);

use ILS::Item;
use ILS::Patron;
use ILS::Transaction;
use ILS::Transaction::Checkout;
use ILS::Transaction::Checkin;
use ILS::Transaction::FeePayment;

our (@ISA, @EXPORT_OK);

@ISA = qw(Exporter);

my %supports = (
		'magnetic media' => 1,
		'security inhibit' => 0,
		'offline operation' => 0
		);

sub new {
    my ($class, $institution) = @_;
    my $type = ref($class) || $class;
    my $self = {};

    syslog("DEBUG", "new ILS '%s'", $institution->{id});
    $self->{institution} = $institution;

    return bless $self, $type;
}

sub institution {
    my $self = shift;

    return $self->{institution}->{id};
}

sub supports {
    my ($self, $op) = @_;

    return exists($supports{$op}) ? $supports{$op} : 0;
}

sub check_inst_id {
    my ($self, $id, $whence) = @_;

    if ($id ne $self->{institution}) {
	syslog("WARNING", "%s: received institution '%s', expected '%s'",
	       $whence, $id, $self->{institution});
    }
}

sub checkout_ok {
    return 1;
}

sub checkin_ok {
    return 0;
}

sub status_update_ok {
    return 1;
}

sub offline_ok {
    return 0;
}

#
# Checkout(patron_id, item_id, sc_renew):
#    patron_id & item_id are the identifiers send by the terminal
#    sc_renew is the renewal policy configured on the terminal
# returns a status opject that can be queried for the various bits
# of information that the protocol (SIP or NCIP) needs to generate
# the response.
#
sub checkout {
    my ($self, $patron_id, $item_id, $sc_renew) = @_;
    my ($patron, $item, $circ);

   $circ = new ILS::Transaction::Checkout;

    # BEGIN TRANSACTION
    $circ->{patron} = $patron = new ILS::Patron $patron_id;
    $circ->{item} = $item = new ILS::Item $item_id;

    $circ->{ok} = ($circ->{patron} && $circ->{item}) ? 1 : 0;

    if ($circ->{ok}) {
	$item->{patron} = $patron_id;
	$item->{due_date} = time + (14*24*60*60); # two weeks
	push(@{$patron->{items}}, $item_id);
	$circ->{desensitize} = !$item->magnetic;

	syslog("LOG_DEBUG", "ILS::Checkout: patron %s has checked out %s",
	       $patron_id, join(', ', @{$patron->{items}}));
    }

    return $circ;
}

sub checkin {
    my ($self, $item_id, $trans_date, $return_date,
	$current_loc, $item_props, $cancel) = @_;
    my ($patron, $item, $circ);

    $circ = new ILS::Transaction::Checkin;
    # BEGIN TRANSACTION
    $circ->{item} = $item = new ILS::Item $item_id;

    # It's ok to check it in if it exists, and if it was checked out
    $circ->{ok} = ($item && $item->{patron}) ? 1 : 0;

    if ($circ->{ok}) {
	$circ->{patron} = $patron = new ILS::Patron $item->{patron};
	delete $item->{patron};
	delete $item->{due_date};
	$patron->{items} = [ grep {$_ ne $item_id} @{$patron->{items}} ];
    }
    # END TRANSACTION

    return $circ;
}

sub block_patron {
    my ($self, $patron_id, $card_retained, $blocked_card_msg) = @_;
    my $patron;

    $patron = new ILS::Patron $patron_id;

    if (!$patron) {
	syslog("WARNING", "ILS::block_patron: attempting to block non-existant patron '%s'", $patron_id);
	return undef;
    }

    foreach my $field ('charge_ok', 'renew_ok', 'recall_ok', 'hold_ok') {
	$patron->{$field} = 'N';
    }

    $patron->{screen_msg} = $blocked_card_msg || "Card Blocked.  Please contact library staff";

    return $patron;
}

# If the ILS caches patron information, this lets it free
# it up
sub end_patron_session {
    my ($self, $patron_id) = @_;

    # success?, screen_msg, print_line
    return (1, 'Thank you for using Evergreen!', '');
}

sub pay_fee {
    my ($patron_id, $patron_pwd, $fee_amt, $fee_type,
	$pay_type, $fee_id, $trans_id, $currency) = @_;
    my $trans;
    my $patron;

    $trans = new ILS::Transaction::FeePayment;

    $patron = new ILS::Patron $patron_id;

    $trans->{transaction_id} = $trans_id;
    $trans->{patron} = $patron;
    $trans->{ok} = 1;

    return $trans;
}

1;
