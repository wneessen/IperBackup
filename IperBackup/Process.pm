#!/usr/bin/perl -wt
#
# Filename:     IperBackup/Process.pm
# Description:  Main processing module to IperBackup
# Creator:      Winfried Neessen <doomy@pebcak.de>
#
# $Id$
#
# Last modified: [ 2010-08-27 15:35:36 ]

## This is the IperBackup::Process package {{{
package IperBackup::Process;

## Load some modules {{{
use warnings;
use strict;
use Carp qw( carp croak );
use Data::Dumper;
use Time::HiRes;
# }}}

## Defined constants {{{
use constant EXT_DEBUG				=> 0;								## Enable extended debug logging
use constant PER_PAGE				=> 100;								## Number of documents per page to fetch
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

### Fetch user information from the Ipernity account // getUserInfo() {{{
sub getUserInfo
{

	## Get object
	my ( $self, $type ) = @_;

	## We need a type of information that has been requested
	return undef unless defined( $type );

	## Read user information via API
	my $userinfo = $self->{ 'api' }->execute_hash
	(

		method		=> 'user.get',
		auth_token	=> $self->{ 'config' }->{ 'IPER_API_AUTHTOKEN' },

	);

	## Return requested user information to caller
	return $userinfo->{ 'user' }->{ $type } || undef;

}
# }}}

### Fetch document information from Ipernity account // getDocsList() {{{
sub getDocsList
{

	## Get object
	my $self = shift;
	
	## Get Logger object
	my $log = IperBackup::Main::get_logger( 'getDocsList' );

	## Temporary varible for hash table
	my ( $docs );

	## Start some benchmarking
	my $bm_start = [ Time::HiRes::gettimeofday ];

	## Log an info message
	$log->info( 'Retriving list of documents to be fetched...' );

	## Get number of pages to be fetched
	my $pages = $self->getNumberPages();
	$log->debug( 'There a 6 pages of documents (' . PER_PAGE . ' documents each) to be fetched...' );

	## Retrieve all document ids and URLs from every page
	for my $page ( 1 .. $pages )
	{

		## Log a debug message
		$log->debug( "Retrieving docs from page $page..." );

		## Get document list and run through it
		foreach my $doc ( @{ $self->getDocIDs( $page ) } )
		{

			## Get document ID for hash table assignment
			my $docid = $doc->{ 'doc_id' };

			## Store download URL and filename in hash table
			$docs->{ $docid }->{ 'url' } = $doc->{ 'original' }->{ 'url' };
			$docs->{ $docid }->{ 'fn' }  = $doc->{ 'original' }->{ 'filename' };

			## Log some ext. debug message
			EXT_DEBUG && $log->debug( 'Found document "' . $docs->{ $docid }->{ 'fn' } . '" (Document ID: ' . $docid . ')' );
			EXT_DEBUG && $log->debug( 'Download URL: ' . $docs->{ $docid }->{ 'url' } );

		}
	}
	
	## End the benchmarking
	$log->debug( 'Document list generated in ' . sprintf( '%.3f', Time::HiRes::tv_interval( $bm_start ) ) . ' seconds' );

	## Return hash table to caller
	return $docs;

}
# }}}

### Retrieve number of pages that have to be fetched // getNumberPages() {{{
sub getNumberPages
{

	## Get object
	my $self = shift;

	## Read documents information via API
	my $docinfo = $self->{ 'api' }->execute_hash
	(

		method		=> 'doc.getList',
		auth_token	=> $self->{ 'config' }->{ 'IPER_API_AUTHTOKEN' },
		per_page	=> PER_PAGE,

	);

	## Return number of docs to caller
	return $docinfo->{ 'docs' }->{ 'pages' } || undef;

}
# }}}

### Retrieve document IDs // getDocIDs() {{{
sub getDocIDs
{

	## Get object
	my ( $self, $page ) = @_;

	## A page number is mandatory
	return undef unless defined( $page );

	## Get Logger object
	my $log = IperBackup::Main::get_logger( 'getDocIDs' );

	## Read documents information via API
	my $docinfo = $self->{ 'api' }->execute_hash
	(

		method		=> 'doc.getList',
		auth_token	=> $self->{ 'config' }->{ 'IPER_API_AUTHTOKEN' },
		per_page	=> PER_PAGE,
		page		=> $page,
		extra		=> 'original',

	);

	## Return number of docs to caller
	return $docinfo->{ 'docs' }->{ 'doc' } || undef;

}
# }}}

### Validate output filename // isValidFile() {{{
sub isValidFile
{

	## Get object
	my ( $self, $dir, $name ) = @_;

	## Don't process if not all arguments are given
	return undef unless( defined( $dir ) and defined( $name ) );

	## Store timestamp for later usage
	my $time = time;
	
	## Get Logger object
	my $log = IperBackup::Main::get_logger( 'isValidFile' );

	## Check if output dir is present and writeable
	my $outdir = $dir if( -w $dir ) || 
	do{ $log->error( 'Output directory not writeable. Aborting.' ); return undef; };

	## Check if file is already present
	if( -f $dir . '/' . $name )
	{

		## Add timestamp to filename if file already present
		$log->warn( 'File ' . $name . ' is already present. Will save file as: ' . $time . '_' . $name );
		$self->{ 'filename' } = $dir . '/' . $time . '_' . $name;

	} else {

		## File is not present, so we can safely use the name
		$self->{ 'filename' } = $dir . '/' . $name;

	}

	## Return the output filename
	return $self->{ 'filename' };

}
# }}}



## Every module needs a true ending...
1;
# }}}
