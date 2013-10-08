#
#	
#   Search empty folders and delete them. 
#   [UNART - INCRYS]
#	
#   environment settings: 
#		env = 0 send print output to logfile (for production)
#		env = 1 send print output to console (for development)
#
my $start_run = time();
my $env = 0;
use strict;
use feature qw(say);
use File::Basename;
use File::Find qw/ find /;
use File::Spec;
use File::Path qw( make_path );
use POSIX qw/strftime/;
use IO::Handle;
	my $log_data = strftime("%Y-%m-%d %H-%M-%S", localtime);
	my $log_file_data = strftime("%Y-%m-%d", localtime);
	#
	# Log file and structure
	#
	my $log_printing;
	my $full_path = "/var/www/html/LOGS/";
	my ( $logfile, $directories ) = fileparse $full_path;
		if ( !$logfile ) {
			$logfile = "delete_empty_folders_".$log_file_data.".log";
			$full_path = File::Spec->catfile( $full_path, $logfile );
			if($env == 0){
			open(STDOUT,'>>',$full_path) or die "Nu se poate creea fisierul pentru log!"; #open file for writing (append)
			} 
		}

		if ( !-d $directories ) {
			make_path $directories or die "Nu se poate creea structura";
		}
		my $root = '/var/www/html/IMPORT/';
		print STDOUT "START\n";
		print STDOUT "----------------- ".$log_data." -----------------\n";
		find \&foldering => $root;
		sub foldering {	
			if ($_ =~ /^\.+.*/) { next; } # remove . and .. from folders listing
			if(-d $_){
				if (empty_folder($_)) {
					rmdir($_);
					print STDOUT "Se sterge folderul: $_\n";
				}
				
			} 
		}
		sub empty_folder {
			my $dirname = shift;
			opendir(my $dh, $dirname) or die "Not a directory";
			return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
		}
		my $end_run = time();
		my $run_time = $end_run - $start_run;
		print STDOUT "Timp executie $run_time secunde\n";
		print STDOUT "STOP\n";
#
#	delete_empty_folders.pl it's the last script from chain
#
