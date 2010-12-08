#!/usr/bin/perl -wt
#
# Filename:     IperBackup/Update.pm
# Description:  Update module to IperBackup
# Creator:      Winfried Neessen <doomy@pebcak.de>
#
# $Id$
#
# Last modified: [ 2010-12-08 16:25:22 ]

## This is the IperBackup::Update package {{{
package IperBackup::Update;

## Load some modules {{{
use warnings;
use strict;
use Carp qw( carp croak );
#use Data::Dumper;
use LWP::UserAgent;
use URI;
# }}}

## Defined constants {{{
use constant BASE_URL				=> 'http://blog.pebcak.de/tmp/IperBackupVersion.txt';		## URL with version sting of latest release
use constant DL_URL				=> 'http://svn.neessen.net/listing.php?repname=IperBackup';	## URL where to get latest release
use constant EXT_DEBUG				=> 0;								## Enable extended debug logging
use constant VERSION				=> '0.05';							## This modules version
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
		show_progress	=> 0,

	);

	## Return the object
	return $self;

}
# }}}

## Check version string of latest release // checkVersion() {{{
sub checkVersion
{

	## Get object and version of current release
	my ( $self, $version ) = @_;

	## Don't go further if no version has been given
	return undef unless( defined( $version ) );
	
	## Get Logger object
	my $log = IperBackup::Main::get_logger( 'checkVersion' );

	## Create URI object from uri string
	my $url = URI->new( BASE_URL );

	## Create a new HTTP request
	$self->{ 'request' } = $self->{ 'ua' }->get( $url );

	## Download is done... let's see if it was a success
	if( $self->{ 'request' }->is_success == 1 )
	{

		## Store latest version in object
		$self->{ 'latest' } = $self->{ 'request' }->decoded_content;
		chomp( $self->{ 'latest' } );

	} else {

		## The download was not successfull
		$log->warn( 'Couldn\'t fetch version information.' );

	}

	## Check if latest version is higher than current
	if( $self->{ 'latest' } > $version )
	{

		print "A new version of IperBackup is available. You are currently using v" . $version . ", but\n";
		print "the latest available version is v" . $self->{ 'latest' } . "\n\n";
		print "It is recommended to upgrade to the latest release. Find it at:\n";
		print DL_URL . "\n";
		my $foo = <STDIN>;

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
