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

our (@ISA, @EXPORT_OK);

@ISA = qw(Exporter);

our %item_db;

sub new {
    my ($class, $item_id) = @_;
    my $type = ref($class) || $class;
    my $self;

    if (!exists($item_db{$item_id})) {
	return undef;
    }

    $self = $item_db{$item_id};
    bless $self, $type;
    return $self;
}


1;
