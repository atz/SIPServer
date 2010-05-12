#!/usr/bin/perl


use strict;
use warnings;

use IO::Socket::INET;
use Data::Dumper;
use Sip qw(:all);

my $server = @ARGV ? shift : 'localhost:8023';

print "Attempting connection to $server\n";
my $sock = IO::Socket::INET->new(
    RemoteAddr => $server,
    Type       => SOCK_STREAM,
    Timeout    => 30
);

$sock or die "IO::Socket::INET->new failed for $server $@";

my $timeout = 15;

$server =~ /^(.*):(.*)$/;
print "sock->connect($2, $1)\n";
$sock->connect($2, inet_aton($1));  # $sock->connect(NAME) or $sock->connect(PORT, ADDR)
sock_debug($sock);

my $user = 'sip_01';
my $pass = 'sip_01';
my $inst = 'CONS';

my @input = (
    "9300CN$user|CO$pass|CP$inst|",
    '9910302.00',
);

if ($server =~ /:8023$/) {
    read_it(1);
    do_the_write_thing($user);
    read_it(1);
    do_the_write_thing($pass);
}

print scalar(@input), " lines of input\n";

foreach(@input) {
    do_the_write_thing($_);
    read_it();
}

## SUBS
sub sock_debug {
    my $sock = shift;
    # print Dumper($sock);
    print "Socket:\n";
    print "sock->connected  : ", ($sock->connected  || ''), "\n";
    print "sock->protocol   : ", ($sock->protocol   || ''), "\n";
    print "sock->sockdomain : ", ($sock->sockdomain || ''), "\n";
    print "sock->socktype   : ", ($sock->socktype   || ''), "\n";
    print "sock->timeout    : ", ($sock->timeout    || ''), "\n";
    print "\n";
}

sub do_the_write_thing {
    my $msg = shift;
    print "TX: $msg\n";
    my $x = write_msg(
        {seqno => 1},
        $msg,
        $sock
    ) or die "write_msg failed $@";
    print "TX: [complete] $x\n";
}

sub read_it {
    local $/ = @_ ? " " : "\r";     # see comment below
    # local $/ = "\012";    # Internet Record Separator (lax version)
    local $SIG{ALRM} = sub { die "Timed Out! ($timeout) $@\n"; };
    print "Waiting for response\n";
    alarm $timeout;
    my $resp = <$sock>;
    alarm 0;
    defined($resp) or die "No response from server $server $@";
    print "RX: $resp\n";
}


__END__

The user/password telnet prompts do not include newlines of any kind, so we set the
record separator to space for those.  

Unfortunately,  we cannot just change the prompts 
because all existing production systems use a form of expect scripts to match
the prompt strings as they are. 
