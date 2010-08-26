#!/usr/bin/perl -wt
#
# Filename:     IperBackup/Process.pm
# Description:  Main processing module to IperBackup
# Creator:      Winfried Neessen <doomy@pebcak.de>
#
# $Id$
#
# Last modified: [ 2010-08-26 17:54:37 ]

## This is the IperBackup::Process package {{{
package IperBackup::Process;

## Load some modules {{{
use warnings;
use strict;
use Carp qw( carp croak );
use Data::Dumper;
# }}}

## Defined constants {{{
use constant EXT_DEBUG				=> 0;								## Enable extended debug logging
use constant VERSION				=> '0.100';							## This modules version
# }}}

## Constuctor // new() {{{
sub new 
{

	## Read arguments
	my $class = shift;
	my $args = shift;

	## Get Logger object
	my $log = IperBackup::Main::get_logger( 'new' );

	## Reference object to class
	my $self = bless {}, $class;

	## Get the API object
	if( defined( $args->{ 'api' } ) )
	{
		$self->{ 'api' } = $args->{ 'api' };

	}
	
	## Get the config object
	if( defined( $args->{ 'config' } ) )
	{
		$self->{ 'config' } = $args->{ 'config' };

	}

	## API object needs to be provided
	unless( defined( $self->{ 'api' } ) )
	{
		$log->error( 'The API object is mandatory for IperBackup::Process::new()' );
		return undef;
	}

	## Return the object
	return $self;

}
# }}}

### Generate and fetch an AuthToken // getToken() {{{
sub getToken
{

	## Get object
	my $self = shift;

	## Retrieve a API frob
	my $frob = $self->{ 'api' }->fetchfrob();

	## Generate an authentication URL to Ipernity
	my $authurl = $self->{ 'api' }->authurl
	(
		frob	=> $frob,
		perms	=> { perm_doc => 'read' }

	);

	## Provide AuthURL to user
	print "Your configuration is missing an AuthToken and/or your UserID, which\n";
	print "both are mandatory.\n\n";
	print "Please open the following URL in your web browser to grant IperBackup\n";
	print "access to your Ipernity account. After giving the permission, please\n";
	print "hit the <ENTER> key to fetch the AuthToken and UserID.\n\n";
	print $authurl . "\n\n";

	## Wait for user confirmation
	my $undef = <STDIN>;

	## Receive the authtoken from Ipernity
	my $token = $self->{ 'api' }->authtoken( $frob );

	## Provide token to user
	print "Thanks for granting IperBackup access to your Ipernity account.\n\n";
	print "Your AuthToken is: " . $token . "\n";
	print "Your UserID is:    " . $self->{ 'api' }->{ 'auth' }->{ 'userid' } . "\n\n";
	print "Please put the following 2 configuration parameters to your IperBackup.conf \n";
	print "file:\n\n";
	print ",----\n";
	print "| IPER_API_AUTHTOKEN = \"" . $token . "\"\n";
	print "| IPER_USERID = \"" . $self->{ 'api' }->{ 'auth' }->{ 'userid' } . "\"\n";
	print "`----\n";

	## End here
	exit 0;

}
# }}}

### Fetch number of documents in the Ipernity account // getNumberDocs() {{{
sub getNumberDocs
{

	## Get object
	my $self = shift;

	## Read user information via API
	my $userinfo = $self->{ 'api' }->execute_hash
	(

		method		=> 'user.get',
		auth_token	=> $self->{ 'config' }->{ 'IPER_API_AUTHTOKEN' },

	);

	## Return number of docs to caller
	return $userinfo->{ 'user' }->{ 'count' }->{ 'docs' } || undef;

}
# }}}

## Every module needs a true ending...
1;
# }}}
