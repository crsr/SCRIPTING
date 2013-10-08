#
#  
# 	Search all folders and rename them. Uppercase and change invalid chars with _ (underscore)
# 	[UNART - INCRYS]
#	
#   environment settings: 
#		env = 0 send print output to logfile (for production)
#		env = 1 send print output to console (for development)
#
my $start_run = time();
my $env = 0;
use strict;
use Cwd 'abs_path';
use feature qw(say);
use File::Basename;
use File::Find qw(find finddepth);
use File::Spec;
use File::Path qw( make_path );
use POSIX qw/strftime/;
use IO::Handle;
use File::Copy;
	my $log_data = strftime("%Y-%m-%d %H-%M-%S", localtime);
	my $log_file_data = strftime("%Y-%m-%d", localtime);
	#
	# Log file and structure
	#
	my $full_path = "/var/www/html/LOGS/";
	my ( $logfile, $directories ) = fileparse $full_path;
	if ( !$logfile ) {
		$logfile = "folders_renaming_".$log_file_data.".log";
		
		$full_path = File::Spec->catfile( $full_path, $logfile );

		if($env == 0){
			open(STDOUT,'>>',$full_path) or die "Nu se poate creea fisierul pentru log!"; #open file for writing (append)
		}
	}

	if ( !-d $directories ) {
		make_path $directories or die "Nu se poate creea structura";
	}
	print STDOUT "START\n";
	print STDOUT "----------------- ".$log_data." -----------------\n";
	my $root = '/var/www/html/IMPORT/';
	
	finddepth(sub {
		return if($_ eq "." || $_ eq "..");
		if(-f $_) {next;}
		my $new_folder_name = uc($File::Find::name);
		$new_folder_name =~ s/VAR/var/;
		$new_folder_name =~ s/WWW/www/;
		$new_folder_name =~ s/HTML/html/;	
		$new_folder_name =~ s/[^a-zA-Z0-9\/]/_/g;	
		$new_folder_name =~ s/__/_/;
		$new_folder_name =~ s/___/_/;
		$new_folder_name =~ s/____/_/;
		$new_folder_name =~ s/_____/_/;
		$new_folder_name =~ s/______/_/;	
		rename($File::Find::name,$new_folder_name);
		print STDOUT "Nume nou: $new_folder_name","\n";	
	},$root);	
	
	my $end_run = time();
	my $run_time = $end_run - $start_run;
	print STDOUT "Timp executie $run_time secunde\n";
	print STDOUT "STOP\n";
#
#	After script is finished, call files renaming script
#
	#system("perl D:\\WORK\\REPOS\\PERL\\UNART\\files_renaming.pl");	
	#system("perl /var/perl-scripts/PERL/UNART/files_processing.pl");
