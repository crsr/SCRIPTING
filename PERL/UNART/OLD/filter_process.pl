#
#
#	Move files and folders that can't be imported (accepted only xls/xlsx/csv)
#
#   This script will works only if the files and folders are:
#   - renamed with folders/files script for renaming and cleaning
#   - change the paths for your system
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
use feature qw(switch);
use File::Basename;
use File::Copy;
use File::Find qw/ find /;
use Cwd 'abs_path';
use File::Path qw(make_path remove_tree);
use File::Spec;
use POSIX qw/strftime/;
use IO::Handle;
use autodie;
	my $log_data = strftime("%Y-%m-%d %H-%M-%S", localtime);
	my $log_file_data = strftime("%Y-%m-%d", localtime);
	#
	# Log file and structure
	#
	my $log_printing;
	my $full_path = "/var/www/html/LOGS/";
	my ( $logfile, $directories ) = fileparse $full_path;
	if ( !$logfile ) {
		$logfile = "cleaning_".$log_file_data.".log";
		$full_path = File::Spec->catfile( $full_path, $logfile );
		if($env == 0){
			open(STDOUT,'>>',$full_path) or die "Nu se poate creea fisierul pentru log!"; #open file for writing (append)
		}
	}

	if ( !-d $directories ) {
		make_path $directories or die "Nu se poate creea structura";
	}
	my $root = '/var/www/html/IMPORT/';
	my @extensions = qw(.XLS .XLSX .CSV);
	print STDOUT "START\n";
	print STDOUT "----------------- ".$log_data." -----------------\n";
	find \&foldering => $root; #call foldering :) function	
	sub foldering {
		if ($_ =~ /^\.+.*/) { next; } # remove . and .. from files listing
		if(-f $_) {
			chomp;
			my $old_path = abs_path($_);
			my $new_path = abs_path($_);
			$new_path =~ s/IMPORT/REMOVED/; #set new path (string replace)
			my($filename_to_move, $directories_to_move) = fileparse($new_path); # get directories tree for new tree creation
			my($filename, $directories, $extension) = fileparse($_, @extensions); # get extensions for all files	 
		
			given ($extension){
				when('.XLS') { }
				when('.XLSX') { }
				when('.CSV') { }
				default {
					make_path($directories_to_move); # create file tree structure
					move($old_path, $new_path); # move file (delete from old tree structure
					print STDOUT "Se muta '$filename' in: $new_path\n";
				}						
			}
		}
	}
	my $end_run = time();
	my $run_time = $end_run - $start_run;
	print STDOUT "Timp executie $run_time secunde\n";
	print STDOUT "STOP\n";
#
#	After script is finished, call cleaning script
#
	#system("perl D:\\WORK\\REPOS\\PERL\\UNART\\delete_empty_folders.pl");
	system("perl /var/perl-scripts/PERL/UNART/empty_folders_processing.pl");	
