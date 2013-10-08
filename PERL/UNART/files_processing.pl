#
#  
# Search all files and rename them. Uppercase and change invalid chars with _ (underscore)
# [UNART - INCRYS]
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
		$logfile = "files_renaming_".$log_file_data.".log";
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
		find \&foldering => $root;
		sub foldering {
			if ($_ =~ /^\.+.*/) { next; } # remove . and .. from files listing
			if(-f $_) {
				my $filename = $_;
				my $fname = fname($filename);
				my $ext = ext($filename);
				$fname =~ s/[^a-zA-Z0-9]/_/g; #cleaner regex
				my $filename_renamed = uc($fname.".".$ext);
				$filename_renamed =~ s/__/_/; #replace double underscore with one
				$filename_renamed =~ s/___/_/; #
				$filename_renamed =~ s/____/_/; #
				$filename_renamed =~ s/_____/_/; #
				print STDOUT "Redenumire \"$_\" in \"$filename_renamed\"\n"; #print for log
				rename $_,$filename_renamed; #rename file;
			}
		}
	# extract only filename from filename, without extension
	sub fname {
 		my ($file) = @_;
    		return substr($file, 0, rindex($file, '.'));
	}
	# extract extension from filename
	sub ext {
    		my ($file) = @_;
    		return substr($file, rindex($file, '.') + 1);
	}
	my $end_run = time();
	my $run_time = $end_run - $start_run;
	print STDOUT "Timp executie $run_time secunde\n";
	print STDOUT "STOP\n";
#
#	After script is finished, call cleaning script
#
	#system("perl D:\\WORK\\REPOS\\PERL\\UNART\\cleaning.pl");
    #system("perl /var/perl-scripts/PERL/UNART/filter_process.pl");		
	
