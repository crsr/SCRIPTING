#
#  This script will works only if the files and folders are:
#  - renamed with folders/files script for renaming and cleaning
#  - change the paths for your system
#  last save: 16:50 15.04.2013 [UNART - INCRYS]
#

my $start_run = time();
use strict;
use feature qw(say);
use feature qw(switch);
use File::Basename;
use File::Copy;
use File::Find qw/ find /;
use Cwd 'abs_path';
use File::Path qw(make_path remove_tree);
use File::Spec;
use autodie;

	my $root = 'D:\\WORK\\perl\\xls';
	my $c;
	my @extensions = qw(.XLS .XLSX .CSV);
	find \&foldering => $root; #call foldering :) function
	sub foldering {
		if ($_ =~ /^\.+.*/) { next; } # remove . and .. from files listing
		if(-f $_) {
			chomp;
			my $old_path = abs_path($_);
			my $new_path = abs_path($_);
			$new_path =~ s/xls/xlsout/; #set new path (string replace)
			my($filename_to_move, $directories_to_move) = fileparse($new_path); # get directories tree for new tree creation
			my($filename, $directories, $extension) = fileparse($_, @extensions); # get extensions for all files	 
			#print "Mut $old_path in $new_path\n";
			
			given ($extension){
				when('.XLS') { }
				when('.XLSX') { }
				when('.CSV') { }
				default {
					make_path($directories_to_move); # create file tree structure
					move($old_path, $new_path); # move file (delete from old tree structure
				}						
			}
		}
	}
my $end_run = time();
my $run_time = $end_run - $start_run;
print "Timp executie $run_time\n";
	
