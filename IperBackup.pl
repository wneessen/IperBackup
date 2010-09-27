#!/usr/bin/perl
#
# Filename:     IperBackup.pl
# Description:  Main script of Ipernity::Backup
# Creator:      Winfried Neessen <doomy@pebcak.de>
#
# $Id$
#
# Last modified: [ 2010-09-27 10:33:08 ]

## This is the IperBackup::Main package {{{
package IperBackup::Main;

### Global modules {{{
use strict;
use warnings;
#use Data::Dumper; ## Debug only
use Getopt::Long;
use IperBackup::Config;
use IperBackup::Download;
use IperBackup::Process;
use Ipernity::API;
use Log::Log4perl qw(:easy);
# }}}

### Basic configuration variables {{{
use constant EXT_DEBUG					=> 0;						## Enable extended debug-logging
use constant LOGLEVEL					=> 'INFO';					## Set the log level
use constant OUTDIR					=> '/var/tmp';					## Default output directory
use constant VERSION					=> '0.01';					## Current version number
# }}}

## Define global variables {{{
my ( $config );
# }}}

### Log4Perl Configuration {{{
my $log4perl = q(
	log4perl.rootLogger					= ) . LOGLEVEL . q(, Screen
	log4perl.appender.Screen				= Log::Log4perl::Appender::Screen
	log4perl.appender.Screen.stderr				= 0
	log4perl.appender.Screen.layout				= PatternLayout
	log4perl.appender.Screen.layout.ConversionPattern	= %d [%p]: %m%n
);
Log::Log4perl->init( \$log4perl );
Log::Log4perl->wrapper_register(__PACKAGE__);
# }}}

### Main subroutine // main() {{{
sub main
{

	## Get a log object
	my $log = get_logger('Main');

	## Read command line arguments
	getArgs();
	
	## Create a config object {{{
	my $conf = IperBackup::Config->new
	({

		conf_file	=> $config->{ 'conffile' },

	});
	# }}}
		
	## Read the config file
	my $myconfig = $conf->readconf();

	## Don't execute anything if no config is present
	$log->logcroak( 'Unable to execute script, without a config file. Aborting.' ) unless defined( $myconfig );
	
	## Create an IperBackup::Download object
	my $dl = IperBackup::Download->new();
	
	## Create an API object {{{
	my $api = Ipernity::API->new
	({
		api_key		=> $myconfig->{ 'IPER_API_KEY' },
		secret		=> $myconfig->{ 'IPER_API_SECRET' },
		outputformat	=> $myconfig->{ 'IPER_API_OUTPUT' },

	});
	# }}}
	
	## Create an IperBackup::Process object {{{
	my $iper = IperBackup::Process->new
	({
		api	=> $api,
		config	=> $myconfig,

	});
	# }}}

	## An authtoken is mandatory, fetch one if non-existant {{{
	unless( defined( $myconfig->{ 'IPER_API_AUTHTOKEN' } ) and defined( $myconfig->{ 'IPER_USERID' } ) )
	{

		$iper->getToken( $api );

	}
	# }}}

	## Get number of documents
	my $docsnumber = $iper->getNumberDocs();

	## Show user how many docs going to be fetched
	$log->info( "Found " . $docsnumber . " documents for user account " . $iper->getUserInfo( 'username' ) . " (" . $iper->getUserInfo( 'realname' ) . ")" );

	## Get list of documents
	my $documents = $iper->getDocsList();

	## Decide which action to perform... the real download {{{
	if( defined( $config->{ 'download' } ) )
	{
		
		## Go through each document and download it
		foreach my $doc ( keys %{ $documents } )
		{

			## Make URL easily accessable
			my $url = $documents->{ $doc }->{ 'url' };

			## Generate absolute path to download filename
			my $file = $iper->isValidFile( $config->{ 'dir' } || OUTDIR, $documents->{ $doc }->{ 'fn' } );

			## Download file from Ipernity
			$dl->download( $url, $file );

		}

	}
	# }}}

	## ...or just creating a download list {{{
	elsif( defined( $config->{ 'list' } ) )
	{

		## Generate a full absolute path to the DL list
		my $file = $iper->isValidFile( $config->{ 'dir' } || OUTDIR, 'IperBackup.list' );

		## Inform the user where the DL list will be stored
		$log->info( 'Creating download link list: ' . $file );

		## Open the list a FH
		open( FH, '>', $file )
			or $log->logcroak( 'Unable to write DL list: ' . $! );
		
		## Go through each document and download it
		foreach my $doc ( keys %{ $documents } )
		{

			## Write it into the list
			print FH $documents->{ $doc }->{ 'url' } . "\n";

		}

		## Close the FH
		close( FH );

	}
	# }}}



}
# }}}

### Read arguments from command line // getArgs() {{{
sub getArgs
{

	GetOptions
	(

		'outdir|o=s'	=> \$config->{ 'dir' },
		'config|c=s'	=> \$config->{ 'conffile' },
		'help|h'	=> \$config->{ 'help' },
		'list|l'	=> \$config->{ 'list' },
		'download|d'	=> \$config->{ 'download' },

	);
	showHelp() if( $config->{ 'help' } );
	showHelp() unless( defined( $config->{ 'list' } ) or defined( $config->{ 'download' } ) );
	showHelp() if( defined( $config->{ 'list' } ) and defined( $config->{ 'download' } ) );

}
# }}}

### Provide some help messages if requested // showHelp() {{{
sub showHelp
{

	## Print message
	print "Usage: $0 [OPTIONS]\n";
	print "\n\t-o, --outdir\t\tSpecify absolute path to the output directory (Default: /var/tmp)";
	print "\n\t-c, --config\t\tSpecify absolute path to config file (Default: /etc/IperBackup.conf)";
	print "\n\t-d, --download\t\tTell IperBackup to download all files in your account";
	print "\n\t-l, --list\t\tTell IperBackup to create a list of files in you account";
	print "\n\t-h, --help\t\tDisplay this help message.\n";
	print "\n";

	## Exit with non-zero error code
	exit 127;

}
# }}}


### Execute main routine
main();
1;
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
