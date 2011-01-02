#!/usr/bin/perl
#
# Filename:     IperBackup.pl
# Description:  Main script of Ipernity::Backup
# Creator:      Winfried Neessen <doomy@pebcak.de>
#
# $Id$
#
# Last modified: [ 2011-01-02 20:28:30 ]

## This is the IperBackup::Main package {{{
package IperBackup::Main;

### Global modules {{{
use strict;
use warnings;
#use Data::Dumper; ## Debug only
use Date::Manip;
use Getopt::Long;
use IperBackup::Config;
use IperBackup::Download;
use IperBackup::Process;
use IperBackup::Update;
use Ipernity::API;
use Log::Log4perl qw(:easy);
# }}}

### Basic configuration variables {{{
use constant DEFAULT_MEDIA				=> 'photo,video,audio,other';			## Default media types
use constant EXT_DEBUG					=> 0;						## Enable extended debug-logging
use constant LOGLEVEL					=> 'INFO';					## Set the log level
use constant OUTDIR					=> '/var/tmp';					## Default output directory
use constant VERSION					=> '0.07';					## Current version number
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

### Check version of Ipernity::API module {{{
BEGIN
{

	my $API = $Ipernity::API::VERSION;
	do{ print "Ipernity::API v0.08 or higher required.\n"; exit 127; }
		unless( $API >= 0.08 );

}
# }}}

### Main subroutine // main() {{{
sub main
{

	## Get a log object
	my $log = get_logger('Main');

	## Check for updates
	checkUpdate();

	## Read command line arguments
	getArgs();
	
	## Create a config object {{{
	my $conf = IperBackup::Config->new
	(

		conf_file	=> $config->{ 'conffile' },

	);
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
	(
		api		=> $api,
		config		=> $myconfig,
		media		=> $config->{ 'media' } || DEFAULT_MEDIA,
		tags		=> $config->{ 'tags' } || undef,
		startdate	=> $config->{ 'startdate' } || undef,
		enddate		=> $config->{ 'enddate' } || undef,
		permission	=> $config->{ 'permission' } || undef,

	);
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
	$log->info( "Found " . $docsnumber . " documents in total for user account " . $iper->getUserInfo( 'username' ) . " (" . $iper->getUserInfo( 'realname' ) . ")" );

	## Get list of documents
	my $documents = $iper->getDocsList();

	## Calculate number of documents to fetch
	my $docCount = scalar( keys %{ $documents } );

	## Don't process any further if no document was found
	exit 127 if $docCount == 0;

	## Inform the user about the number of documents to be fetched
	$log->info( 'Will fetch ' . scalar( keys %{ $documents } ) . ' documents of the media type(s): ' . join( ', ', split( /,/, $config->{ 'media' } || DEFAULT_MEDIA ) ) );
	$log->info( 'Specified tags: ' . join( ', ', split( /,/, $config->{ 'tags' } ) ) ) if defined $config->{ 'tags' };

	## Decide which action to perform... the real download {{{
	if( defined( $config->{ 'download' } ) )
	{
		
		## Go through each document and download it
		foreach my $doc ( keys %{ $documents } )
		{

			## Make URL easily accessable
			my $url = $documents->{ $doc }->{ 'url' };

			## Generate absolute path to download filename
			my $file = $iper->isValidFile( $config->{ 'dir' } || OUTDIR, $documents->{ $doc }->{ 'fn' }, $doc );

			## If we wanna fetch comments, check if there are some
			if( defined( $config->{ 'comment' } ) )
			{

				## Get list of comments for the document ID
				my $commentPages = $iper->getCommentNumberPages( $doc );

				## Don't go any further if is no comment
				if( defined( $commentPages ) )
				{
					
					## Get comments via API
					my $comments = $iper->getCommentList( $doc, $commentPages );

					## Log a information message
					$log->info( 'Storing comments in ' .  $file . '_comments.txt' );

					## Open file to store comments in
					open( COMMENTS, '>', $file . '_comments.txt' )
						or $log->logcroak( 'Unable to open ' . $file . '_comments.txt for writing comments.' );

					## Go through each comment we have and store it
					foreach my $comid ( keys %{ $comments->{ $doc } } )
					{

						## Store the comment
						print COMMENTS "Comment ID:\t" . $comid . "\n";
						print COMMENTS "Comment URL:\t" . $comments->{ $doc }->{ $comid }->{ 'link' } . "\n";
						print COMMENTS "Written by:\t" . $comments->{ $doc }->{ $comid }->{ 'username' } . " (User ID: " . $comments->{ $doc }->{ $comid }->{ 'user_id' } . ")\n";
						print COMMENTS "Written on:\t" . scalar localtime( $comments->{ $doc }->{ $comid }->{ 'date' } ) . "\n";
						print COMMENTS "=" x 72 . "\n";
						print COMMENTS $comments->{ $doc }->{ $comid }->{ 'content' } . "\n";
						print COMMENTS "=" x 72 . "\n\n";

					}

					## Close comments file
					close( COMMENTS );

				}

			}

			## Download file (if commentsonly is not set)
			unless( defined( $config->{ 'commentsonly' } ) )
			{

				## Download file from Ipernity
				$dl->download( $url, $file );

				## Change date of downloaded file to creation date
				if( defined( $documents->{ $doc }->{ 'cdate' } ) and -f $file )
				{
			
					## Log a information message
					$log->info( 'Changing creation date of file to: ' . $documents->{ $doc }->{ 'cdate' } );

					## Convert date to unix timestamp
					my $cdate = UnixDate( $documents->{ $doc }->{ 'cdate' }, '%s' );

					## Update timestamp of downloaded file
					utime( $cdate, $cdate, $file );

				}

			}

		}

	}
	# }}}

	## ...or just creating a download list {{{
	elsif( defined( $config->{ 'list' } ) )
	{

		## Generate a full absolute path to the DL list
		my $file = $iper->isValidFile( $config->{ 'dir' } || OUTDIR, 'IperBackup.list', undef );

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
		'media|m=s'	=> \$config->{ 'media' },
		'tags|t=s'	=> \$config->{ 'tags' },
		'comments|n'	=> \$config->{ 'comment' },
		'commentsonly'	=> \$config->{ 'commentsonly' },
		'startdate|s=s'	=> \$config->{ 'startdate' },
		'enddate|e=s'	=> \$config->{ 'enddate' },
		'permission|p'	=> \$config->{ 'permission' },

	);
	
	## Download mode is implied for commentsonly mode
	$config->{ 'download' } = 1 if( defined( $config->{ 'commentsonly' } ) );

	## Check for conflicts
	showHelp() if( $config->{ 'help' } );
	showHelp() unless( defined( $config->{ 'list' } ) or defined( $config->{ 'download' } ) );
	showHelp() if( defined( $config->{ 'list' } ) and defined( $config->{ 'download' } ) );
	showHelp() if( defined( $config->{ 'list' } ) and defined( $config->{ 'comment' } ) );

	
	## Check media types
	if( defined( $config->{ 'media' } ) )
	{

		## Clean up whitespaces
		$config->{ 'media' } =~ s/\s//g;

		## Get array of types
		my @list = split( /,/, $config->{ 'media' } );
		showHelp() if( scalar( grep( !/\b(photo|audio|video|other)\b/, @list ) ) );

	}

	## Check tags
	if( defined( $config->{ 'tags' } ) )
	{

		## Clean up whitespaces
		$config->{ 'tags' } =~ s/,\s/,/g;

		## Count number of provided tags
		my @list = split( /,/, $config->{ 'tags' } );
		showHelp() if( $#list > 19 );

	}

}
# }}}

### Use IperBackup::Update to check for latest updates // checkUpdate() {{{
sub checkUpdate
{

	## Create an IperBackup::Update object
	my $update = IperBackup::Update->new();

	## Check if a new version is available
	$update->checkVersion( VERSION );

}
# }}}

### Provide some help messages if requested // showHelp() {{{
sub showHelp
{

	## Print message
	print "Usage: $0 [OPTIONS]\n";
	print "\n\t-c, --config\t\tSpecify absolute path to config file (Default: /etc/IperBackup.conf)";
	print "\n\t--comentsonly\t\tDownload comments only";
	print "\n\t-d, --download\t\tTell IperBackup to download all files in your account";
	print "\n\t-e, --enddate\t\tSpecify the maximum date of documents you are searching";
	print "\n\t-h, --help\t\tDisplay this help message.";
	print "\n\t-l, --list\t\tTell IperBackup to create a list of files in you account";
	print "\n\t-m, --media\t\tSpecify which media type to fetch. Possiblities are: audio, photo, other, video (Default: all)";
	print "\n\t-n, --comments\t\tFetch comments of the document if any (only works in download mode)";
	print "\n\t-o, --outdir\t\tSpecify absolute path to the output directory (Default: /var/tmp)";
	print "\n\t-p, --permission\t\tTell IperBackup to add the permission type to the filename";
	print "\n\t-s, --startdate\t\tSpecify the minimum date of documents you are searching";
	print "\n\t-t, --tags\t\tForce IperBackup to fetch only files with a specific tag (max. 20 tags)";
	print "\n\n\n";

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
