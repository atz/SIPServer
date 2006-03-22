#
# Sip::MsgType.pm
#
# A Class for handing SIP messages
#

package Sip::MsgType;

use strict;
use warnings;
use Exporter;
use Sys::Syslog qw(syslog);

use Sip;
use Sip::Constants qw(:all);
use Sip::Checksum qw(checksum verify_cksum);

use ILS;
use ILS::Patron;
use ILS::Item;

use Data::Dumper;

our (@ISA, @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT_OK = qw(handle);

# Predeclare handler subroutines
use subs qw(handle_patron_status handle_checkout handle_checkin
	    handle_block_patron handle_sc_status handle_request_acs_resend
	    handle_login handle_patron_info handle_end_patron_session
	    handle_fee_paid handle_item_information handle_item_status_update
	    handle_patron_enable handle_hold handle_renew handle_renew_all);

#
# For the most part, Version 2.00 of the protocol just adds new
# variable fields, but sometimes it changes the fixed header.
#
# In general, if there's no '2.00' protocol entry for a handler, that's
# because 2.00 didn't extend the 1.00 version of the protocol.  This will
# be handled by the module initialization code following the declaration,
# which goes through the handlers table and creates a '2.00' entry that
# points to the same place as the '1.00' entry.  If there's a 2.00 entry
# but no 1.00 entry, then that means that it's a completely new service
# in 2.00, so 1.00 shouldn't recognize it.

my %handlers = (
		(PATRON_STATUS_REQ) => {
		    name => "Patron Status Request",
		    handler => \&handle_patron_status,
		    protocol => {
			"1.00" => {
			    template => "A3A18",
			    template_len => 21,
			    fields => [(FID_INST_ID), (FID_PATRON_ID),
				       (FID_TERMINAL_PWD), (FID_PATRON_PWD)],
			}
		    }
		},
		(CHECKOUT) => {
		    name => "Checkout",
		    handler => \&handle_checkout,
		    protocol => {
			"1.00" => {
			    template => "CCA18A18",
			    template_len => 38,
			    fields => [(FID_INST_ID), (FID_PATRON_ID),
				       (FID_ITEM_ID), (FID_TERMINAL_PWD)],
			},
			"2.00" => {
			    template => "CCA18A18",
			    template_len => 38,
			    fields => [(FID_INST_ID), (FID_PATRON_ID),
				       (FID_ITEM_ID), (FID_TERMINAL_PWD),
				       (FID_ITEM_PROPS), (FID_PATRON_PWD),
				       (FID_FEE_ACK), (FID_CANCEL)],
			},
		    }
		},
		(CHECKIN) => {
		    name => "Checkin",
		    handler => \&handle_checkin,
		    protocol => {
			"1.00" => {
			    template => "CA18A18",
			    template_len => 37,
			    fields => [(FID_CURRENT_LOCN), (FID_INST_ID),
				       (FID_ITEM_ID), (FID_TERMINAL_PWD)],
			},
			"2.00" => {
			    template => "CA18A18",
			    template_len => 37,
			    fields => [(FID_CURRENT_LOCN), (FID_INST_ID),
				       (FID_ITEM_ID), (FID_TERMINAL_PWD),
				       (FID_ITEM_PROPS), (FID_CANCEL)],
			}
		    }
		},
		(BLOCK_PATRON) => {
		    name => "Block Patron",
		    handler => \&handle_block_patron,
		    protocol => {
			"1.00" => {
			    template => "CA18",
			    template_len => 19,
			    fields => [(FID_INST_ID), (FID_BLOCKED_CARD_MSG),
				       (FID_PATRON_ID), (FID_TERMINAL_PWD)],
			},
		    }
		},
		(SC_STATUS) => {
		    name => "SC Status",
		    handler => \&handle_sc_status,
		    protocol => {
			"1.00" => {
			    template =>"CA3A4",
			    template_len => 8,
			    fields => [],
			}
		    }
		},
		(REQUEST_ACS_RESEND) => {
		    name => "Request ACS Resend",
		    handler => \&handle_request_acs_resend,
		    protocol => {
			"1.00" => {
			    template => "",
			    template_len => 0,
			    fields => [],
			}
		    }
		},
		(LOGIN) => {
		    name => "Login",
		    handler => \&handle_login,
		    protocol => {
			"2.00" => {
			    template => "A1A1",
			    template_len => 2,
			    fields => [(FID_LOGIN_UID), (FID_LOGIN_PWD),
				       (FID_LOCATION_CODE)],
			}
		    }
		},
		(PATRON_INFO) => {
		    name => "Patron Info",
		    handler => \&handle_patron_info,
		    protocol => {
			"2.00" => {
			    template => "A3A18A10",
			    template_len => 21,
			    fields => [(FID_INST_ID), (FID_PATRON_ID),
				       (FID_TERMINAL_PWD), (FID_PATRON_PWD),
				       (FID_START_ITEM), (FID_END_ITEM)],
			}
		    }
		},
		(END_PATRON_SESSION) => {
		    name => "End Patron Session",
		    handler => \&handle_end_patron_session,
		    protocol => {
			"2.00" => {
			    template => "A18",
			    template_len => 18,
			    fields => [(FID_INST_ID), (FID_PATRON_ID),
				       (FID_TERMINAL_PWD), (FID_PATRON_PWD)],
			}
		    }
		},
		(FEE_PAID) => {
		    name => "Fee Paid",
		    handler => \&handle_fee_paid,
		    protocol => {
			"2.00" => {
			    template => "A18A2A3",
			    template_len => 0,
			    fields => [(FID_FEE_AMT), (FID_INST_ID),
				       (FID_PATRON_ID), (FID_TERMINAL_PWD),
				       (FID_PATRON_PWD), (FID_FEE_ID),
				       (FID_TRANSACTION_ID)],
			}
		    }
		},
		(ITEM_INFORMATION) => {
		    name => "Item Information",
		    handler => \&handle_item_information,
		    protocol => {
			"2.00" => {
			    template => "A18",
			    template_len => 18,
			    fields => [(FID_INST_ID), (FID_ITEM_ID),
				       (FID_TERMINAL_PWD)],
			}
		    }
		},
		(ITEM_STATUS_UPDATE) => {
		    name => "Item Status Update",
		    handler => \&handle_item_status_update,
		    protocol => {
			"2.00" => {
			    template => "A18",
			    template_len => 18,
			    fields => [(FID_INST_ID), (FID_PATRON_ID),
				       (FID_ITEM_ID), (FID_TERMINAL_PWD),
				       (FID_ITEM_PROPS)],
			}
		    }
		},
		(PATRON_ENABLE) => {
		    name => "Patron Enable",
		    handler => \&handle_patron_enable,
		    protocol => {
			"2.00" => {
			    template => "A18",
			    template_len => 18,
			    fields => [(FID_INST_ID), (FID_PATRON_ID),
				       (FID_TERMINAL_PWD), (FID_PATRON_PWD)],
			}
		    }
		},
		(HOLD) => {
		    name => "Hold",
		    handler => \&handle_hold,
		    protocol => {
			"2.00" => {
			    template => "CA18",
			    template_len => 19,
			    fields => [(FID_EXPIRATION), (FID_PICKUP_LOCN),
				       (FID_HOLD_TYPE), (FID_INST_ID),
				       (FID_PATRON_ID), (FID_ITEM_ID),
				       (FID_TITLE_ID), (FID_TERMINAL_PWD),
				       (FID_FEE_ACK)],
			}
		    }
		},
		(RENEW) => {
		    name => "Renew",
		    handler => \&handle_renew,
		    protocol => {
			"2.00" => {
			    template => "CCA18A18",
			    template_len => 38,
			    fields => [(FID_INST_ID), (FID_PATRON_ID),
				       (FID_PATRON_PWD), (FID_ITEM_ID),
				       (FID_TITLE_ID), (FID_TERMINAL_PWD),
				       (FID_ITEM_PROPS), (FID_FEE_ACK)],
			}
		    }
		},
		(RENEW_ALL) => {
		    name => "Renew All",
		    handler => \&handle_renew_all,
		    protocol => {
			"2.00" => {
			    template => "A18",
			    template_len => 18,
			    fields => [(FID_INST_ID), (FID_PATRON_ID),
				       (FID_TERMINAL_PWD), (FID_FEE_ACK)],
			}
		    }
		}
		);

#
# Now, initialize some of the missing bits of %handlers
#
foreach my $i (keys(%handlers)) {
    if (!exists($handlers{$i}->{protocol}->{"2.00"})) {

	$handlers{$i}->{protocol}->{"2.00"} = $handlers{$i}->{protocol}->{"1.00"};
    }
}

my $error_detection = 0;
my $protocol_version = "1.00";
my $field_delimiter = '|'; 	# Protocol Default

sub new {
    my ($class, $msg, $seqno) = @_;
    my $self = {};
    my $msgtag = substr($msg, 0, 2);

    syslog("LOG_DEBUG", "Sip::MsgType::new('%s', '%s', '%s'): msgtag '%s'",
	   $class, substr($msg, 0, 10), $msgtag, $seqno);
    if ($msgtag eq LOGIN) {
	# If the client is using the 2.00-style "Login" message
	# to authenticate to the server, then we get the Login message
	# _before_ the client has indicated that it supports 2.00, but
	# it's using the 2.00 login process, so it must support 2.00,
	# so we'll just do it.
	$protocol_version = "2.00";
    }
    if (!exists($handlers{$msgtag})) {
	syslog("LOG_WARNING",
	       "new Sip::MsgType: Skipping message of unknown type '%s' in '%s'",
	       $msgtag, $msg);
	return(undef);
    } elsif (!exists($handlers{$msgtag}->{protocol}->{$protocol_version})) {
	syslog("LOG_WARNING", "new Sip::MsgType: Skipping message '%s' unsupported by protocol rev. '%s'",
	       $msgtag, $protocol_version);
	return(undef);
    }
    
    bless $self, $class;

    $self->{seqno} = $seqno;
    $self->_initialize(substr($msg,2), $handlers{$msgtag});

    return($self);
}

sub _initialize {
    my ($self, $msg, $control_block) = @_;
    my ($fs, $fn, $fe);
    my $proto = $control_block->{protocol}->{$protocol_version};
    
    $self->{name} = $control_block->{name};
    $self->{handler} = $control_block->{handler};
    
    $self->{fields} = {};
    $self->{fixed_fields} = [];

    syslog("LOG_DEBUG", "Sip::MsgType:_initialize('%s', '%s...')",
	   $self->{name}, substr($msg, 0, 20));

    foreach my $field (@{$proto->{fields}}) {
	$self->{fields}->{$field} = undef;
    }

    syslog("LOG_DEBUG",
	   "Sip::MsgType::_initialize('%s', '%s', '%s', '%s', ...",
	   $self->{name}, $msg, $proto->{template},
	   $proto->{template_len});

    $self->{fixed_fields} = [ unpack($proto->{template}, $msg) ];

    for ($fs = $proto->{template_len}; $fs < length($msg); $fs = $fe + 1) {
	$fn = substr($msg, $fs, 2);
	$fs += 2;
	syslog("LOG_DEBUG",
	       "_initialize: msg: '%s', field_delimiter: '%s', fs: '%s'",
	       $msg, $field_delimiter, $fs);
	$fe = index($msg, $field_delimiter, $fs);

	if ($fe == -1) {
	    syslog("LOG_WARNING", "Unterminated %s field in %s message '%s'",
		   $fn, $self->{name}, $msg);
	    $fe = length($msg);
	}

	if (!exists($self->{fields}->{$fn})) {
	    syslog("LOG_WARNING",
		   "Unsupported field '%s' at offset %d in %s message '%s'",
		   $fn, $fs, $self->{name}, $msg);
	} elsif (defined($self->{fields}->{$fn})) {
	    syslog("LOG_WARNING",
		   "Duplicate field '%s' at offset %d (previous value '%s') in %s message '%s'",
		   $fn, $fs, $self->{fields}->{$fn}, $self->{name}, $msg);
	} else {
	    $self->{fields}->{$fn} = substr($msg, $fs, $fe - $fs);
	}
    }
    
    return($self);
}

# We need to keep a copy of the last message we sent to the SC,
# in case there's a transmission error and the SC sends us a
# REQUEST_ACS_RESEND.  If we receive a REQUEST_ACS_RESEND before
# we've ever sent anything, then we are to respond with a 
# REQUEST_SC_RESEND (p.16)

my $last_response = '';

sub handle {
    my ($msg, $server, $req) = @_;
    my $config = $server->{config};
    my $self;


    #
    # What's the field delimiter for variable length fields?
    # This can't be based on the account, since we need to know
    # the field delimiter to parse a SIP login message
    #
    if (defined($server->{config}->{delimiter})) {
	$field_delimiter = $server->{config}->{delimiter};
    }

    # error detection is active if this is a REQUEST_ACS_RESEND
    # message with a checksum, or if the message is long enough
    # and the last nine characters begin with a sequence number
    # field
    if ($msg eq REQUEST_ACS_RESEND_CKSUM) {
	# Special case

	$error_detection = 1;
	$self = new Sip::MsgType ((REQUEST_ACS_RESEND), 0);
    } elsif((length($msg) > 11) && (substr($msg, -9, 2) eq "AY")) {
	$error_detection = 1;

	if (!verify_cksum($msg)) {
	    syslog("LOG_WARNING", "Checksum failed on message '%s'", $msg);
	    # REQUEST_SC_RESEND with error detection
	    $last_response = REQUEST_SC_RESEND_CKSUM;
	    print("$last_response\r");
	    return REQUEST_ACS_RESEND;
	} else {
	    # Save the sequence number, then strip off the
	    # error detection data to process the message
	    $self = new Sip::MsgType (substr($msg, 0, -9), substr($msg, -7, 1));
	}
    } elsif ($error_detection) {
	# We've receive a non-ED message when ED is supposed
	# to be active.  Warn about this problem, then process
	# the message anyway.
	syslog("LOG_WARNING",
	       "Received message without error detection: '%s'", $msg);
	$error_detection = 0;
	$self = new Sip::MsgType ($msg, 0);
    } else {
	$self = new Sip::MsgType ($msg, 0);
    }

    if ((substr($msg, 0, 2) ne REQUEST_ACS_RESEND) &&
	$req && (substr($msg, 0, 2) ne $req)) {
	return substr($msg, 0, 2);
    }
    return($self->{handler}->($self, $server));
}

##
## Message Handlers
##

#
# Patron status messages are produced in response to both
# "Request Patron Status" and "Block Patron"
#
sub build_patron_status {
    my ($patron, $lang, $fields)= @_;
    my $resp = (PATRON_STATUS_RESP);

    if ($patron) {
	# Valid patron
	$resp .= patron_status_string($patron);
	$resp .= $lang . Sip::timestamp();
	$resp .= FID_PERSONAL_NAME . $patron->name . $field_delimiter;

	# while the patron ID we got from the SC is valid, let's
	# use the one returned from the ILS, just in case...
	$resp .= FID_PATRON_ID . $patron->id . $field_delimiter;
	if ($protocol_version eq '2.00') {
	    $resp .= FID_VALID_PATRON . 'Y' . $field_delimiter;
	    # If the patron password field doesn't exist, we don't know if
	    # it's valid or not.  Or do we have to match an empty password?
	    if (exists($fields->{(FID_PATRON_PWD)})) {
		$resp .= FID_VALID_PATRON_PWD
		    . $patron->check_password($fields->{(FID_PATRON_PWD)})
		    . $field_delimiter;
	    }
	    $resp .= maybe_add(FID_CURRENCY, $patron->currency);
	    $resp .= maybe_add(FID_FEE_AMT, $patron->fee_amount);
	}
	$resp .= maybe_add(FID_SCREEN_MSG, $patron->screen_msg);
	$resp .= maybe_add(FID_PRINT_LINE, $patron->print_line);
    } else {
	# Invalid patron id: he has no privileges, has
	# no personal name, and is invalid (if we're using 2.00)
	$resp .= (' ' x 14) . $lang . Sip::timestamp();
	$resp .= FID_PERSONAL_NAME . $field_delimiter;

	# the patron ID is invalid, but it's a required field, so
	# just echo it back
	$resp .= FID_PATRON_ID . $fields->{(FID_PATRON_ID)} . $field_delimiter;

	if ($protocol_version eq '2.00') {
	    $resp .= FID_VALID_PATRON . 'N' . $field_delimiter;
	}
    }

    $resp .= FID_INST_ID . $fields->{(FID_INST_ID)} . $field_delimiter;

    return $resp;
}

sub handle_patron_status {
    my ($self, $server) = @_;
    my ($lang, $date);
    my $fields;
    my $patron;
    my $resp = (PATRON_STATUS_RESP);
    my $account = $server->{account};

    ($lang, $date) = @{$self->{fixed_fields}};
    $fields = $self->{fields};

    if ($fields->{(FID_INST_ID)} ne $account->{institution}) {
	syslog("LOG_WARN", "handle_patron_status: Inst-ID from SC, %s, doesn't match account Inst-ID, %s",
	       $fields->{(FID_INST_ID)}, $account->{institution});
    }

    $patron = new ILS::Patron $fields->{(FID_PATRON_ID)};

    $resp = build_patron_status($patron, $lang, $fields);

    $self->write_msg($resp, $server);

    return (PATRON_STATUS_REQ);
}

sub handle_checkout {
    my ($self, $server) = @_;
    my $account = $server->{account};
    my $ils = $server->{ils};
    my $inst = $ils->institution;
    my ($sc_renewal_policy, $no_block, $trans_date, $nb_due_date);
    my $fields;
    my ($patron_id, $item_id, $status);
    my ($item, $patron);
    my $resp;

    ($sc_renewal_policy, $no_block, $trans_date, $nb_due_date) =
	@{$self->{fixed_fields}};
    $fields = $self->{fields};

    $patron_id = $fields->{(FID_PATRON_ID)};
    $item_id = $fields->{(FID_ITEM_ID)};
    

    if ($no_block eq 'Y') {
	# Off-line transactions need to be recorded, but there's
	# not a lot we can do about it
	syslog("LOG_WARN", "received no-block checkout from terminal '%s'",
	       $account->{id});

	$status = $ils->checkout_no_block($patron_id, $item_id,
					  $sc_renewal_policy,
					  $trans_date, $nb_due_date);
    } else {
	# Does the transaction date really matter for items that are
	# checkout out while the terminal is online?  I'm guessing 'no'
	$status = $ils->checkout($patron_id, $item_id, $sc_renewal_policy);
    }


    $item = $status->item;
    $patron = $status->patron;

    if ($status->ok) {
	# Item successfully checked out
	# Fixed fields
	$resp = CHECKOUT_RESP . '1';
	$resp .= sipbool($status->renew_ok);
	if ($ils->supports('magnetic media')) {
	    $resp .= sipbool($item->magnetic);
	} else {
	    $resp .= 'U';
	}
	# We never return the obsolete 'U' value for 'desensitize'
	$resp .= sipbool($status->desensitize);
	$resp .= Sip::timestamp;

	# Now for the variable fields
	$resp .= add_field(FID_INST_ID, $inst);
	$resp .= add_field(FID_PATRON_ID, $patron_id);
	$resp .= add_field(FID_ITEM_ID, $item_id);
	$resp .= add_field(FID_TITLE_ID, $item->title_id);
	$resp .= add_field(FID_DUE_DATE, $status->due_date);

	$resp .= maybe_add(FID_SCREEN_MSG, $status->screen_msg);
	$resp .= maybe_add(FID_PRINT_LINE, $status->print_line);

	if ($protocol_version eq '2.00') {
	    if ($ils->supports('security inhibit')) {
		$resp .= add_field(FID_SECURITY_INHIBIT,
				   $status->security_inhibit);
	    }
	    $resp .= maybe_add(FID_MEDIA_TYPE, $item->sip_media_type);
	    $resp .= maybe_add(FID_ITEM_PROPS, $item->sip_item_properties);
	    
	    # Financials
	    if ($status->fee_amount) {
		$resp .= add_field(FID_FEE_AMT, $status->fee_amount);
		$resp .= maybe_add(FID_CURRENCY, $status->sip_currency);
		$resp .= maybe_add(FID_FEE_TYPE, $status->sip_fee_type);
		$resp .= maybe_add(FID_TRANSACTION_ID,
				   $status->transaction_id);
	    }
	}

    } else {
	# Checkout failed
	# Checkout Response: not ok, no renewal, don't know mag. media,
	# no desensitize
	$resp = sprintf("120NUN%s", Sip::timestamp);
	$resp .= add_field(FID_INST_ID, $inst);
	$resp .= add_field(FID_PATRON_ID, $patron_id);
	$resp .= add_field(FID_ITEM_ID, $item_id);

	# We don't know the title, but it's required, so leave it blank
	$resp .= FID_TITLE_ID . $field_delimiter;
	# Due date is required.  Since it didn't get checked out,
	# it's not due, so leave the date blank
	$resp .= FID_DUE_DATE . $field_delimiter;
	
	$resp .= maybe_add(FID_SCREEN_MSG, $status->screen_msg);
	$resp .= maybe_add(FID_PRINT_LINE, $status->print_line);
	
	if ($protocol_version eq '2.00') {
	    # Is the patron ID valid?
	    $resp .= add_field(FID_VALID_PATRON, sipbool($patron));
	    
	    if ($patron && exists($fields->{FID_PATRON_PWD})) {
		# Password provided, so we can tell if it was valid or not
		$resp .= add_field(FID_VALID_PATRON_PWD,
				   sipbool($patron->check_password($fields->{(FID_PATRON_PWD)})));
	    }
	}
    }

    $self->write_msg($resp, $server);
    return(CHECKOUT);
}

sub handle_checkin {
    my ($self, $server) = @_;
    my ($no_block, $trans_date, $return_date);
    my $fields;

    ($no_block, $trans_date, $return_date) = @{$self->{fixed_fields}};
    $fields = $self->{fields};

    printf("handle_checkin:\n");
    printf("    no_block   : %c\n", $no_block);
    printf("    trans_date : %s\n", $trans_date);
    printf("    return_date: %s\n", $return_date);

    foreach my $key (keys(%$fields)) {
	printf("    $key         : %s\n",
	       defined($fields->{$key}) ? $fields->{$key} : 'UNDEF' );
    }

}

sub handle_block_patron {
    my ($self, $server) = @_;
    my $account = $server->{account};
    my $ils = $server->{ils};
    my ($card_retained, $trans_date);
    my ($inst_id, $blocked_card_msg, $patron_id, $terminal_pwd);
    my $fields;
    my $resp;
    my $patron;

    ($card_retained, $trans_date) = @{$self->{fixed_fields}};
    $fields = $self->{fields};
    $inst_id = $fields->{(FID_INST_ID)};
    $blocked_card_msg = $fields->{(FID_BLOCKED_CARD_MSG)};
    $patron_id = $fields->{(FID_PATRON_ID)};
    $terminal_pwd = $fields->{(FID_TERMINAL_PWD)};

    # Terminal passwords are different from account login
    # passwords, but I have no idea what to do with them.  So,
    # I'll just ignore them for now.

    if ($ils->institution ne $inst_id) {
	syslog("WARN", "block_patron: recieved message for institution '%s', expecting '%s'",
	       $inst_id, $ils->institution);
    }

    $patron = $ils->block_patron($patron_id, $card_retained,
				 $blocked_card_msg);

    # The correct response for a "Block Patron" message is a
    # "Patron Status Response", so use that handler to generate
    # the message, but then return the correct code from here.
    # 
    # Normally, the language is provided by the "Patron Status"
    # fixed field, but since we're not responding to one of those
    # we'll just say, "Unspecified", as per the spec.  Let the 
    # terminal default to something that, one hopes, will be 
    # intelligible
    $resp = build_patron_status($patron, '000', $fields);

    $self->write_msg($resp, $server);
    return(BLOCK_PATRON);
}

sub handle_sc_status {
    my ($self, $server) = @_;
    my ($status, $print_width, $sc_protocol_version);

    ($status, $print_width, $sc_protocol_version) = @{$self->{fixed_fields}};

    if ($sc_protocol_version ne $protocol_version) {
	syslog("LOG_INFO", "Setting protocol level to $sc_protocol_version");
	$protocol_version = $sc_protocol_version;
    }

    if ($status == SC_STATUS_PAPER) {
	syslog("LOG_WARN", "Self-Check unit '%s@%s' out of paper",
	       $self->{account}->{id}, $self->{account}->{institution});
    } elsif ($status == SC_STATUS_SHUTDOWN) {
	syslog("LOG_WARN", "Self-Check unit '%s@%s' shutting down",
	       $self->{account}->{id}, $self->{account}->{institution});
    }

    $self->{account}->{print_width} = $print_width;

    return send_acs_status($self, $server) ? SC_STATUS : '';
}

sub handle_request_acs_resend {
    my ($self, $server) = @_;

    if (!$last_response) {
	# We haven't sent anything yet, so respond with a 
	# REQUEST_SC_RESEND msg (p. 16)
	$self->write_msg(REQUEST_SC_RESEND, $server);
    } elsif ((length($last_response) < 9)
	     || substr($last_response, -9, 2) ne 'AY') {
	# When resending a message, we aren't supposed to include
	# a sequence number, even if the original had one (p. 4).
	# If the last message didn't have a sequence number, then
	# we can just send it.
	print("$last_response\r");
    } else {
	my $rebuilt;

	# Cut out the sequence number and checksum, since the old
	# checksum is wrong for the resent message.
	$rebuilt = substr($last_response, 0, -9);
	$self->write_msg($rebuilt, $server);
    }

    return REQUEST_ACS_RESEND;
}

sub handle_login {
    my ($self, $server) = @_;
    my ($uid_algorithm, $pwd_algorithm);
    my ($uid, $pwd);
    my $fields;
    my $status = 1;		# Assume it all works

    $fields = $self->{fields};
    ($uid_algorithm, $pwd_algorithm) = @{$self->{fixed_fields}};

    $uid = $fields->{(FID_LOGIN_UID)};
    $pwd = $fields->{(FID_LOGIN_PWD)};

    if ($uid_algorithm || $pwd_algorithm) {
	syslog("LOG_ERR", "LOGIN: Can't cope with non-zero encryption methods: uid = $uid_algorithm, pwd = $pwd_algorithm");
	$status = 0;
    }

    if (!exists($server->{config}->{accounts}->{$uid})) {
	syslog("LOG_WARNING", "MsgType::handle_login: Unknown login '$uid'");
	$status = 0;
    } elsif ($server->{config}->{accounts}->{$uid}->{password} ne $pwd) {
	syslog("LOG_WARNING",
	       "MsgType::handle_login: Invalid password for login '$uid'");
	$status = 0;
    }
    
    # Store the active account someplace handy for everybody else to find.
    if ($status) {
	$server->{account} = $server->{config}->{accounts}->{$uid};
	syslog("LOG_INFO", "Successful login for '%s' of '%s'",
	       $server->{account}->{id}, $server->{account}->{institution});
    }

    $self->write_msg(LOGIN_RESP . $status, $server);

    return $status ? LOGIN : '';
}

sub handle_patron_info {
    my ($self, $server) = @_;
    my ($lang, $trans_date, $summary) = $self->{fixed_fields};
    my $fields = $self->{fields};

}

sub handle_end_patron_session {
    my ($self, $server) = @_;
    my $trans_date;
    my $fields;

    #  No tagged fields are required.
    ($trans_date) = @{$self->{fixed_fields}};
    $fields = $self->{fields};

    printf("handle_end_patron_session\n");
    printf("    trans_date: %s\n", $trans_date);

    foreach my $key (keys(%$fields)) {
	printf("    $key        : %s\n",
	       defined($fields->{$key}) ? $fields->{$key} : 'UNDEF' );
    }
}

sub handle_fee_paid {
    my ($self, $server) = @_;
    my ($trans_date, $fee_type, $pay_type, $currency) = $self->{fixed_fields};
    my $fields = $self->{fields};
}

sub handle_item_information {
    my ($self, $server) = @_;
    my $trans_date;
    my $fields;

    ($trans_date) = @{$self->{fixed_fields}};

    printf("handle_item_information:\n");
    printf("    trans_date: %s\n", $trans_date);

    $fields = $self->{fields};
    foreach my $key (keys(%$fields)) {
	printf("    $key        : %s\n",
	       defined($fields->{$key}) ? $fields->{$key} : 'UNDEF' );
    }
}

sub handle_item_status_update {
    my ($self, $server) = @_;
    my $trans_date;
    my $fields;

    ($trans_date) = @{$self->{fixed_fields}};

    printf("handle_item_status_update:\n");
    printf("    trans_date: %s\n", $trans_date);

    $fields = $self->{fields};
    foreach my $key (keys(%$fields)) {
	printf("    $key        : %s\n",
	       defined($fields->{$key}) ? $fields->{$key} : 'UNDEF' );
    }
}

sub handle_patron_enable {
    my ($self, $server) = @_;
    my $trans_date;
    my $fields;

    ($trans_date) = @{$self->{fixed_fields}};

    printf("handle_patron_enable:\n");
    printf("    trans_date: %s\n", $trans_date);

    $fields = $self->{fields};
    foreach my $key (keys(%$fields)) {
	printf("    $key        : %s\n",
	       defined($fields->{$key}) ? $fields->{$key} : 'UNDEF' );
    }
}

sub handle_hold {
    my ($self, $server) = @_;
    my ($hold_mode, $trans_date);
    my $fields;

    ($hold_mode, $trans_date) = @{$self->{fixed_fields}};


    printf("handle_hold:\n");
    printf("    hold_mode : %c\n", $hold_mode);
    printf("    trans_date: %s\n", $trans_date);

    $fields = $self->{fields};
    foreach my $key (keys(%$fields)) {
	printf("    $key        : %s\n",
	       defined($fields->{$key}) ? $fields->{$key} : 'UNDEF' );
    }
}

sub handle_renew {
    my ($self, $server) = @_;
    my ($third_party, $no_block, $trans_date, $nb_due_date);
    my $fields;

    ($third_party, $no_block, $trans_date, $nb_due_date) =
	@{$self->{fixed_fields}};

    printf("handle_renew:\n");
    printf("    3d party   : %c\n", $third_party);
    printf("    no_block   : %c\n", $no_block);
    printf("    trans date : %s\n", $trans_date);
    printf("    nb_due_date: %s\n", $nb_due_date);

    $fields = $self->{fields};
    foreach my $key (keys(%$fields)) {
	printf("    $key        : %s\n",
	       defined($fields->{$key}) ? $fields->{$key} : 'UNDEF' );
    }

}

sub handle_renew_all {
    my ($self, $server) = @_;
    my $trans_date;
    my $fields;

    ($trans_date) = @{$self->{fixed_fields}};

    printf("handle_renew_all:\n");
    printf("    trans_date: %s\n", $trans_date);

    $fields = $self->{fields};
    foreach my $key (keys(%$fields)) {
	printf("    $key        : %s\n",
	       defined($fields->{$key}) ? $fields->{$key} : 'UNDEF' );
    }
}

#
# send_acs_status($self, $server)
#
# Send an ACS Status message, which is contains lots of little fields
# of information gleaned from all sorts of places.
#
sub send_acs_status {
    my ($self, $server, $screen_msg, $print_line) = @_;
    my $msg = ACS_STATUS;
    my $account = $server->{account};
    my $policy = $server->{policy};
    my $ils = $server->{ils};
    my ($online_status, $checkin_ok, $checkout_ok, $ACS_renewal_policy);
    my ($status_update_ok, $offline_ok, $timeout, $retries);

    $online_status = 'Y';
    $checkout_ok = sipbool($ils->checkout_ok);
    $checkin_ok = sipbool($ils->checkin_ok);
    $ACS_renewal_policy = sipbool($policy->{renewal});
    $status_update_ok = sipbool($ils->status_update_ok);
    $offline_ok = sipbool($ils->offline_ok);
    $timeout = sprintf("%03d", $policy->{timeout});
    $retries = sprintf("%03d", $policy->{retries});

    if (length($timeout) != 3) {
	syslog("LOG_ERR", "handle_acs_status: timeout field wrong size: '%s'",
	       $timeout);
	$timeout = '000';
    }

    if (length($retries) != 3) {
	syslog("LOG_ERR", "handle_acs_status: retries field wrong size: '%s'",
	       $retries);
	$retries = '000';
    }

    $msg .= "$online_status$checkin_ok$checkout_ok$ACS_renewal_policy";
    $msg .= "$status_update_ok$offline_ok$timeout$retries";
    $msg .= Sip::timestamp();
    $msg .= $protocol_version;

    # Institution ID
    $msg .= FID_INST_ID . $account->{institution} . $field_delimiter;

    if ($protocol_version eq '2.00') {
	# Supported messages: we do it all
	$msg .= FID_SUPPORTED_MSGS . 'YYYYYYYYYYYYYYYY' . $field_delimiter;
    }

    $msg .= maybe_add(FID_SCREEN_MSG, $screen_msg);

    if (defined($account->{print_width}) && defined($print_line)
	&& $account->{print_width} < length($print_line)) {
	syslog("LOG_WARNING", "send_acs_status: print line '%s' too long.  Truncating",
	       $print_line);
	$print_line = substr($print_line, 0, $account->{print_width});
    }

    $msg .= maybe_add(FID_PRINT_LINE, $print_line);

    # Do we want to tell the terminal its location?

    $self->write_msg($msg, $server);
    return 1;
}

#
# add_field(field_id, value)
#    return constructed field value
#
sub add_field {
    my ($field_id, $value) = @_;

    return $field_id . $value . $field_delimiter;
}
#
# maybe_add(field_id, value):
#    If value is defined and non-empty, then return the
#    constructed field value, otherwise return the empty string
#
sub maybe_add {
    my ($fid, $value) = @_;

    return (defined($value) && $value) ? $fid . $value . $field_delimiter : '';
}

#
# build_patron_status: create the 14-char patron status
# string for the Patron Status message
#
sub patron_status_string {
    my $patron = shift;
    my $patron_status;

    $patron_status = sprintf('%s%s%s%s%s%s%s%s%s%s%s%s%s%s',
			     denied($patron->charge_ok),
			     denied($patron->renew_ok),
			     denied($patron->recall_ok),
			     denied($patron->hold_ok),
			     boolspace($patron->card_lost),
			     boolspace($patron->too_many_charged),
			     boolspace($patron->too_many_overdue),
			     boolspace($patron->too_many_renewal),
			     boolspace($patron->too_many_claim_return),
			     boolspace($patron->too_many_lost),
			     boolspace($patron->excessive_fines),
			     boolspace($patron->excessive_fees),
			     boolspace($patron->recall_overdue),
			     boolspace($patron->too_many_billed));
    return $patron_status;
}

#
# denied($bool)
# if $bool is false, return true.  This is because SIP statuses
# are inverted:  we report that something has been denied, not that
# it's permitted.  For example, 'renewal priv. denied' of 'Y' means
# that the user's not permitted to renew.  I assume that the ILS has
# real positive tests.
# 
sub denied {
    my $bool = shift;

    if (!$bool || ($bool eq 'N') || $bool eq 'False') {
	return 'Y';
    } else {
	return ' ';
    }
}

sub sipbool {
    my $bool = shift;

    if (!$bool || ($bool =~/^false|n|no$/i)) {
	return('N');
    } else {
	return('Y');
    }
}

#
# boolspace: ' ' is false, 'Y' is true. (don't ask)
# 
sub boolspace {
    my $bool = shift;

    if (!$bool || ($bool eq 'N' || $bool eq 'False')) {
	return ' ';
    } else {
	return 'Y';
    }
}
#
# write_msg($msg, $server)
#
# Send $msg to the SC.  If error detection is active, then 
# add the sequence number (if $seqno is non-zero) and checksum
# to the message, and save the whole thing as $last_response
#

sub write_msg {
    my ($self, $msg, $server) = @_;
    my $cksum;

    if ($error_detection) {
	if ($self->{seqno}) {
	    $msg .= 'AY' . $self->{seqno};
	}
	$msg .= 'AZ';
	$cksum = checksum($msg);
	$msg .= sprintf('%4X', $cksum);
    }

    syslog("LOG_DEBUG", "OUTPUT MSG: '$msg'");

    print "$msg\r";
    $last_response = $msg;
}

1;
