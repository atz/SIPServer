#
# ILS::Item.pm
# 
# A Class for hiding the ILS's concept of the item from the OpenSIP
# system
#

package ILS::Item;

use strict;
use warnings;

use Sys::Syslog qw(syslog);

use ILS::Transaction;

our %item_db = (
		1565921879 => {
		    title => "Perl 5 desktop reference",
		    id => 1565921879,
		    sip_media_type => '001',
		    magnetic_media => 0,
		    hold_queue => [],
		}
		);

sub new {
    my ($class, $item_id) = @_;
    my $type = ref($class) || $class;
    my $self;


    if (!exists($item_db{$item_id})) {
	syslog("DEBUG", "new ILS::Item('%s'): not found", $item_id);
	return undef;
    }

    $self = $item_db{$item_id};
    bless $self, $type;

    syslog("DEBUG", "new ILS::Item('%s'): found with title '%s'",
	   $item_id, $self->{title});

    return $self;
}

sub magnetic {
    my $self = shift;

    return $self->{magnetic_media};
}

sub sip_media_type {
    my $self = shift;

    return $self->{sip_media_type};
}

sub sip_item_properties {
    my $self = shift;

    return $self->{sip_item_properties};
}

sub status_update {
    my ($self, $props) = @_;
    my $status = new ILS::Transaction;

    $self->{sip_item_properties} = $props;
    $status->{ok} = 1;

    return $status;
}

    
sub id {
    my $self = shift;

    return $self->{id};
}

sub title_id {
    my $self = shift;

    return $self->{title};
}

sub permanent_location {
    my $self = shift;

    return $self->{permanent_location} || '';
}

sub current_location {
    my $self = shift;

    return $self->{current_location} || '';
}

sub sip_circulation_status {
    my $self = shift;

    if ($self->{patron}) {
	return '04';
    } else {
	return '01';
    }
}

sub sip_security_marker {
    return '02';
}

sub sip_fee_type {
    return '01';
}

sub fee {
    my $self = shift;

    return $self->{fee} || 0;
}

sub fee_currency {
    my $self = shift;

    return $self->{currency} || 'CAD';
}

sub owner {
    my $self = shift;

    return 'UWOLS';
}

sub hold_queue_length {
    my $self = shift;

    return scalar @{$self->{hold_queue}};
}

sub due_date {
    my $self = shift;

    return $self->{due_date} || 0;
}

sub recall_date {
    my $self = shift;

    return $self->{recall_date} || 0;
}

sub hold_pickup_date {
    my $self = shift;

    return $self->{hold_pickup_date} || 0;
}

sub screen_msg {
    my $self = shift;

    return $self->{screen_msg} || '';
}

sub print_line {
    my $self = shift;

    return $self->{print_line} || '';
}


1;
