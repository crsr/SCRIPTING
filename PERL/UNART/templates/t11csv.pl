#!/usr/bin/perl
#
#
#	T11CSV template script (IMPORT V2)
# 	DO:
# 	1. Match template
# 	2. Parse file
# 	3. Import mongoDB
# 	[UNART - INCRYS]
#
#
#   environment settings: 
#		env = 0 send print output to logfile (for production)
#		env = 1 send print output to console (for development)
#
my $start_run = time();
my $env = 0;
my $template = "T11CSV";
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

sub clean_string($); 


binmode STDOUT, ":utf8";

my $log_data = strftime("%Y-%m-%d %H-%M-%S", localtime);
my $log_file_data = strftime("%Y-%m-%d", localtime);

our $database_name;
our $database_host;
our $database_uname;
our $database_pwd;
our $mongo_database_host;
our $mongo_database;
our $mongo_collection;
our $logs_path;

do '/var/perl-unart/PERL/UNART/templates/config.cfg';

my $pg_connection = DBI->connect("dbi:Pg:dbname=$database_name;host=$database_host","$database_uname","$database_pwd");
my $mango = Mango->new($mongo_database_host); # DB connection

#
# Log file and structure
#
my ( $logfile, $directories ) = fileparse $logs_path;
if ( !$logfile ) {
    $logfile = "parser_".$template."_".$log_file_data.".log";
    $logs_path = File::Spec->catfile( $logs_path, $logfile );
	if($env == 0){
		open(STDOUT,'>>',$logs_path) or die "Nu se poate creea fisierul pentru log!"; #open file for writing (append)
	}
}

if ( !-d $directories ) {
    make_path $directories or die "Nu se poate creea structura";
}



my $file = $ARGV[0];
my @extensions = qw(.XLS .XLSX .CSV); #set allowed extensions for filter
print STDOUT "START\n";
print STDOUT "----------------- ".$log_data." -----------------\n";

			if (-f $file) { # check if is file (-f)
				my($filename, $directories, $extension) = fileparse($file, @extensions);
						
					my $channels = $pg_connection->selectall_arrayref("SELECT channel_id,channel_title FROM public.channels",{ Slice => {} });
					my $months = $pg_connection->selectall_arrayref("SELECT month_no,month_str FROM public.months",{ Slice => {} });
					my $years = $pg_connection->selectall_arrayref("SELECT year_id,year_str FROM public.years",{ Slice => {} });

					my @channel_founded;
					my @month_founded;
					my @year_founded;
					my @year_founded_in_condition_for_data;

					foreach my $cnl ( @$channels ) { my $channel = uc($cnl->{channel_title}); $channel =~ s/[^A-Za-z0-9|\-\.]/_/g; if (index($filename, $channel) != -1) { @channel_founded = $cnl->{channel_id}; } }
								
					foreach my $mn ( @$months ) { my $month = uc($mn->{month_str}); $month =~ s/[^A-Za-z0-9|\-\.]/_/g; if (index($filename, $month) != -1) { @month_founded = $mn->{month_no}; } }			
					
					foreach my $yr ( @$years ) { my $year = uc($yr->{year_str}); $year =~ s/[^A-Za-z0-9|\-\.]/_/g; if (index($filename, $year) != -1) { @year_founded = $yr->{year_id}; @year_founded_in_condition_for_data = $yr->{year_str}; } }
				

					# if filename doesn't contain month or year, search in path.
					if(scalar(@month_founded) == 0 && scalar(@year_founded) == 0) { 

						my $file_path_for_search = abs_path($file);
						my @month_founded_in_condition;
						my @year_founded_in_condition;
						my @year_founded_in_condition_for_data;

						foreach my $mn ( @$months ) { my $month = uc($mn->{month_str}); $month =~ s/[^A-Za-z0-9|\-\.]/_/g; if (index($file_path_for_search, $month) != -1) { @month_founded_in_condition = $mn->{month_no}; } }
						push @month_founded,@month_founded_in_condition;

						foreach my $yr ( @$years ) { my $year = uc($yr->{year_str}); $year =~ s/[^A-Za-z0-9|\-\.]/_/g; if (index($file_path_for_search, $year) != -1) { @year_founded_in_condition = $yr->{year_id}; @year_founded_in_condition_for_data = $yr->{year_str}; } }
						push @year_founded,@year_founded_in_condition;
								
					}
					
					# if filename doesn't contain channel, search in path.
					if(scalar(@channel_founded) == 0) { 
						my $file_path_for_search = abs_path($file);
						my @channel_founded_in_condition;
						foreach my $cnl ( @$channels ) { my $channel = uc($cnl->{channel_title}); $channel =~ s/[^A-Za-z0-9|\-\.]/_/g; if (index($file_path_for_search, $channel) != -1) { @channel_founded_in_condition = $cnl->{channel_id}; } }
						
						
						push @channel_founded,@channel_founded_in_condition;	
					}

					if(scalar(@channel_founded) == 0 && scalar(@month_founded) == 0 && scalar(@year_founded) == 0){
							my $old_path = abs_path($file);
							my $new_path = abs_path($file);
							$new_path =~ s/IMPORT/RESIDUUM/; #set new path (string replace)
							my($filename_to_move, $directories_to_move) = fileparse($new_path); # get directories tree for new tree creation
							make_path($directories_to_move);
							move($old_path, $new_path);
							unlink($old_path);
					}

					my $month_founded = @month_founded;
					my $year_founded = @year_founded;
					my $channel_founded = @channel_founded;
					my $year_founded_in_condition_for_data = @year_founded_in_condition_for_data;

					if( ! defined $month_founded) { $month_founded[0] = "null"; }
					if( ! defined $year_founded) { $year_founded[0] = "null"; }
					if( ! defined $channel_founded) { $channel_founded[0] = "null"; }
						if (-e $file) {
						open(FILE,$file);
						if(tell(FILE) == -1 ){ 
							my $old_path = abs_path($file);
							my $new_path = abs_path($file);
							$new_path =~ s/IMPORT/RESIDUUM/; #set new path (string replace)
							my($filename_to_move, $directories_to_move) = fileparse($new_path); # get directories tree for new tree creation
							make_path($directories_to_move);
							move($old_path, $new_path);
							unlink($old_path);
							next; 
						} #remove corrupted files
						my $csv = Text::CSV->new();
					    open (CSV, "<", $file);
					    my $row = 0;
					    while (<CSV>) {
					        $row += 1; 
					        	if($row > 8){ 	    
						            if ($csv->parse($_)) {
						                my @columns = $csv->fields();
						                my @splitted = split(';',$columns[0]);

						                my $total = (($splitted[2] * 60) + $splitted[3]);

						                my $correct_data = $year_founded_in_condition_for_data[0] . '-' . $month_founded[0] . '-' . $splitted[0];

						                my $insert = $mango->db($mongo_database)->collection($mongo_collection)->insert({ "DATA_DIFUZARE" => $correct_data, "EMISIUNE" => $channel_founded[0], "MINUTE" => $splitted[3], "SECUNDE" => $splitted[4], "OPERA" => $splitted[5], "ARTIST" => $splitted[7], "NR_DIFUZARI" => "-", "LUNA" => $month_founded[0], "AN" => $year_founded[0], "POST" => $channel_founded[0], "TEMPLATE" => $template, "STATUS" => "0", "TOTAL" => $total});
						            } else {
						                my $err = $csv->error_input;
						                print STDOUT "Failed to parse line: $err\n";
						            }
					       		}
					        
					        
						}
						close CSV;
						
						chomp($file);
								my $old_path = abs_path($file);
								my $new_path = abs_path($template.'_'.$file);
								$new_path =~ s/IMPORT/IMPORTED/; #set new path (string replace)
								my($filename_to_move, $directories_to_move) = fileparse($new_path); # get directories tree for new tree creation
								make_path($directories_to_move);
								move($old_path, $new_path);
								unlink($old_path);
								print STDOUT "----------------- ".$log_data." -----------------\n";
								print STDOUT "Fisier importat si mutat -> $new_path\n";
								print "==========================================================================================================================\n";
						}				
			}		
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