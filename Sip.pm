#
# Sip.pm: General Sip utility functions
#

package Sip;

use strict;
use warnings;
use English;
use Exporter;
use POSIX qw(strftime);
use Sip::Constants qw(SIP_DATETIME);
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(y_or_n timestamp);

sub y_or_n {
    my $bool = shift;

    $bool = uc $bool;
    if (!$bool || ($bool eq 'NO') || ($bool eq 'FALSE')) {
	return 'N';
    } else {
	return 'Y';
    }
}

sub timestamp {
    return strftime(SIP_DATETIME, localtime());
}
1;
