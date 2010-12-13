#!/usr/bin/perl -wt
#
# Filename:     IperBackup/Config.pm
# Description:  Module to handle the configuration file
# Creator:      Winfried Neessen <doomy@pebcak.de>
#
# $Id$
#
# Last modified: [ 2010-12-13 15:37:20 ]

## This is the IperBackup::Config package {{{
package IperBackup::Config;

## Load some modules {{{
use warnings;
use strict;
use Carp qw( carp croak );
# }}}

## Defined constants {{{
use constant CONFFILE				=> '/etc/IperBackup.conf';				## Absolute path to config file if non is defined
use constant EXT_DEBUG				=> 0;								## Enable extended debug logging
use constant VERSION				=> '0.05';							## This modules version
# }}}

## Constuctor // new() {{{
sub new 
{

	## Read arguments
	my ( $class, %args ) = @_;

	## Get Logger object
	my $log = IperBackup::Main::get_logger( 'new' );

	## Reference object to class
	my $self = bless {}, $class;

	## Get the absolute path to the config file
	$self->{ 'conf_file' }	= delete( $args{ 'conf_file' } ) || CONFFILE;

	## Config file needs to be set for this object
	unless( defined( $self->{ 'conf_file' } ) )
	{
		$log->error( 'The config file path is mandatory for IperBackup::Config::new()' );
		return undef;
	}

	## Return the object
	return $self;

}
# }}}

## Read the configuration file // readconf() {{{
sub readconf
{

	## Get object
	my $self = shift;
	
	## Get Logger object
	my $log = IperBackup::Main::get_logger( 'readconf' );

	## Get filename of config file
	my $conffile = $self->is_present();

	## Die if the conffile is non-present
	unless( defined( $conffile ) ) 
	{
		$log->error( 'Config file ' . $self->{ 'conf_file' } . ' not present. Aborting.' );
		return undef;
	}

	## Open the config file
	open ( CONFIG, $conffile )
		or $log->logcroak( 'Unable to open config file: ' . $! );

	## Read the whole config file into an array
	my @config = <CONFIG>;

	## Close the file handle
	close( CONFIG );

	## Interpret the config values
	my $config = $self->process( @config );

	## Return the config hashref
	return $config;

}
# }}}

## Interpret the single config file values // process() {{{
sub process
{

	## Get object
	my ( $self, @config ) = @_;
	my $confhash;
	
	## Get Logger object
	my $log = IperBackup::Main::get_logger( 'process' );

	## Interpret the single config lines
	foreach my $line ( @config )
	{

		## Clean up line feeds
		chomp( $line );

		## Ignore comments and blank lines
		next if $line =~ /^(#|;)/;
		next if $line eq '';

		## Extract key and value
		$line =~ /\s*(\w+)\s*=\s*"(.+?)".*/i;
		$confhash->{ $1 } = $2;
		
		## Log something if ext. debug is enabled
		EXT_DEBUG && $log->debug( 
			'Received config line: ' . $line . ' // ',
			'Extracted -> Key: ' . $1 . ' -- Value: ' . $2
		);

	}

	## Return the hashref
	return $confhash;

}
# }}}

## Verify that the config file is present // is_present() {{{
sub is_present
{

	## Get object
	my $self = shift;
	
	## Get Logger object
	my $log = IperBackup::Main::get_logger( 'is_present' );

	## Build a full path out of the servername and the path (if file is present)
	my $conffile = $self->{ 'conf_file' } 
		if -r $self->{ 'conf_file' };

	## Return the full path
	return $conffile;

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
