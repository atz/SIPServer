#
# Copyright (C) 2006-2008  Georgia Public Library Service
# 
# Author: David J. Fiander
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public
# License as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA

package Sip::Checksum;

use Exporter;
use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(checksum verify_cksum);

sub checksum {
    my $pkt = shift;
    return (-unpack('%16C*', $pkt) & 0xFFFF);
}

sub verify_cksum {
    my $pkt = shift;
    my $cksum;
    my $shortsum;

    return 0 if (substr($pkt, -6, 2) ne "AZ"); # No checksum at end

    # Convert the checksum back to hex and calculate the sum of the
    # pack without the checksum.
    $cksum = hex(substr($pkt, -4));
    $shortsum = unpack("%16C*", substr($pkt, 0, -4));

    # The checksum is valid if the hex sum, plus the checksum of the 
    # base packet short when truncated to 16 bits.
    return (($cksum + $shortsum) & 0xFFFF) == 0;
}

1;

__END__

#
# Some simple test data
#
sub test {
    my $testpkt = shift;
    my $cksum = checksum($testpkt);
    my $fullpkt = sprintf("%s%4X", $testpkt, $cksum);

    print $fullpkt, "\n";
}

while (<>) {
    chomp;
    test($_);
}
