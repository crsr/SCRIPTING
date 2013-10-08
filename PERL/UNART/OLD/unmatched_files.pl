#
#
#	Templates manager script
# 	DO:
# 	1. Search in file name and path for month/year/channel
# 	2. Set array with results (for sending to mongodb)
# 	3. Parsing each file and send data to mongodb
# 	[UNART - INCRYS]
#
#
#   environment settings: 
#		env = 0 send print output to logfile (for production)
#		env = 1 send print output to console (for development)
#

my $start_run = time();
my $env = 0;
use strict;
use warnings;
use feature qw(say);
use Cwd 'realpath';
use Cwd 'abs_path';
use FileHandle;
use File::Basename;
use File::Find::Rule;
use File::Path qw( make_path );
use File::Spec;
use File::Copy;
use IO::Handle;
use Text::Undiacritic qw(undiacritic);
use POSIX qw/strftime/;
use Mango;
use DBI;
use Spreadsheet::ParseExcel;
use Data::Dumper;
use JSON;
sub clean_string($);
use MongoDB::Connection;
use MongoDB::Database;
use MongoDB::Cursor;
binmode STDOUT, ":utf8";
my $log_data = strftime("%Y-%m-%d %H-%M-%S", localtime);
my $log_file_data = strftime("%Y-%m-%d", localtime);
	#
	# Log file and structure
	#
	my $log_printing;
	#my $full_path = "D:\\WORK\\perl\\logs";
	my $full_path = "/var/www/html/LOGS/";
	my ( $logfile, $directories ) = fileparse $full_path;
	if ( !$logfile ) {
		$logfile = "unmatched_files_".$log_file_data.".log";
		$full_path = File::Spec->catfile( $full_path, $logfile );
		if($env == 0){
			open(STDOUT,'>>',$full_path) or die "Nu se poate creea fisierul pentru log!"; #open file for writing (append)
		}
	}

	if ( !-d $directories ) {
		make_path $directories or die "Nu se poate creea structura";
	}
	my $mongodb_connection = MongoDB::Connection->new(host=>"mongodb://127.0.0.1:27017");
	my $database = $mongodb_connection->get_database('unart_parsing');
	my $collection = $database->get_collection("matched_files")->find();
	#postgres connection and queries
	#my $pg_connection;
	#my $data_base_name = "unart";
	#my $data_base_host = "127.0.0.1";
	#my $data_base_uname = "postgres";
	#my $data_base_pwd = "postgres";
	#$pg_connection = DBI->connect("dbi:Pg:dbname=$data_base_name;host=$data_base_host", "$data_base_uname", "$data_base_pwd");
	#my $query_templates = $pg_connection->prepare('SELECT "template.meta_data" as tmd FROM public.templates WHERE "template.status" = true ');
	#$query_templates->execute();
	#my($tmd);
	#$query_templates->bind_columns(\($tmd));
	
	my $root_folder="/var/www/html/IMPORT/";
	my @folders = File::Find::Rule->directory->in($root_folder); # get entire folders tree
	my @extensions = qw(.XLS .XLSX .CSV); #set allowed extensions for filter
	print STDOUT "START\n";
	print STDOUT "----------------- ".$log_data." -----------------\n";
	foreach my $folder (@folders){
	  opendir(DIR, $folder) || die ("Folderul {".$folder."} nu poate fi deschis!");
		my @files = grep !/^\.\.?$/,readdir(DIR); # remove . and .. from files listing
		closedir(DIR);
		chdir($folder);
			foreach my $file (@files){
				if (-f $file) { # check if is file (-f)
					my($filename, $directories, $extension) = fileparse($file, @extensions);
					
						
						if (-e $file) {
						print $file,"\n";
						my $matched_file = $database->get_collection("matched_files")->find_one({ FILE => $file });	
						if($file ne $matched_file){
							chomp($file);
							my $old_path = abs_path($file);
							my $new_path = abs_path($file);
							$new_path =~ s/IMPORT/UNMATCHED/; #set new path (string replace)
							my($filename_to_move, $directories_to_move) = fileparse($new_path); # get directories tree for new tree creation
							make_path($directories_to_move);
							move($old_path, $new_path);
							unlink($old_path);
						}
						print Dumper($matched_file);
						#my $collection = $database->get_collection("matched_files")->find({ FILE => $file });
						#while (my $doc = $collection->next){ 
						#	print Dumper($doc);
						#}
=begin
						if($unmatched->{FILE} eq ""){
							chomp($file);
							my $old_path = abs_path($file);
							my $new_path = abs_path($file);
							$new_path =~ s/IMPORT/UNMATCHED/; #set new path (string replace)
							my($filename_to_move, $directories_to_move) = fileparse($new_path); # get directories tree for new tree creation
							make_path($directories_to_move);
							move($old_path, $new_path);
							unlink($old_path);
						}		
=end
=cut							
						}	
					
			}		
		}
}
# trim string and diacritics removal subroutine
sub clean_string($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return undiacritic($string);
}
my $end_run = time();
my $run_time = $end_run - $start_run;
print STDOUT "Timp executie $run_time secunde\n";
print STDOUT "STOP\n";
