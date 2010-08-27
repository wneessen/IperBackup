#!/usr/bin/perl -wt
#
# Filename:     IperBackup/Download.pm
# Description:  Download module to IperBackup
# Creator:      Winfried Neessen <doomy@pebcak.de>
#
# $Id$
#
# Last modified: [ 2010-08-27 15:29:34 ]

## This is the IperBackup::Process package {{{
package IperBackup::Download;

## Load some modules {{{
use warnings;
use strict;
use Carp qw( carp croak );
use Data::Dumper;
use LWP::UserAgent;
use Time::HiRes;
use URI;
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

	## Create LWP object
	$self->{ 'ua' } = LWP::UserAgent->new
	(

		agent		=> 'IperBackup/v' . VERSION,
		keep_alive	=> 1,
		env_proxy	=> 1,
		show_progress	=> 1,

	);

	## Return the object
	return $self;

}
# }}}

## Download the file // download() {{{
sub download
{

	## Get object and URL to fetch
	my ( $self, $uri, $file ) = @_;

	## Don't go further if no URL or filename has been given
	return undef unless( defined( $uri ) and defined( $file ) );
	
	## Get Logger object
	my $log = IperBackup::Main::get_logger( 'download' );

	## Create URI object from uri string
	my $url = URI->new( $uri );

	## Log an information message
	$log->info( 'Downloading ' . $url . ' into ' . $file . '...' );
	
	## Start some benchmarking
	my $bm_start = [ Time::HiRes::gettimeofday ];

	## Create a new HTTP request
	$self->{ 'request' } = $self->{ 'ua' }->get( $url, ':content_file' => $file );

	## Download is done... let's see if it was a success
	if( $self->{ 'request' }->is_success == 1 )
	{

		## Finish the benchmarking
		$log->info( 'Download successfully finished in ' . sprintf( '%.3f', Time::HiRes::tv_interval( $bm_start ) ) . ' seconds' );

	} else {

		## The download was not successfull
		$log->error( 'Download unsuccessfully finished.' );

	}

	## Return to the caller
	return undef;

}
# }}}



## Every module needs a true ending...
1;
# }}}
