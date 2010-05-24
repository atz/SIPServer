#!/usr/bin/perl
#
# Copyright: 2010 - Equinox Software, Inc.
#    Author: Joe Atzberger
#   License: GPLv2 or later

use strict;
use warnings;
use Test::More tests => 5;

use vars qw/ $debug /;

BEGIN {
    use_ok('Sip::Checksum', qw/checksum verify_cksum/);
    $debug = @ARGV ? shift  : 0;
    $Sip::Checksum::debug = $debug;
}

note("checksum: " . checksum("9300CNLoginUserID|COLoginPassword|CPLocationCode|AY5AZEC78"));

my %pairs = (
    FCB4 => '990 402.00AY1AZ',  # see page 26 of the 3M SIP2 Developers Guide
    EC78 => '9300CNLoginUserID|COLoginPassword|CPLocationCode|AY5AZ',
    F400 => '2300119960212 100239AOid_21|104000000105|AC|AD|AY2AZ',
    CBC8 => '18030001200808050000053612CF 0|AB2030527770|AJWalter in the woods and the letter W / by Cynthia Klingel and Robert B. Noyed.|BG|BV|CK000|AQreerd|CH|AF|CSE KLINGEL | CT|AY9AZ',
    CD15 => '101YNN2008050000053612AOkcls |AB2030527770|AQreerd|AJWalter in the woods and the letter W / by Cynthia Klingel and Robert B. Noyed.|AF|CSE KLINGEL|CRreerd|AY89AZ',
    DC06 => '101YNN200808050000053558AOkcls |AB2029693658|AQrecfc|AJClementine and Mungo / by Saray Dyer.|AF|CSE DYER|CRrecfc|AY1AZ'
);

foreach (sort keys %pairs) {
    my $string = $pairs{$_};
    my $checksum = checksum($string);
    is($checksum, $_, "checksum($string)");
    ok(verify_cksum("$string$_"), "verify_cksum($string$_)");
}
# is();
1;
