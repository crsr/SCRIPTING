#
#
#	T57 template script
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
#binmode STDOUT, ":utf8";

my $log_data = strftime("%Y-%m-%d %H-%M-%S", localtime);
my $log_file_data = strftime("%Y-%m-%d", localtime);
my $mango = Mango->new('mongodb://127.0.0.1:27017'); # DB connection
#
# Lists for search patterns
#
my @months = ("ianuarie", "februarie", "martie", "aprilie", "mai", "iunie", "iulie", "august", "septembrie", "octombrie", "noiembrie", "decembrie"); 
my @years = ("2011", "2012", "2013");


	
	
	
	
	
	
	
	
	
    

#
# Log file and structure
#
my $log_printing;

my $full_path = "/var/www/html/LOGS/";
my ( $logfile, $directories ) = fileparse $full_path;
if ( !$logfile ) {
    $logfile = "parser_T57_".$log_file_data.".log";
    $full_path = File::Spec->catfile( $full_path, $logfile );
	if($env == 0){
		open(STDOUT,'>>',$full_path) or die "Nu se poate creea fisierul pentru log!"; #open file for writing (append)
	}
}

if ( !-d $directories ) {
    make_path $directories or die "Nu se poate creea structura";
}

my $database_name = "unart";
my $database_host = "127.0.0.1";
my $database_uname = "unart";
my $database_pwd = "unart";
my $pg_connection = DBI->connect("dbi:Pg:dbname=$database_name;host=$database_host","$database_uname","$database_pwd");

my $file = $ARGV[0];
#my $file = "/var/www/html/IMPORT/ALEXANDRA_TOUR_SRL_HUNEDOARA_TV/TRIM_1/T57_PLAYLIST_IANUARIE_2012.XLS";
my @extensions = qw(.XLS .XLSX .CSV); #set allowed extensions for filter
print STDOUT "START\n";
print STDOUT "----------------- ".$log_data." -----------------\n";

			if (-f $file) { # check if is file (-f)
				my($filename, $directories, $extension) = fileparse($file, @extensions);
			
					# search month in filename
					my $months_array = join("|",@months); 
					my $formatted_months_array =  uc($months_array);
					my @month_founded = ($filename =~ /($formatted_months_array)/); 
					
					# search year in filename
					my $years_array = join("|",@years); 
					my $formatted_years_array =  $years_array;
					my @year_founded = ($filename =~ /($formatted_years_array)/); 
					
					my $channels = $pg_connection->selectall_arrayref("SELECT channel_id,channel_title FROM public.channels",{ Slice => {} });
					my @channel_founded;
					foreach my $cnl ( @$channels ) { my $channel = uc($cnl->{channel_title}); $channel =~ s/[^A-Za-z0-9|\-\.]/_/g; if (index($filename, $channel) != -1) { @channel_founded = $cnl->{channel_id}; } }
					
					

					# if filename doesn't contain month, search in path.
					if(scalar(@month_founded) == 0) { 
						my $file_path_for_search = abs_path($file);
						my $months_array = join("|",@months); 
						my $formatted_months_array =  uc($months_array);
						my @month_founded_in_condition = ($file_path_for_search =~ /($formatted_months_array)/); 
						push @month_founded,@month_founded_in_condition;
					}
					
					# if filename doesn't contain year, search in path.
					if(scalar(@year_founded) == 0) { 
						my $file_path_for_search = abs_path($file);
						my $years_array = join("|",@years); 
						my $formatted_years_array =  uc($years_array);
						my @year_founded_in_condition = ($file_path_for_search =~ /($formatted_years_array)/); 
						push @year_founded,@year_founded_in_condition;	
					}
					
					# if filename doesn't contain month or year, search in path.
					if(scalar(@month_founded) == 0 && scalar(@year_founded) == 0) { 
						my $file_path_for_search = abs_path($file);
						
						my $years_array = join("|",@years); 
						my $formatted_years_array =  uc($years_array);
						my @year_founded_in_condition = ($file_path_for_search =~ /($formatted_years_array)/); 
						push @year_founded,@year_founded_in_condition;

						my $months_array = join("|",@months); 
						my $formatted_months_array =  uc($months_array);
						my @month_founded_in_condition = ($file_path_for_search =~ /($formatted_months_array)/); 
						push @month_founded,@month_founded_in_condition;		
					}
					
					# if filename doesn't contain channel, search in path.
					if(scalar(@channel_founded) == 0) { 
						my $file_path_for_search = abs_path($file);
						my @channel_founded_in_condition;
						foreach my $cnl ( @$channels ) { my $channel = uc($cnl->{channel_title}); $channel =~ s/[^A-Za-z0-9|\-\.]/_/g; if (index($filename, $channel) != -1) { @channel_founded_in_condition = $cnl->{channel_id}; } }
						
						
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
						my $parser   = Spreadsheet::ParseExcel->new(); # init excel module
						my $workbook = $parser->parse(realpath($file)); # parse file
								if ( !defined $workbook ) {
									next; #if the file isn't accesible or protected or smthelse ..parse the next file;
								}
								my($data_sheet, $sheet_name); # set variables for parsing
									foreach my $data_sheet (@{$workbook->{Worksheet}}) {
									
										my $data_sheet_name = $data_sheet->{Name};
										print STDOUT "Fisier: [$file] | Foaie: [$data_sheet_name]\n";
										$sheet_name = undiacritic($data_sheet->{Name}); 

												#my $stmt = $pg_connection->prepare("INSERT INTO first_buffer2 (data_difuzare,emisiune,minute,secunde,opera,artist,template,luna,an,post,nr_difuzari) VALUES(?,?,?,?,?,?,?,?,?,?,?)");
												for my $row (0 .. $data_sheet->{MaxRow}) {
													if($row != 0 and $row != 1){
														my $c1 = $data_sheet->get_cell($row, 1); next unless $c1; #data
														#my $c2 = $data_sheet->get_cell($row, 1);#emisiune
														my $c3 = $data_sheet->get_cell($row, 6); next unless $c3; #opera
														my $c4 = $data_sheet->get_cell($row, 5); next unless $c4; #artist
														my $c5 = $data_sheet->get_cell($row, 3); next unless $c5; #minute
														my $c6 = $data_sheet->get_cell($row, 4); next unless $c6; #secunde
														#my $c7 = $data_sheet->get_cell($row, 1);#nr difuzari
														my $c3string = $c3->value();
														$c3string =~ s/.mpg//;
														$c3string =~ s/. mpg//;
														$c3string =~ s/, mpg//;
														$c3string =~ s/.rnpg//;
														$c3string =~ s/. rnpg//;
														$c3string =~ s/, rnpg//;
														$c3string =~ s/.avi//;
														$c3string =~ s/.//;
														$c3string =~ s/,//;
														$c3string =~ s/.rn2p//;
														$c3string =~ s/.m2p//;
														$c3string =~ s/"//;
														$c3string =~ s/.rr//;
														$c3string =~ s/~/'/;
														if($c1->value() eq "" and $c3->value() eq "" and $c4->value() eq "" and $c5->value() eq "" and $c6->value() eq "") { next; } #remove empty data
														
														#$stmt->execute( clean_string($c1->value()), "null", clean_string($c5->value()), clean_string($c6->value()), clean_string($c3string), clean_string($c4->value()), "T57", $month_founded[0], $year_founded[0], $channel_founded[0], "-");		
														my $insert = $mango->db('unart_parsing')->collection('parsed')->insert({ "DATA_DIFUZARE" => clean_string($c1->value()), "EMISIUNE" => "null", "MINUTE" => clean_string($c5->value()), "SECUNDE" => clean_string($c6->value()), "OPERA" => clean_string($c3string), "ARTIST" => clean_string($c4->value()), "NR_DIFUZARI" => "-", "LUNA" => $month_founded[0], "AN" => $year_founded[0], "POST" => $channel_founded[0], "TEMPLATE" => "T57"});
													}
												}									
									} 
									
									chomp($file);
									my $old_path = abs_path($file);
									my $new_path = abs_path('T57_'.$file);
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