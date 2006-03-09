#
# ILS.pm: Test ILS interface module
#

package ILS;

use Exporter;
use warnings;
use strict;
use Sys::Syslog qw(syslog);

our (@ISA, @EXPORT_OK);

@ISA = qw(Exporter);

1;
