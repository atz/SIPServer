# 
# parse-config: Parse an XML-format
# ACS configuration file and build the configuration
# structure.
#

package Sip::Configuration;

use strict;
use English;
use warnings;
use XML::Simple qw(:strict);

use Sip::Configuration::Institution;
use Sip::Configuration::Account;
use Sip::Configuration::Service;

my $parser = new XML::Simple( KeyAttr   => { login => '+id',
					     institution => '+id', 
					     service => '+port' },
			      GroupTags =>  { listeners => 'service',
					      accounts => 'login',
					      institutions => 'institution', },
			      ForceArray=> [ 'service',
					     'login',
					     'institution' ],
			      ValueAttr =>  { 'error-detect' => 'enabled',
					     'min_servers' => 'value',
					     'max_servers' => 'value'} );

sub new {
    my ($class, $config_file) = @_;
    my $cfg = $parser->XMLin($config_file);
    
    foreach my $acct (values %{$cfg->{accounts}}) {
	new Sip::Configuration::Account $acct;
    }

    foreach my $service (values %{$cfg->{listeners}}) {
	new Sip::Configuration::Service $service;
    }

    foreach my $inst (values %{$cfg->{institutions}}) {
	new Sip::Configuration::Institution $inst;
    }

    return bless $cfg, $class;
}

sub error_detect {
    my $self = shift;

    return $self->{'error-detect'};
}

sub accounts {
    my $self = shift;

    return values %{$self->{accounts}};
}

sub find_service {
    my ($self, $sockaddr, $port, $proto) = @_;
    my $portstr;

    foreach my $addr ('', '*:', "$sockaddr:") {
	$portstr = sprintf("%s%s/%s", $addr, $port, $proto);
	Sys::Syslog::syslog("LOG_DEBUG", "Configuration::find_service: Trying $portstr");
	last if (exists(($self->{listeners})->{$portstr}));
    }

    return $self->{listeners}->{$portstr};
}

#
# Testing
#


{
    no warnings qw(once);
    eval join('',<main::DATA>) || die $@ unless caller();
}

1;
__END__

    my $config = new Sip::Configuration $ARGV[0];


foreach my $acct ($config->accounts) {
    print "Found account '", $acct->name, "', part of '"
    print $acct->institution, "'\n";
}

1;
