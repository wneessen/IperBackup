#!/usr/bin/perl -wt
#
# Filename:     IperBackup/Download.pm
# Description:  Download module to IperBackup
# Creator:      Winfried Neessen <doomy@pebcak.de>
#
# $Id$
#
# Last modified: [ 2010-09-27 10:33:25 ]

## This is the IperBackup::Process package {{{
package IperBackup::Download;

## Load some modules {{{
use warnings;
use strict;
use Carp qw( carp croak );
#use Data::Dumper;
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
__END__
=head1 LICENSE
Copyright (c) 2010, Winfried Neessen <doomy@dokuleser.org>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the neessen.net nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
