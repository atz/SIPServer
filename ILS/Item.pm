#
# ILS::Item.pm
# 
# A Class for hiding the ILS's concept of the item from the OpenSIP
# system
#

package ILS::Item;

use strict;
use warnings;
use Exporter;

use Sys::Syslog qw(syslog);

our (@ISA, @EXPORT_OK);

@ISA = qw(Exporter);

our %item_db = (
		1565921879 => {
		    title => "Perl 5 desktop reference",
		    id => 1565921879,
		    sip_media_type => '001',
		    magnetic_media => 0,
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

sub title_id {
    my $self = shift;

    return $self->{title};
}

1;
