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
my $env = 1;
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
		$logfile = "manager_".$log_file_data.".log";
		$full_path = File::Spec->catfile( $full_path, $logfile );
		if($env == 0){
			open(STDOUT,'>>',$full_path) or die "Nu se poate creea fisierul pentru log!"; #open file for writing (append)
		}
	}

	if ( !-d $directories ) {
		make_path $directories or die "Nu se poate creea structura";
	}
	my $mango = Mango->new('mongodb://127.0.0.1:27017'); # DB connection
	
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
					chomp($extension); # remove formatting tags
					if($extension eq ".XLS"){
						if (-e $file) {
						open(FILE,$file);
						if(tell(FILE) == -1 ){ 
							my $old_path = abs_path($file);
							my $new_path = abs_path($file);
							$new_path =~ s/IMPORT/RESIDUUM/; #set new path (string replace)
							#$new_path =~ s/xls/residuum/; #set new path (string replace)
							my($filename_to_move, $directories_to_move) = fileparse($new_path); # get directories tree for new tree creation
							make_path($directories_to_move);
							move($old_path, $new_path);
							unlink($old_path);
							next; 
						} #remove corrupted files
						my $parser   = Spreadsheet::ParseExcel->new(); # init excel module
						my $workbook = $parser->parse(realpath($file)); # parse file
						
								if ( !defined $workbook ) {
									#die $parser->error(), ".\n";
									next; #if the file isn't accesible or protected or smthelse ..parse the next file/sheet;
								}
						for my $worksheet ( $workbook->worksheets() ) {
						print $file,"\n";
							#TEMPLATE 1 (ok)							
							my $template_1_cell_1 = $worksheet->get_cell(0, 1);
							my $template_1_cell_2 = $worksheet->get_cell(0, 2);
							my $template_1_cell_3 = $worksheet->get_cell(0, 3);
							my $template_1_cell_4 = $worksheet->get_cell(0, 4);
							
							if($template_1_cell_1 and $template_1_cell_2 and $template_1_cell_3 and $template_1_cell_4){
								my $value1 = clean_string($template_1_cell_1->Value);
								my $value2 = clean_string($template_1_cell_2->Value);
								my $value3 = clean_string($template_1_cell_3->Value);
								my $value4 = clean_string($template_1_cell_4->Value);
								if(($value1 eq "Data difuzarii") and ($value2 eq "Emisiune") and ($value3 eq "Min.") and ($value4 eq "Sec.")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T1"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t1.pl $file");	
								}
							}
							
							#TEMPLATE 2 
							my $template_2_cell_1 = $worksheet->get_cell(9, 1);
							my $template_2_cell_2 = $worksheet->get_cell(9, 2);
							my $template_2_cell_3 = $worksheet->get_cell(9, 3);
							my $template_2_cell_4 = $worksheet->get_cell(9, 4);
							
							if($template_2_cell_1 and $template_2_cell_2 and $template_2_cell_3 and $template_2_cell_4){
								my $value1 = clean_string($template_2_cell_1->Value);
								my $value2 = clean_string($template_2_cell_2->Value);
								my $value3 = clean_string($template_2_cell_3->Value);
								my $value4 = clean_string($template_2_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Denumire opera muzicala") and ($value4 eq "Interpret")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T2"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t2.pl $file");	
								}
							}
							
							#TEMPLATE 3 (ok)
							my $template_3_cell_1 = $worksheet->get_cell(0, 0);
							my $template_3_cell_2 = $worksheet->get_cell(0, 1);
							my $template_3_cell_3 = $worksheet->get_cell(0, 2);
							my $template_3_cell_4 = $worksheet->get_cell(0, 4);
							
							if($template_3_cell_1 and $template_3_cell_2 and $template_3_cell_3 and $template_3_cell_4){
								my $value1 = clean_string($template_3_cell_1->Value);
								my $value2 = clean_string($template_3_cell_2->Value);
								my $value3 = clean_string($template_3_cell_3->Value);
								my $value4 = clean_string($template_3_cell_4->Value);
								if(($value1 eq "Emisiune") and ($value2 eq "Titlu") and ($value3 eq "Interpret") and ($value4 eq "Nr.Difuzari")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T3"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t3.pl $file");	
								}
							}
							
							#TEMPLATE 4 (ok)
							my $template_4_cell_1 = $worksheet->get_cell(2, 0);
							my $template_4_cell_2 = $worksheet->get_cell(2, 1);
							my $template_4_cell_3 = $worksheet->get_cell(2, 2);
							my $template_4_cell_4 = $worksheet->get_cell(2, 3);
							
							if($template_4_cell_1 and $template_4_cell_2 and $template_4_cell_3 and $template_4_cell_4){
								my $value1 = clean_string($template_4_cell_1->Value);
								my $value2 = clean_string($template_4_cell_2->Value);
								my $value3 = clean_string($template_4_cell_3->Value);
								my $value4 = clean_string($template_4_cell_4->Value);
								if(($value1 eq "Minute") and ($value2 eq "Secunde") and ($value3 eq "Artist") and ($value4 eq "Titlu piesa")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T4"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t4.pl $file");	
								}
							}
							
							#TEMPLATE 5 (ok)
							my $template_5_cell_1 = $worksheet->get_cell(9, 1);
							my $template_5_cell_2 = $worksheet->get_cell(9, 3);
							my $template_5_cell_3 = $worksheet->get_cell(9, 6);
							my $template_5_cell_4 = $worksheet->get_cell(9, 12);
							
							if($template_5_cell_1 and $template_5_cell_2 and $template_5_cell_3 and $template_5_cell_4){
								my $value1 = clean_string($template_5_cell_1->Value);
								my $value2 = clean_string($template_5_cell_2->Value);
								my $value3 = clean_string($template_5_cell_3->Value);
								my $value4 = clean_string($template_5_cell_4->Value);
								if(($value1 eq "Emisiune") and ($value2 eq "Titlu piesa") and ($value3 eq "Interpreti") and ($value4 eq "Nr. Difuzari")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T5"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t5.pl $file");	
								}
							}
							
							#TEMPLATE 6 (ok)
							my $template_6_cell_1 = $worksheet->get_cell(0, 2);
							my $template_6_cell_2 = $worksheet->get_cell(0, 5);
							my $template_6_cell_3 = $worksheet->get_cell(0, 6);
							my $template_6_cell_4 = $worksheet->get_cell(0, 7);
							
							if($template_6_cell_1 and $template_6_cell_2 and $template_6_cell_3 and $template_6_cell_4){
								my $value1 = clean_string($template_6_cell_1->Value);
								my $value2 = clean_string($template_6_cell_2->Value);
								my $value3 = clean_string($template_6_cell_3->Value);
								my $value4 = clean_string($template_6_cell_4->Value);
								if(($value1 eq "Emisiune") and ($value2 eq "Nr. Dif") and ($value3 eq "Artist") and ($value4 eq "Titlu piesa")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T6"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t6.pl $file");	
								}
							}
							
							#TEMPLATE 7 (ok)
							my $template_7_cell_1 = $worksheet->get_cell(0, 2);
							my $template_7_cell_2 = $worksheet->get_cell(0, 3);
							my $template_7_cell_3 = $worksheet->get_cell(0, 4);
							my $template_7_cell_4 = $worksheet->get_cell(0, 8);
							
							if($template_7_cell_1 and $template_7_cell_2 and $template_7_cell_3 and $template_7_cell_4){
								my $value1 = clean_string($template_7_cell_1->Value);
								my $value2 = clean_string($template_7_cell_2->Value);
								my $value3 = clean_string($template_7_cell_3->Value);
								my $value4 = clean_string($template_7_cell_4->Value);
								if(($value1 eq "Emisiune") and ($value2 eq "Min") and ($value3 eq "Sec") and ($value4 eq "Titlu piesa")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T7"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t7.pl $file");	
								}
							}
							
							#TEMPLATE 8 (ok)
							my $template_8_cell_1 = $worksheet->get_cell(0, 0);
							my $template_8_cell_2 = $worksheet->get_cell(0, 3);
							my $template_8_cell_3 = $worksheet->get_cell(0, 6);
							my $template_8_cell_4 = $worksheet->get_cell(0, 7);
							
							if($template_8_cell_1 and $template_8_cell_2 and $template_8_cell_3 and $template_8_cell_4){
								my $value1 = clean_string($template_8_cell_1->Value);
								my $value2 = clean_string($template_8_cell_2->Value);
								my $value3 = clean_string($template_8_cell_3->Value);
								my $value4 = clean_string($template_8_cell_4->Value);
								if(($value1 eq "DATA") and ($value2 eq "TITLU") and ($value3 eq "ORCHESTRA") and ($value4 eq "TARA")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T8"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t8.pl $file");	
								}
							}
							
							#TEMPLATE 9 (ok)
							my $template_9_cell_1 = $worksheet->get_cell(0, 0);
							my $template_9_cell_2 = $worksheet->get_cell(0, 1);
							my $template_9_cell_3 = $worksheet->get_cell(0, 2);
							my $template_9_cell_4 = $worksheet->get_cell(0, 4);
							
							if($template_9_cell_1 and $template_9_cell_2 and $template_9_cell_3 and $template_9_cell_4){
								my $value1 = clean_string($template_9_cell_1->Value);
								my $value2 = clean_string($template_9_cell_2->Value);
								my $value3 = clean_string($template_9_cell_3->Value);
								my $value4 = clean_string($template_9_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Minute") and ($value4 eq "Titlu piesa")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T9"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t9.pl $file");	
								}
							}
							
							#TEMPLATE 10 (ok)
							my $template_10_cell_1 = $worksheet->get_cell(3, 0);
							my $template_10_cell_2 = $worksheet->get_cell(3, 1);
							my $template_10_cell_3 = $worksheet->get_cell(3, 2);
							my $template_10_cell_4 = $worksheet->get_cell(3, 6);
							
							if($template_10_cell_1 and $template_10_cell_2 and $template_10_cell_3 and $template_10_cell_4){
								my $value1 = clean_string($template_10_cell_1->Value);
								my $value2 = clean_string($template_10_cell_2->Value);
								my $value3 = clean_string($template_10_cell_3->Value);
								my $value4 = clean_string($template_10_cell_4->Value);
								if(($value1 eq "nr crt") and ($value2 eq "data dif") and ($value3 eq "Ora difuzarii") and ($value4 eq "titlu")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T10"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t10.pl $file");	
								}
							}
							
							#TEMPLATE 11 (ok)
							my $template_11_cell_1 = $worksheet->get_cell(4, 0);
							my $template_11_cell_2 = $worksheet->get_cell(4, 2);
							my $template_11_cell_3 = $worksheet->get_cell(4, 3);
							my $template_11_cell_4 = $worksheet->get_cell(4, 4);
							
							if($template_11_cell_1 and $template_11_cell_2 and $template_11_cell_3 and $template_11_cell_4){
								my $value1 = clean_string($template_11_cell_1->Value);
								my $value2 = clean_string($template_11_cell_2->Value);
								my $value3 = clean_string($template_11_cell_3->Value);
								my $value4 = clean_string($template_11_cell_4->Value);
								if(($value1 eq "Nr.crt.") and ($value2 eq "DESCRIERE *") and ($value3 eq "CANALUL TV") and ($value4 eq "Data/ORA DIFUZARII")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T11"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t11.pl $file");	
								}
							}
							
							#TEMPLATE 12 (ok)
							my $template_12_cell_1 = $worksheet->get_cell(4, 0);
							my $template_12_cell_2 = $worksheet->get_cell(4, 2);
							my $template_12_cell_3 = $worksheet->get_cell(4, 3);
							my $template_12_cell_4 = $worksheet->get_cell(4, 5);
							
							if($template_12_cell_1 and $template_12_cell_2 and $template_12_cell_3 and $template_12_cell_4){
								my $value1 = clean_string($template_12_cell_1->Value);
								my $value2 = clean_string($template_12_cell_2->Value);
								my $value3 = clean_string($template_12_cell_3->Value);
								my $value4 = clean_string($template_12_cell_4->Value);
								if(($value1 eq "Day") and ($value2 eq "Min") and ($value3 eq "Sec") and ($value4 eq "Song")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T12"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t12.pl $file");	
								}
							}
							
							#TEMPLATE 13 (ok)
							my $template_13_cell_1 = $worksheet->get_cell(13, 0);
							my $template_13_cell_2 = $worksheet->get_cell(13, 2);
							my $template_13_cell_3 = $worksheet->get_cell(13, 3);
							my $template_13_cell_4 = $worksheet->get_cell(13, 4);
							
							if($template_13_cell_1 and $template_13_cell_2 and $template_13_cell_3 and $template_13_cell_4){
								my $value1 = clean_string($template_13_cell_1->Value);
								my $value2 = clean_string($template_13_cell_2->Value);
								my $value3 = clean_string($template_13_cell_3->Value);
								my $value4 = clean_string($template_13_cell_4->Value);
								if(($value1 eq "Nr.") and ($value2 eq "Minute dufizate") and ($value3 eq "Secunde difuzate") and ($value4 eq "Titlu fonograma")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T13"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t13.pl $file");	
								}
							}
							
							#TEMPLATE 14 (ok)
							my $template_14_cell_1 = $worksheet->get_cell(0, 3);
							my $template_14_cell_2 = $worksheet->get_cell(0, 4);
							my $template_14_cell_3 = $worksheet->get_cell(0, 6);
							my $template_14_cell_4 = $worksheet->get_cell(0, 7);
							
							if($template_14_cell_1 and $template_14_cell_2 and $template_14_cell_3 and $template_14_cell_4){
								my $value1 = clean_string($template_14_cell_1->Value);
								my $value2 = clean_string($template_14_cell_2->Value);
								my $value3 = clean_string($template_14_cell_3->Value);
								my $value4 = clean_string($template_14_cell_4->Value);
								if(($value1 eq "ARTIST/A") and ($value2 eq "NUME MELODIE") and ($value3 eq "DURATA") and ($value4 eq "NR DIF")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T14"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t14.pl $file");	
								}
							}
							
							#TEMPLATE 15 (ok)
							my $template_15_cell_1 = $worksheet->get_cell(6, 0);
							my $template_15_cell_2 = $worksheet->get_cell(6, 1);
							my $template_15_cell_3 = $worksheet->get_cell(6, 2);
							my $template_15_cell_4 = $worksheet->get_cell(6, 3);
							
							if($template_15_cell_1 and $template_15_cell_2 and $template_15_cell_3 and $template_15_cell_4){
								my $value1 = clean_string($template_15_cell_1->Value);
								my $value2 = clean_string($template_15_cell_2->Value);
								my $value3 = clean_string($template_15_cell_3->Value);
								my $value4 = clean_string($template_15_cell_4->Value);
								if(($value1 eq "Data dif.") and ($value2 eq "Ora difuzare") and ($value3 eq "Min.difuzate") and ($value4 eq "Sec.difuzate")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T15"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t15.pl $file");	
								}
							}
							
							#TEMPLATE 16 (ok)
							my $template_16_cell_1 = $worksheet->get_cell(7, 0);
							my $template_16_cell_2 = $worksheet->get_cell(7, 1);
							my $template_16_cell_3 = $worksheet->get_cell(7, 4);
							my $template_16_cell_4 = $worksheet->get_cell(7, 5);
							
							if($template_16_cell_1 and $template_16_cell_2 and $template_16_cell_3 and $template_16_cell_4){
								my $value1 = clean_string($template_16_cell_1->Value);
								my $value2 = clean_string($template_16_cell_2->Value);
								my $value3 = clean_string($template_16_cell_3->Value);
								my $value4 = clean_string($template_16_cell_4->Value);
								if(($value1 eq "DATA DIFUZARII") and ($value2 eq "ORA DIFUZARII") and ($value3 eq "TITLU PIESA") and ($value4 eq "ARTIST")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T6"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t16.pl $file");	
								}
							}
							
							#TEMPLATE 17 (ok)
							my $template_17_cell_1 = $worksheet->get_cell(2, 0);
							my $template_17_cell_2 = $worksheet->get_cell(2, 1);
							my $template_17_cell_3 = $worksheet->get_cell(2, 3);
							my $template_17_cell_4 = $worksheet->get_cell(2, 5);
							
							if($template_17_cell_1 and $template_17_cell_2 and $template_17_cell_3 and $template_17_cell_4){
								my $value1 = clean_string($template_17_cell_1->Value);
								my $value2 = clean_string($template_17_cell_2->Value);
								my $value3 = clean_string($template_17_cell_3->Value);
								my $value4 = clean_string($template_17_cell_4->Value);
								if(($value1 eq "Nr. crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Minute difuzate") and ($value4 eq "Titlu fonograma")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T17"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t17.pl $file");	
								}
							}
							
							#TEMPLATE 18 (ok)
							my $template_18_cell_1 = $worksheet->get_cell(7, 0);
							my $template_18_cell_2 = $worksheet->get_cell(7, 1);
							my $template_18_cell_3 = $worksheet->get_cell(7, 6);
							my $template_18_cell_4 = $worksheet->get_cell(7, 7);
							
							if($template_18_cell_1 and $template_18_cell_2 and $template_18_cell_3 and $template_18_cell_4){
								my $value1 = clean_string($template_18_cell_1->Value);
								my $value2 = clean_string($template_18_cell_2->Value);
								my $value3 = clean_string($template_18_cell_3->Value);
								my $value4 = clean_string($template_18_cell_4->Value);
								if(($value1 eq "Nr. crt.") and ($value2 eq "Data difuzare") and ($value3 eq "Titlul emisiunii") and ($value4 eq "Titlul piesei")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T18"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t18.pl $file");	
								}
							}
							
							#TEMPLATE 19 (ok)
							my $template_19_cell_1 = $worksheet->get_cell(8, 0);
							my $template_19_cell_2 = $worksheet->get_cell(8, 1);
							my $template_19_cell_3 = $worksheet->get_cell(8, 3);
							my $template_19_cell_4 = $worksheet->get_cell(8, 4);
							
							if($template_19_cell_1 and $template_19_cell_2 and $template_19_cell_3 and $template_19_cell_4){
								my $value1 = clean_string($template_19_cell_1->Value);
								my $value2 = clean_string($template_19_cell_2->Value);
								my $value3 = clean_string($template_19_cell_3->Value);
								my $value4 = clean_string($template_19_cell_4->Value);
								if(($value1 eq "Nr. crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Minute difuzate") and ($value4 eq " Secunde difuzate")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T19"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t19.pl $file");	
								}
							}
							
							#TEMPLATE 20 (ok)
							my $template_20_cell_1 = $worksheet->get_cell(1, 0);
							my $template_20_cell_2 = $worksheet->get_cell(1, 2);
							my $template_20_cell_3 = $worksheet->get_cell(1, 3);
							my $template_20_cell_4 = $worksheet->get_cell(1, 4);
							
							if($template_20_cell_1 and $template_20_cell_2 and $template_20_cell_3 and $template_20_cell_4){
								my $value1 = clean_string($template_20_cell_1->Value);
								my $value2 = clean_string($template_20_cell_2->Value);
								my $value3 = clean_string($template_20_cell_3->Value);
								my $value4 = clean_string($template_20_cell_4->Value);
								if(($value1 eq "DATA") and ($value2 eq "ARTIST") and ($value3 eq "MELODIE") and ($value4 eq "Durata/piesa")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T20"});
									system("perl /var/perl-scripts/PERL/UNART/templates/T22.pl $file");	
								}
							}
=begin						
							#TEMPLATE 21
							my $template_21_cell_1 = $worksheet->get_cell(1, 0);
							my $template_21_cell_2 = $worksheet->get_cell(1, 2);
							my $template_21_cell_3 = $worksheet->get_cell(1, 3);
							my $template_21_cell_4 = $worksheet->get_cell(1, 4);
							
							if($template_21_cell_1 and $template_21_cell_2 and $template_21_cell_3 and $template_21_cell_4){
								my $value1 = clean_string($template_21_cell_1->Value);
								my $value2 = clean_string($template_21_cell_2->Value);
								my $value3 = clean_string($template_21_cell_3->Value);
								my $value4 = clean_string($template_21_cell_4->Value);
								if(($value1 eq "DATA") and ($value2 eq "ARTIST") and ($value3 eq "MELODIE") and ($value4 eq "Min")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t21.pl $file");	
								}
							}
=end COMMENT
=cut						
							#TEMPLATE 22 (ok)
							my $template_22_cell_1 = $worksheet->get_cell(14, 0);
							my $template_22_cell_2 = $worksheet->get_cell(14, 1);
							my $template_22_cell_3 = $worksheet->get_cell(14, 2);
							my $template_22_cell_4 = $worksheet->get_cell(14, 3);
							
							if($template_22_cell_1 and $template_22_cell_2 and $template_22_cell_3 and $template_22_cell_4){
								my $value1 = clean_string($template_22_cell_1->Value);
								my $value2 = clean_string($template_22_cell_2->Value);
								my $value3 = clean_string($template_22_cell_3->Value);
								my $value4 = clean_string($template_22_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Emisiunea") and ($value4 eq "Titlul Piesei")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T22"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t22.pl $file");	
								}
							}
							
							#TEMPLATE 23 (ok)
							my $template_23_cell_1 = $worksheet->get_cell(0, 0);
							my $template_23_cell_2 = $worksheet->get_cell(0, 1);
							my $template_23_cell_3 = $worksheet->get_cell(0, 2);
							my $template_23_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_23_cell_1 and $template_23_cell_2 and $template_23_cell_3 and $template_23_cell_4){
								my $value1 = clean_string($template_23_cell_1->Value);
								my $value2 = clean_string($template_23_cell_2->Value);
								my $value3 = clean_string($template_23_cell_3->Value);
								my $value4 = clean_string($template_23_cell_4->Value);
								if(($value1 eq "Canal") and ($value2 eq "Data") and ($value3 eq "Ora") and ($value4 eq "Distribuitor")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T23"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t23.pl $file");	
								}
							}
						
							#TEMPLATE 24 (ok)
							my $template_24_cell_1 = $worksheet->get_cell(2, 0);
							my $template_24_cell_2 = $worksheet->get_cell(2, 1);
							my $template_24_cell_3 = $worksheet->get_cell(2, 3);
							my $template_24_cell_4 = $worksheet->get_cell(2, 14);
							
							if($template_24_cell_1 and $template_24_cell_2 and $template_24_cell_3 and $template_24_cell_4){
								my $value1 = clean_string($template_24_cell_1->Value);
								my $value2 = clean_string($template_24_cell_2->Value);
								my $value3 = clean_string($template_24_cell_3->Value);
								my $value4 = clean_string($template_24_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Titlu piesa") and ($value4 eq "nr difuzari + reluari")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T24"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t24.pl $file");	
								}
							}
=begin						
							#TEMPLATE 25
							my $template_25_cell_1 = $worksheet->get_cell(2, 0);
							my $template_25_cell_2 = $worksheet->get_cell(2, 1);
							my $template_25_cell_3 = $worksheet->get_cell(2, 3);
							my $template_25_cell_4 = $worksheet->get_cell(2, 13);
							
							if($template_25_cell_1 and $template_25_cell_2 and $template_25_cell_3 and $template_25_cell_4){
								my $value1 = clean_string($template_25_cell_1->Value);
								my $value2 = clean_string($template_25_cell_2->Value);
								my $value3 = clean_string($template_25_cell_3->Value);
								my $value4 = clean_string($template_25_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Titlu piesa") and ($value4 eq "Nr. Difuzari")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t25.pl $file");	
								}
							}
=end COMMENT
=cut						
							#TEMPLATE 26 (ok)
							my $template_26_cell_1 = $worksheet->get_cell(1, 0);
							my $template_26_cell_2 = $worksheet->get_cell(1, 6);
							my $template_26_cell_3 = $worksheet->get_cell(1, 7);
							my $template_26_cell_4 = $worksheet->get_cell(1, 10);
							
							if($template_26_cell_1 and $template_26_cell_2 and $template_26_cell_3 and $template_26_cell_4){
								my $value1 = clean_string($template_26_cell_1->Value);
								my $value2 = clean_string($template_26_cell_2->Value);
								my $value3 = clean_string($template_26_cell_3->Value);
								my $value4 = clean_string($template_26_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Titlul piesei") and ($value3 eq "Autor") and ($value4 eq "Interpret")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T26"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t26.pl $file");	
								}
							}
						
							#TEMPLATE 27 (ok)
							my $template_27_cell_1 = $worksheet->get_cell(1, 1);
							my $template_27_cell_2 = $worksheet->get_cell(1, 2);
							my $template_27_cell_3 = $worksheet->get_cell(1, 4);
							my $template_27_cell_4 = $worksheet->get_cell(1, 7);
							
							if($template_27_cell_1 and $template_27_cell_2 and $template_27_cell_3 and $template_27_cell_4){
								my $value1 = clean_string($template_27_cell_1->Value);
								my $value2 = clean_string($template_27_cell_2->Value);
								my $value3 = clean_string($template_27_cell_3->Value);
								my $value4 = clean_string($template_27_cell_4->Value);
								if(($value1 eq "ora difuzare") and ($value2 eq "numele filmului") and ($value3 eq "durata") and ($value4 eq "Producator")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T27"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t27.pl $file");	
								}
							}
=begin						
							#TEMPLATE 28
							my $template_28_cell_1 = $worksheet->get_cell(0, 0);
							my $template_28_cell_2 = $worksheet->get_cell(0, 2);
							my $template_28_cell_3 = $worksheet->get_cell(0, 4);
							my $template_28_cell_4 = $worksheet->get_cell(0, 5);
							
							if($template_28_cell_1 and $template_28_cell_2 and $template_28_cell_3 and $template_28_cell_4){
								my $value1 = clean_string($template_28_cell_1->Value);
								my $value2 = clean_string($template_28_cell_2->Value);
								my $value3 = clean_string($template_28_cell_3->Value);
								my $value4 = clean_string($template_28_cell_4->Value);
								if(($value1 eq "DATA RADIODIFUZARII") and ($value2 eq "CRONOMETRAJ FILM  (SECUNDE)") and ($value3 eq "TITLUL FILMULUI") and ($value4 eq "REGIZOR")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t28.pl $file");	
								}
							}
							
							#TEMPLATE 29
							my $template_29_cell_1 = $worksheet->get_cell(0, 0);
							my $template_29_cell_2 = $worksheet->get_cell(0, 3);
							my $template_29_cell_3 = $worksheet->get_cell(0, 4);
							my $template_29_cell_4 = $worksheet->get_cell(0, 7);
							
							if($template_29_cell_1 and $template_29_cell_2 and $template_29_cell_3 and $template_29_cell_4){
								my $value1 = clean_string($template_29_cell_1->Value);
								my $value2 = clean_string($template_29_cell_2->Value);
								my $value3 = clean_string($template_29_cell_3->Value);
								my $value4 = clean_string($template_29_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Durata secunde") and ($value3 eq "Titlu") and ($value4 eq "Regia")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t29.pl $file");	
								}
							}
						
							#TEMPLATE 30
							my $template_30_cell_1 = $worksheet->get_cell(0, 0);
							my $template_30_cell_2 = $worksheet->get_cell(0, 1);
							my $template_30_cell_3 = $worksheet->get_cell(0, 2);
							my $template_30_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_30_cell_1 and $template_30_cell_2 and $template_30_cell_3 and $template_30_cell_4){
								my $value1 = clean_string($template_30_cell_1->Value);
								my $value2 = clean_string($template_30_cell_2->Value);
								my $value3 = clean_string($template_30_cell_3->Value);
								my $value4 = clean_string($template_30_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Minute") and ($value4 eq "Secunde")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t30.pl $file");	
								}
							}
						
							#TEMPLATE 31
							my $template_31_cell_1 = $worksheet->get_cell(0, 0);
							my $template_31_cell_2 = $worksheet->get_cell(0, 3);
							my $template_31_cell_3 = $worksheet->get_cell(0, 6);
							my $template_31_cell_4 = $worksheet->get_cell(0, 8);
							
							if($template_31_cell_1 and $template_31_cell_2 and $template_31_cell_3 and $template_31_cell_4){
								my $value1 = clean_string($template_31_cell_1->Value);
								my $value2 = clean_string($template_31_cell_2->Value);
								my $value3 = clean_string($template_31_cell_3->Value);
								my $value4 = clean_string($template_31_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Durata") and ($value3 eq "Denumire MCS") and ($value4 eq "Regie")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t31.pl $file");	
								}
							}
=end COMMENT
=cut							
							#TEMPLATE 32 (ok)
							my $template_32_cell_1 = $worksheet->get_cell(0, 0);
							my $template_32_cell_2 = $worksheet->get_cell(0, 5);
							my $template_32_cell_3 = $worksheet->get_cell(0, 7);
							my $template_32_cell_4 = $worksheet->get_cell(0, 10);
							
							if($template_32_cell_1 and $template_32_cell_2 and $template_32_cell_3 and $template_32_cell_4){
								my $value1 = clean_string($template_32_cell_1->Value);
								my $value2 = clean_string($template_32_cell_2->Value);
								my $value3 = clean_string($template_32_cell_3->Value);
								my $value4 = clean_string($template_32_cell_4->Value);
								if(($value1 eq "Canal") and ($value2 eq "Durata secunde") and ($value3 eq "Titlu") and ($value4 eq "Regie")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T32"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t32.pl $file");	
								}
							}
						
							#TEMPLATE 33 (ok)
							my $template_33_cell_1 = $worksheet->get_cell(2, 0);
							my $template_33_cell_2 = $worksheet->get_cell(2, 1);
							my $template_33_cell_3 = $worksheet->get_cell(2, 4);
							my $template_33_cell_4 = $worksheet->get_cell(2, 6);
							
							if($template_33_cell_1 and $template_33_cell_2 and $template_33_cell_3 and $template_33_cell_4){
								my $value1 = clean_string($template_33_cell_1->Value);
								my $value2 = clean_string($template_33_cell_2->Value);
								my $value3 = clean_string($template_33_cell_3->Value);
								my $value4 = clean_string($template_33_cell_4->Value);
								if(($value1 eq "Nr. crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Titlu piesa") and ($value4 eq "Artist")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T33"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t33.pl $file");	
								}
							}
						
							#TEMPLATE 34 (ok)
							my $template_34_cell_1 = $worksheet->get_cell(0, 0);
							my $template_34_cell_2 = $worksheet->get_cell(0, 1);
							my $template_34_cell_3 = $worksheet->get_cell(0, 2);
							my $template_34_cell_4 = $worksheet->get_cell(0, 4);
							
							if($template_34_cell_1 and $template_34_cell_2 and $template_34_cell_3 and $template_34_cell_4){
								my $value1 = clean_string($template_34_cell_1->Value);
								my $value2 = clean_string($template_34_cell_2->Value);
								my $value3 = clean_string($template_34_cell_3->Value);
								my $value4 = clean_string($template_34_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Post Radio") and ($value3 eq "Data") and ($value4 eq "Denumirea operei muzicale")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T34"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t34.pl $file");	
								}
							}
						
							#TEMPLATE 35 (ok)
							my $template_35_cell_1 = $worksheet->get_cell(1, 0);
							my $template_35_cell_2 = $worksheet->get_cell(1, 1);
							my $template_35_cell_3 = $worksheet->get_cell(1, 5);
							my $template_35_cell_4 = $worksheet->get_cell(1, 7);
							
							if($template_35_cell_1 and $template_35_cell_2 and $template_35_cell_3 and $template_35_cell_4){
								my $value1 = clean_string($template_35_cell_1->Value);
								my $value2 = clean_string($template_35_cell_2->Value);
								my $value3 = clean_string($template_35_cell_3->Value);
								my $value4 = clean_string($template_35_cell_4->Value);
								if(($value1 eq "ID") and ($value2 eq "date_played") and ($value3 eq "duration") and ($value4 eq "title")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T35"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t35.pl $file");	
								}
							}
						
							#TEMPLATE 36 (ok)
							my $template_36_cell_1 = $worksheet->get_cell(0, 1);
							my $template_36_cell_2 = $worksheet->get_cell(0, 3);
							my $template_36_cell_3 = $worksheet->get_cell(0, 5);
							my $template_36_cell_4 = $worksheet->get_cell(0, 8);
							
							if($template_36_cell_1 and $template_36_cell_2 and $template_36_cell_3 and $template_36_cell_4){ 
								my $value1 = clean_string($template_36_cell_1->Value);
								my $value2 = clean_string($template_36_cell_2->Value);
								my $value3 = clean_string($template_36_cell_3->Value);
								my $value4 = clean_string($template_36_cell_4->Value);
								if(($value1 eq "Emisiune") and ($value2 eq "Titlu") and ($value3 eq "Interpret") and ($value4 eq "Nr difuzari")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T36"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t36.pl $file");	
								}
							}
							
							#TEMPLATE 37 (ok)
							my $template_37_cell_1 = $worksheet->get_cell(10, 1);
							my $template_37_cell_2 = $worksheet->get_cell(10, 2);
							my $template_37_cell_3 = $worksheet->get_cell(10, 4);
							my $template_37_cell_4 = $worksheet->get_cell(10, 6);
							
							if($template_37_cell_1 and $template_37_cell_2 and $template_37_cell_3 and $template_37_cell_4){
								my $value1 = clean_string($template_37_cell_1->Value);
								my $value2 = clean_string($template_37_cell_2->Value);
								my $value3 = clean_string($template_37_cell_3->Value);
								my $value4 = clean_string($template_37_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Titlu") and ($value4 eq "Interpret")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T37"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t37.pl $file");	
								}
							}
						
							#TEMPLATE 38 (ok)
							my $template_38_cell_1 = $worksheet->get_cell(7, 0);
							my $template_38_cell_2 = $worksheet->get_cell(7, 2);
							my $template_38_cell_3 = $worksheet->get_cell(7, 3);
							my $template_38_cell_4 = $worksheet->get_cell(7, 4);
							
							if($template_38_cell_1 and $template_38_cell_2 and $template_38_cell_3 and $template_38_cell_4){
								my $value1 = clean_string($template_38_cell_1->Value);
								my $value2 = clean_string($template_38_cell_2->Value);
								my $value3 = clean_string($template_38_cell_3->Value);
								my $value4 = clean_string($template_38_cell_4->Value);
								if(($value1 eq "DATA DIFUZARII") and ($value2 eq "MINUTE") and ($value3 eq "SECUNDE") and ($value4 eq "TITLU PIESA")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T38"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t38.pl $file");	
								}
							}
							
							#TEMPLATE 39 (ok)
							my $template_39_cell_1 = $worksheet->get_cell(8, 2);
							my $template_39_cell_2 = $worksheet->get_cell(8, 3);
							my $template_39_cell_3 = $worksheet->get_cell(8, 6);
							my $template_39_cell_4 = $worksheet->get_cell(8, 21);
							
							if($template_39_cell_1 and $template_39_cell_2 and $template_39_cell_3 and $template_39_cell_4){
								my $value1 = clean_string($template_39_cell_1->Value);
								my $value2 = clean_string($template_39_cell_2->Value);
								my $value3 = clean_string($template_39_cell_3->Value);
								my $value4 = clean_string($template_39_cell_4->Value);
								if(($value1 eq "Nr. crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Minute difuzate") and ($value4 eq "Artist/Interpret")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T39"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t39.pl $file");	
								}
							}
						
							#TEMPLATE 40 (ok)
							my $template_40_cell_1 = $worksheet->get_cell(2, 2);
							my $template_40_cell_2 = $worksheet->get_cell(2, 3);
							my $template_40_cell_3 = $worksheet->get_cell(2, 4);
							my $template_40_cell_4 = $worksheet->get_cell(2, 5);
							
							if($template_40_cell_1 and $template_40_cell_2 and $template_40_cell_3 and $template_40_cell_4){
								my $value1 = clean_string($template_40_cell_1->Value);
								my $value2 = clean_string($template_40_cell_2->Value);
								my $value3 = clean_string($template_40_cell_3->Value);
								my $value4 = clean_string($template_40_cell_4->Value);
								if(($value1 eq "Nr minute difuzate") and ($value2 eq "Nr secunde difuzate") and ($value3 eq "Titlul piesei") and ($value4 eq "Interpretul / Trupa")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T40"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t40.pl $file");	
								}
							}
=begin comment							
							#TEMPLATE 41
							my $template_41_cell_1 = $worksheet->get_cell(1, 2);
							my $template_41_cell_2 = $worksheet->get_cell(1, 3);
							my $template_41_cell_3 = $worksheet->get_cell(1, 4);
							my $template_41_cell_4 = $worksheet->get_cell(1, 5);
							
							if($template_41_cell_1 and $template_41_cell_2 and $template_41_cell_3 and $template_41_cell_4){
								my $value1 = clean_string($template_41_cell_1->Value);
								my $value2 = clean_string($template_41_cell_2->Value);
								my $value3 = clean_string($template_41_cell_3->Value);
								my $value4 = clean_string($template_41_cell_4->Value);
								if(($value1 eq "Nr minute difuzate") and ($value2 eq "Nr secunde difuzate") and ($value3 eq "Titlul piesei") and ($value4 eq "Interpretul / Trupa")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t41.pl $file");	
								}
							}
=end COMMENT
=cut						
							#TEMPLATE 42 (ok)
							my $template_42_cell_1 = $worksheet->get_cell(0, 1);
							my $template_42_cell_2 = $worksheet->get_cell(0, 5);
							my $template_42_cell_3 = $worksheet->get_cell(0, 7);
							my $template_42_cell_4 = $worksheet->get_cell(0, 8);
							
							if($template_42_cell_1 and $template_42_cell_2 and $template_42_cell_3 and $template_42_cell_4){
								my $value1 = clean_string($template_42_cell_1->Value);
								my $value2 = clean_string($template_42_cell_2->Value);
								my $value3 = clean_string($template_42_cell_3->Value);
								my $value4 = clean_string($template_42_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Interpret") and ($value3 eq "Dirijor") and ($value4 eq "Album")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T42"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t42.pl $file");	
								}
							}
=begin comment							
							#TEMPLATE 43
							my $template_43_cell_1 = $worksheet->get_cell(8, 0);
							my $template_43_cell_2 = $worksheet->get_cell(8, 1);
							my $template_43_cell_3 = $worksheet->get_cell(8, 3);
							my $template_43_cell_4 = $worksheet->get_cell(8, 4);
							
							if($template_43_cell_1 and $template_43_cell_2 and $template_43_cell_3 and $template_43_cell_4){
								my $value1 = clean_string($template_43_cell_1->Value);
								my $value2 = clean_string($template_43_cell_2->Value);
								my $value3 = clean_string($template_43_cell_3->Value);
								my $value4 = clean_string($template_43_cell_4->Value);
								if(($value1 eq "NR CRT") and ($value2 eq "DATA DIFUZARII") and ($value3 eq "MINUTE") and ($value4 eq "SECUNDE")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t43.pl $file");	
								}
							}
=end COMMENT
=cut							
							#TEMPLATE 44 (ok) 
							my $template_44_cell_1 = $worksheet->get_cell(7, 0);
							my $template_44_cell_2 = $worksheet->get_cell(7, 1);
							my $template_44_cell_3 = $worksheet->get_cell(7, 3);
							my $template_44_cell_4 = $worksheet->get_cell(7, 4);
							
							if($template_44_cell_1 and $template_44_cell_2 and $template_44_cell_3 and $template_44_cell_4){
								my $value1 = clean_string($template_44_cell_1->Value);
								my $value2 = clean_string($template_44_cell_2->Value);
								my $value3 = clean_string($template_44_cell_3->Value);
								my $value4 = clean_string($template_44_cell_4->Value);
								if(($value1 eq "") and ($value2 eq "DATA DIFUZARII") and ($value3 eq "MINUTE") and ($value4 eq "SECUNDE")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T44"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t44.pl $file");	
								}
							}
=begin comment							
							#TEMPLATE 45
							my $template_45_cell_1 = $worksheet->get_cell(0, 0);
							my $template_45_cell_2 = $worksheet->get_cell(0, 1);
							my $template_45_cell_3 = $worksheet->get_cell(0, 2);
							my $template_45_cell_4 = $worksheet->get_cell(0, 7);
							
							if($template_45_cell_1 and $template_45_cell_2 and $template_45_cell_3 and $template_45_cell_4){
								my $value1 = clean_string($template_45_cell_1->Value);
								my $value2 = clean_string($template_45_cell_2->Value);
								my $value3 = clean_string($template_45_cell_3->Value);
								my $value4 = clean_string($template_45_cell_4->Value);
								if(($value1 eq "DateTime") and ($value2 eq "Artist") and ($value3 eq "Title") and ($value4 eq "PlayCount")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t45.pl $file");	
								}
							}
=end COMMENT
=cut							 
							#TEMPLATE 46 (ok)  
							my $template_46_cell_1 = $worksheet->get_cell(7, 0);
							my $template_46_cell_2 = $worksheet->get_cell(7, 1);
							my $template_46_cell_3 = $worksheet->get_cell(7, 3);
							my $template_46_cell_4 = $worksheet->get_cell(7, 4);
							
							if($template_46_cell_1 and $template_46_cell_2 and $template_46_cell_3 and $template_46_cell_4){
								my $value1 = clean_string($template_46_cell_1->Value);
								my $value2 = clean_string($template_46_cell_2->Value);
								my $value3 = clean_string($template_46_cell_3->Value);
								my $value4 = clean_string($template_46_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "EMISIUNE") and ($value3 eq "Interpret") and ($value4 eq "Titlu")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T46"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t46.pl $file");	
								}
							}
							
							#TEMPLATE 47 (ok)
							my $template_47_cell_1 = $worksheet->get_cell(0, 0);
							my $template_47_cell_2 = $worksheet->get_cell(0, 1);
							my $template_47_cell_3 = $worksheet->get_cell(0, 1);
							my $template_47_cell_4 = $worksheet->get_cell(0, 2);
							
							if($template_47_cell_1 and $template_47_cell_2 and $template_47_cell_3 and $template_47_cell_4){
								my $value1 = clean_string($template_47_cell_1->Value);
								my $value2 = clean_string($template_47_cell_2->Value);
								my $value3 = clean_string($template_47_cell_3->Value);
								my $value4 = clean_string($template_47_cell_4->Value);
								if(($value1 eq "DATA DIFUZARE") and ($value2 eq "ORA DIFUZARE") and ($value3 eq "ARTIST") and ($value4 eq "PIESA")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T47"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t47.pl $file");	
								}
							}
							
							#TEMPLATE 48 (ok)
							my $template_48_cell_1 = $worksheet->get_cell(8, 0);
							my $template_48_cell_2 = $worksheet->get_cell(8, 1);
							my $template_48_cell_3 = $worksheet->get_cell(8, 3);
							my $template_48_cell_4 = $worksheet->get_cell(8, 4);
							
							if($template_48_cell_1 and $template_48_cell_2 and $template_48_cell_3 and $template_48_cell_4){
								my $value1 = clean_string($template_48_cell_1->Value);
								my $value2 = clean_string($template_48_cell_2->Value);
								my $value3 = clean_string($template_48_cell_3->Value);
								my $value4 = clean_string($template_48_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Interpret") and ($value4 eq "Titlu")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T48"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t48.pl $file");	
								}
							}
							
							#TEMPLATE 49 (ok)
							my $template_49_cell_1 = $worksheet->get_cell(5, 0);
							my $template_49_cell_2 = $worksheet->get_cell(5, 2);
							my $template_49_cell_3 = $worksheet->get_cell(5, 3);
							my $template_49_cell_4 = $worksheet->get_cell(5, 5);
							
							if($template_49_cell_1 and $template_49_cell_2 and $template_49_cell_3 and $template_49_cell_4){
								my $value1 = clean_string($template_49_cell_1->Value);
								my $value2 = clean_string($template_49_cell_2->Value);
								my $value3 = clean_string($template_49_cell_3->Value);
								my $value4 = clean_string($template_49_cell_4->Value);
								if(($value1 eq "Day") and ($value2 eq "Min") and ($value3 eq "Sec") and ($value4 eq "Song")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T49"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t49.pl $file");	
								}
							}
							
							#TEMPLATE 50 (ok)
							my $template_50_cell_1 = $worksheet->get_cell(0, 0);
							my $template_50_cell_2 = $worksheet->get_cell(0, 1);
							my $template_50_cell_3 = $worksheet->get_cell(0, 4);
							my $template_50_cell_4 = $worksheet->get_cell(0, 7);
							
							if($template_50_cell_1 and $template_50_cell_2 and $template_50_cell_3 and $template_50_cell_4){
								my $value1 = clean_string($template_50_cell_1->Value);
								my $value2 = clean_string($template_50_cell_2->Value);
								my $value3 = clean_string($template_50_cell_3->Value);
								my $value4 = clean_string($template_50_cell_4->Value);
								if(($value1 eq "Nume Spot") and ($value2 eq "Voce") and ($value3 eq "Nume artist/compozitor piesa fundal") and ($value4 eq "Timp (s)")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T50"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t50.pl $file");	
								}
							}
							
							#TEMPLATE 51 (ok)
							my $template_51_cell_1 = $worksheet->get_cell(5, 0);
							my $template_51_cell_2 = $worksheet->get_cell(5, 1);
							my $template_51_cell_3 = $worksheet->get_cell(5, 3);
							my $template_51_cell_4 = $worksheet->get_cell(5, 4);
							
							if($template_51_cell_1 and $template_51_cell_2 and $template_51_cell_3 and $template_51_cell_4){
								my $value1 = clean_string($template_51_cell_1->Value);
								my $value2 = clean_string($template_51_cell_2->Value);
								my $value3 = clean_string($template_51_cell_3->Value);
								my $value4 = clean_string($template_51_cell_4->Value);
								if(($value1 eq "NR. CRT") and ($value2 eq "DATA DIFUZARE") and ($value3 eq "MINUTE") and ($value4 eq "SECUNDE")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T51"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t51.pl $file");	
								}
							}
=begin comment							 
							#TEMPLATE 52 
							my $template_52_cell_1 = $worksheet->get_cell(6, 0);
							my $template_52_cell_2 = $worksheet->get_cell(6, 1);
							my $template_52_cell_3 = $worksheet->get_cell(6, 2);
							my $template_52_cell_4 = $worksheet->get_cell(6, 3);
							
							if($template_52_cell_1 and $template_52_cell_2 and $template_52_cell_3 and $template_52_cell_4){
								my $value1 = clean_string($template_52_cell_1->Value);
								my $value2 = clean_string($template_52_cell_2->Value);
								my $value3 = clean_string($template_52_cell_3->Value);
								my $value4 = clean_string($template_52_cell_4->Value);
								if(($value1 eq "Data dif.") and ($value2 eq "Ora difuzare") and ($value3 eq "Min.difuzate") and ($value4 eq "Sec.difuzate")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t52.pl $file");	
								}
							}
=end COMMENT
=cut							
							#TEMPLATE 53 (ok)
							my $template_53_cell_1 = $worksheet->get_cell(6, 0);
							my $template_53_cell_2 = $worksheet->get_cell(6, 1);
							my $template_53_cell_3 = $worksheet->get_cell(6, 3);
							my $template_53_cell_4 = $worksheet->get_cell(6, 4);
							
							if($template_53_cell_1 and $template_53_cell_2 and $template_53_cell_3 and $template_53_cell_4){
								my $value1 = clean_string($template_53_cell_1->Value);
								my $value2 = clean_string($template_53_cell_2->Value);
								my $value3 = clean_string($template_53_cell_3->Value);
								my $value4 = clean_string($template_53_cell_4->Value);
								if(($value1 eq "Nr.crt") and ($value2 eq "Data") and ($value3 eq "Minute") and ($value4 eq "Secunde")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T53"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t53.pl $file");	
								}
							}
							
							#TEMPLATE 54 (ok)
							my $template_54_cell_1 = $worksheet->get_cell(0, 0);
							my $template_54_cell_2 = $worksheet->get_cell(0, 1);
							my $template_54_cell_3 = $worksheet->get_cell(0, 2);
							my $template_54_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_54_cell_1 and $template_54_cell_2 and $template_54_cell_3 and $template_54_cell_4){
								my $value1 = clean_string($template_54_cell_1->Value);
								my $value2 = clean_string($template_54_cell_2->Value);
								my $value3 = clean_string($template_54_cell_3->Value);
								my $value4 = clean_string($template_54_cell_4->Value);
								if(($value1 eq "Ziua") and ($value2 eq "Numar Difuzari") and ($value3 eq "Minute") and ($value4 eq "Secunde")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T54"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t54.pl $file");	
								}
							}
							
							#TEMPLATE 55 (ok)
							my $template_55_cell_1 = $worksheet->get_cell(6, 0);
							my $template_55_cell_2 = $worksheet->get_cell(6, 1);
							my $template_55_cell_3 = $worksheet->get_cell(6, 2);
							my $template_55_cell_4 = $worksheet->get_cell(6, 3);
							
							if($template_55_cell_1 and $template_55_cell_2 and $template_55_cell_3 and $template_55_cell_4){
								my $value1 = clean_string($template_55_cell_1->Value);
								my $value2 = clean_string($template_55_cell_2->Value);
								my $value3 = clean_string($template_55_cell_3->Value);
								my $value4 = clean_string($template_55_cell_4->Value);
								if(($value1 eq "Zi") and ($value2 eq "Luna") and ($value3 eq "An") and ($value4 eq "Ora")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T55"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t55.pl $file");	
								}
							}
							
							#TEMPLATE 56 (ok)
							my $template_56_cell_1 = $worksheet->get_cell(14, 0);
							my $template_56_cell_2 = $worksheet->get_cell(14, 3);
							my $template_56_cell_3 = $worksheet->get_cell(14, 4);
							my $template_56_cell_4 = $worksheet->get_cell(14, 5);
							
							if($template_56_cell_1 and $template_56_cell_2 and $template_56_cell_3 and $template_56_cell_4){
								my $value1 = clean_string($template_56_cell_1->Value);
								my $value2 = clean_string($template_56_cell_2->Value);
								my $value3 = clean_string($template_56_cell_3->Value);
								my $value4 = clean_string($template_56_cell_4->Value);
								if(($value1 eq "Data difuzarii") and ($value2 eq "Interpret") and ($value3 eq "Titlu piesa") and ($value4 eq "Compozitor")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T56"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t56.pl $file");	
								}
							}
							
							#TEMPLATE 57 (ok)
							my $template_57_cell_1 = $worksheet->get_cell(0, 1);
							my $template_57_cell_2 = $worksheet->get_cell(0, 2);
							my $template_57_cell_3 = $worksheet->get_cell(0, 3);
							my $template_57_cell_4 = $worksheet->get_cell(0, 4);
							
							if($template_57_cell_1 and $template_57_cell_2 and $template_57_cell_3 and $template_57_cell_4){
								my $value1 = clean_string($template_57_cell_1->Value);
								my $value2 = clean_string($template_57_cell_2->Value);
								my $value3 = clean_string($template_57_cell_3->Value);
								my $value4 = clean_string($template_57_cell_4->Value);
								if(($value1 eq "Ziua") and ($value2 eq "Ora") and ($value3 eq "Minute") and ($value4 eq "Secunde")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T57"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t57.pl $file");	
								}
							}
=begin comment							
							#TEMPLATE 58
							my $template_58_cell_1 = $worksheet->get_cell(1, 1);
							my $template_58_cell_2 = $worksheet->get_cell(1, 2);
							my $template_58_cell_3 = $worksheet->get_cell(1, 3);
							my $template_58_cell_4 = $worksheet->get_cell(1, 4);
							
							if($template_58_cell_1 and $template_58_cell_2 and $template_58_cell_3 and $template_58_cell_4){
								my $value1 = clean_string($template_58_cell_1->Value);
								my $value2 = clean_string($template_58_cell_2->Value);
								my $value3 = clean_string($template_58_cell_3->Value);
								my $value4 = clean_string($template_58_cell_4->Value);
								if(($value1 eq "Post TV/Radio") and ($value2 eq "Emisiune") and ($value3 eq "Titlu opera muzicala") and ($value4 eq "Durata minute, secunde")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t58.pl $file");	
								}
							}
							
							#TEMPLATE 59
							my $template_59_cell_1 = $worksheet->get_cell(13, 0);
							my $template_59_cell_2 = $worksheet->get_cell(13, 1);
							my $template_59_cell_3 = $worksheet->get_cell(13, 2);
							my $template_59_cell_4 = $worksheet->get_cell(13, 3);
							
							if($template_59_cell_1 and $template_59_cell_2 and $template_59_cell_3 and $template_59_cell_4){
								my $value1 = clean_string($template_59_cell_1->Value);
								my $value2 = clean_string($template_59_cell_2->Value);
								my $value3 = clean_string($template_59_cell_3->Value);
								my $value4 = clean_string($template_59_cell_4->Value);
								if(($value1 eq "Nr crt") and ($value2 eq "DATA DIFUZARII") and ($value3 eq "ORA DIFUZARII") and ($value4 eq "MINUTE")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t59.pl $file");	
								}
							}
							
							#TEMPLATE 60
							my $template_60_cell_1 = $worksheet->get_cell(9, 0);
							my $template_60_cell_2 = $worksheet->get_cell(9, 1);
							my $template_60_cell_3 = $worksheet->get_cell(9, 2);
							my $template_60_cell_4 = $worksheet->get_cell(9, 3);
							
							if($template_60_cell_1 and $template_60_cell_2 and $template_60_cell_3 and $template_60_cell_4){
								my $value1 = clean_string($template_60_cell_1->Value);
								my $value2 = clean_string($template_60_cell_2->Value);
								my $value3 = clean_string($template_60_cell_3->Value);
								my $value4 = clean_string($template_60_cell_4->Value);
								if(($value1 eq "Nr") and ($value2 eq "DATA DIFUZARII") and ($value3 eq "ORA DIFUZARII") and ($value4 eq "MINUTE")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t60.pl $file");	
								}
							}
							
							#TEMPLATE 61
							my $template_61_cell_1 = $worksheet->get_cell(7, 0);
							my $template_61_cell_2 = $worksheet->get_cell(7, 1);
							my $template_61_cell_3 = $worksheet->get_cell(7, 3);
							my $template_61_cell_4 = $worksheet->get_cell(7, 4);
							
							if($template_61_cell_1 and $template_61_cell_2 and $template_61_cell_3 and $template_61_cell_4){
								my $value1 = clean_string($template_61_cell_1->Value);
								my $value2 = clean_string($template_61_cell_2->Value);
								my $value3 = clean_string($template_61_cell_3->Value);
								my $value4 = clean_string($template_61_cell_4->Value);
								if(($value1 eq "Nr crt") and ($value2 eq "Data") and ($value3 eq "Min") and ($value4 eq "Sec")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t61.pl $file");	
								}
							}
							
							#TEMPLATE 62
							my $template_62_cell_1 = $worksheet->get_cell(8, 0);
							my $template_62_cell_2 = $worksheet->get_cell(8, 1);
							my $template_62_cell_3 = $worksheet->get_cell(8, 2);
							my $template_62_cell_4 = $worksheet->get_cell(8, 3);
							
							if($template_62_cell_1 and $template_62_cell_2 and $template_62_cell_3 and $template_62_cell_4){
								my $value1 = clean_string($template_62_cell_1->Value);
								my $value2 = clean_string($template_62_cell_2->Value);
								my $value3 = clean_string($template_62_cell_3->Value);
								my $value4 = clean_string($template_62_cell_4->Value);
								if(($value1 eq "Nr crt") and ($value2 eq "Data difuzarii") and ($value3 eq "Ora difuzarii") and ($value4 eq "Minute difuzate")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t62.pl $file");	
								}
							}
=end COMMENT
=cut							
							#TEMPLATE 63 (ok)
							my $template_63_cell_1 = $worksheet->get_cell(5, 0);
							my $template_63_cell_2 = $worksheet->get_cell(5, 1);
							my $template_63_cell_3 = $worksheet->get_cell(5, 2);
							my $template_63_cell_4 = $worksheet->get_cell(5, 3);
							
							if($template_63_cell_1 and $template_63_cell_2 and $template_63_cell_3 and $template_63_cell_4){
								my $value1 = clean_string($template_63_cell_1->Value);
								my $value2 = clean_string($template_63_cell_2->Value);
								my $value3 = clean_string($template_63_cell_3->Value);
								my $value4 = clean_string($template_63_cell_4->Value);
								if(($value1 eq "Date") and ($value2 eq "Hour") and ($value3 eq "Minutes") and ($value4 eq "Seconds")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T63"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t63.pl $file");	
								}
							}
							
							#TEMPLATE 64 (ok)
							my $template_64_cell_1 = $worksheet->get_cell(3, 0);
							my $template_64_cell_2 = $worksheet->get_cell(3, 1);
							my $template_64_cell_3 = $worksheet->get_cell(3, 2);
							my $template_64_cell_4 = $worksheet->get_cell(3, 3);
							
							if($template_64_cell_1 and $template_64_cell_2 and $template_64_cell_3 and $template_64_cell_4){
								my $value1 = clean_string($template_64_cell_1->Value);
								my $value2 = clean_string($template_64_cell_2->Value);
								my $value3 = clean_string($template_64_cell_3->Value);
								my $value4 = clean_string($template_64_cell_4->Value);
								if(($value1 eq "Date") and ($value2 eq "Hour") and ($value3 eq "Minutes") and ($value4 eq "Seconds")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T64"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t64.pl $file");	
								}
							}
							
							#TEMPLATE 65 (ok)
							my $template_65_cell_1 = $worksheet->get_cell(0, 0);
							my $template_65_cell_2 = $worksheet->get_cell(0, 1);
							my $template_65_cell_3 = $worksheet->get_cell(0, 2);
							my $template_65_cell_4 = $worksheet->get_cell(0, 4);
							
							if($template_65_cell_1 and $template_65_cell_2 and $template_65_cell_3 and $template_65_cell_4){
								my $value1 = clean_string($template_65_cell_1->Value);
								my $value2 = clean_string($template_65_cell_2->Value);
								my $value3 = clean_string($template_65_cell_3->Value);
								my $value4 = clean_string($template_65_cell_4->Value);
								if(($value1 eq "Nr Crt") and ($value2 eq "Data Difuzarii") and ($value3 eq "Ora Difuzarii") and ($value4 eq "Secunde Difuzate")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T65"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t65.pl $file");	
								}
							}
=begin COMMENT							
							#TEMPLATE 66
							my $template_66_cell_1 = $worksheet->get_cell(3, 1);
							my $template_66_cell_2 = $worksheet->get_cell(3, 2);
							my $template_66_cell_3 = $worksheet->get_cell(3, 3);
							
							if($template_66_cell_1 and $template_66_cell_2 and $template_66_cell_3){
								my $value1 = clean_string($template_66_cell_1->Value);
								my $value2 = clean_string($template_66_cell_2->Value);
								my $value3 = clean_string($template_66_cell_3->Value);
								if(($value1 eq "Ziua") and ($value2 eq "Ora Dif.") and ($value3 eq "Titlu Spot")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t66.pl $file");	
								}
							}
=end COMMENT
=cut							
							#TEMPLATE 67 (ok)
							my $template_67_cell_1 = $worksheet->get_cell(0, 0);
							my $template_67_cell_2 = $worksheet->get_cell(0, 1);
							my $template_67_cell_3 = $worksheet->get_cell(0, 2);
							my $template_67_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_67_cell_1 and $template_67_cell_2 and $template_67_cell_3 and $template_67_cell_4){
								my $value1 = clean_string($template_67_cell_1->Value);
								my $value2 = clean_string($template_67_cell_2->Value);
								my $value3 = clean_string($template_67_cell_3->Value);
								my $value4 = clean_string($template_67_cell_4->Value);
								if(($value1 eq "NrCrt") and ($value2 eq "DataDifuzarii") and ($value3 eq "OraDifuzarii") and ($value4 eq "MinuteDifuzate")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T67"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t67.pl $file");	
								}
							}
=begin COMMENT							
							#TEMPLATE 68
							my $template_68_cell_1 = $worksheet->get_cell(1, 0);
							my $template_68_cell_2 = $worksheet->get_cell(1, 1);
							my $template_68_cell_3 = $worksheet->get_cell(1, 2);
							my $template_68_cell_4 = $worksheet->get_cell(1, 3);
							
							if($template_68_cell_1 and $template_68_cell_2 and $template_68_cell_3 and $template_68_cell_4){
								my $value1 = clean_string($template_68_cell_1->Value);
								my $value2 = clean_string($template_68_cell_2->Value);
								my $value3 = clean_string($template_68_cell_3->Value);
								my $value4 = clean_string($template_68_cell_4->Value);
								if(($value1 eq "Ziua") and ($value2 eq "Ora sau Spatiu orar") and ($value3 eq "Minute") and ($value4 eq "Secunde")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t68.pl $file");	
								}
							}
=end COMMENT
=cut							
							#TEMPLATE 69 (ok)
							my $template_69_cell_1 = $worksheet->get_cell(7, 0);
							my $template_69_cell_2 = $worksheet->get_cell(7, 1);
							my $template_69_cell_3 = $worksheet->get_cell(7, 2);
							my $template_69_cell_4 = $worksheet->get_cell(7, 3);
							
							if($template_69_cell_1 and $template_69_cell_2 and $template_69_cell_3 and $template_69_cell_4){
								my $value1 = clean_string($template_69_cell_1->Value);
								my $value2 = clean_string($template_69_cell_2->Value);
								my $value3 = clean_string($template_69_cell_3->Value);
								my $value4 = clean_string($template_69_cell_4->Value);
								if(($value1 eq "DATA DIFUZARII") and ($value2 eq "ORA DIFUZARII") and ($value3 eq "MINUTE") and ($value4 eq "SECUNDE")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T69"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t69.pl $file");	
								}
							}
=begin COMMENTS							
							#TEMPLATE 70
							my $template_70_cell_1 = $worksheet->get_cell(7, 0);
							my $template_70_cell_2 = $worksheet->get_cell(7, 1);
							my $template_70_cell_3 = $worksheet->get_cell(7, 2);
							my $template_70_cell_4 = $worksheet->get_cell(7, 3);
							
							if($template_70_cell_1 and $template_70_cell_2 and $template_70_cell_3 and $template_70_cell_4){
								my $value1 = clean_string($template_70_cell_1->Value);
								my $value2 = clean_string($template_70_cell_2->Value);
								my $value3 = clean_string($template_70_cell_3->Value);
								my $value4 = clean_string($template_70_cell_4->Value);
								if(($value1 eq "DATA DIFUZARII") and ($value2 eq "POST RADIO") and ($value3 eq "TITLU OPERA MUZICALA") and ($value4 eq "EMISIUNE")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t70.pl $file");	
								}
							}
=end COMMENT
=cut							
							#TEMPLATE 71 (ok)
							my $template_71_cell_1 = $worksheet->get_cell(0, 0);
							my $template_71_cell_2 = $worksheet->get_cell(0, 1);
							my $template_71_cell_3 = $worksheet->get_cell(0, 2);
							my $template_71_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_71_cell_1 and $template_71_cell_2 and $template_71_cell_3 and $template_71_cell_4){
								my $value1 = clean_string($template_71_cell_1->Value);
								my $value2 = clean_string($template_71_cell_2->Value);
								my $value3 = clean_string($template_71_cell_3->Value);
								my $value4 = clean_string($template_71_cell_4->Value);
								if(($value1 eq "DATA") and ($value2 eq "ORA") and ($value3 eq "DURATA") and ($value4 eq "INTERPRET")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T71"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t71.pl $file");	
								}
							}
							
							#TEMPLATE 72 (ok)
							my $template_72_cell_1 = $worksheet->get_cell(7, 0);
							my $template_72_cell_2 = $worksheet->get_cell(7, 2);
							my $template_72_cell_3 = $worksheet->get_cell(7, 3);
							my $template_72_cell_4 = $worksheet->get_cell(7, 4);
							
							if($template_72_cell_1 and $template_72_cell_2 and $template_72_cell_3 and $template_72_cell_4){
								my $value1 = clean_string($template_72_cell_1->Value);
								my $value2 = clean_string($template_72_cell_2->Value);
								my $value3 = clean_string($template_72_cell_3->Value);
								my $value4 = clean_string($template_72_cell_4->Value);
								if(($value1 eq "Day") and ($value2 eq "Min") and ($value3 eq "Sec") and ($value4 eq "Artist")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T72"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t72.pl $file");	
								}
							}
=begin COMMENTS							
							#TEMPLATE 73
							my $template_73_cell_1 = $worksheet->get_cell(0, 0);
							my $template_73_cell_2 = $worksheet->get_cell(0, 1);
							my $template_73_cell_3 = $worksheet->get_cell(0, 2);
							my $template_73_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_73_cell_1 and $template_73_cell_2 and $template_73_cell_3 and $template_73_cell_4){
								my $value1 = clean_string($template_73_cell_1->Value);
								my $value2 = clean_string($template_73_cell_2->Value);
								my $value3 = clean_string($template_73_cell_3->Value);
								my $value4 = clean_string($template_73_cell_4->Value);
								if(($value1 eq "nr.crt") and ($value2 eq "firma/campanie") and ($value3 eq "artist/titlu") and ($value4 eq "durata spot")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t73.pl $file");	
								}
							}
							
							#TEMPLATE 74
							my $template_74_cell_1 = $worksheet->get_cell(0, 0);
							my $template_74_cell_2 = $worksheet->get_cell(0, 1);
							my $template_74_cell_3 = $worksheet->get_cell(0, 2);
							my $template_74_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_74_cell_1 and $template_74_cell_2 and $template_74_cell_3 and $template_74_cell_4){
								my $value1 = clean_string($template_74_cell_1->Value);
								my $value2 = clean_string($template_74_cell_2->Value);
								my $value3 = clean_string($template_74_cell_3->Value);
								my $value4 = clean_string($template_74_cell_4->Value);
								if(($value1 eq "data") and ($value2 eq "ora") and ($value3 eq "durata") and ($value4 eq "interpret + titlu")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t74.pl $file");	
								}
							}
							
							#TEMPLATE 75
							my $template_75_cell_1 = $worksheet->get_cell(0, 0);
							my $template_75_cell_2 = $worksheet->get_cell(0, 1);
							my $template_75_cell_3 = $worksheet->get_cell(0, 2);
							my $template_75_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_75_cell_1 and $template_75_cell_2 and $template_75_cell_3 and $template_75_cell_4){
								my $value1 = clean_string($template_75_cell_1->Value);
								my $value2 = clean_string($template_75_cell_2->Value);
								my $value3 = clean_string($template_75_cell_3->Value);
								my $value4 = clean_string($template_75_cell_4->Value);
								if(($value1 eq "Num") and ($value2 eq "Vox1") and ($value3 eq "Vox2") and ($value4 eq "Id")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t75.pl $file");	
								}
							}
=end COMMENT
=cut							
							#TEMPLATE 76 (ok)
							my $template_76_cell_1 = $worksheet->get_cell(10, 0);
							my $template_76_cell_2 = $worksheet->get_cell(10, 1);
							my $template_76_cell_3 = $worksheet->get_cell(10, 2);
							my $template_76_cell_4 = $worksheet->get_cell(10, 3);
							
							if($template_76_cell_1 and $template_76_cell_2 and $template_76_cell_3 and $template_76_cell_4){
								my $value1 = clean_string($template_76_cell_1->Value);
								my $value2 = clean_string($template_76_cell_2->Value);
								my $value3 = clean_string($template_76_cell_3->Value);
								my $value4 = clean_string($template_76_cell_4->Value);
								if(($value1 eq "Nr crt.") and ($value2 eq "Data") and ($value3 eq "Spatiu emisie") and ($value4 eq "Minute")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T76"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t76.pl $file");	
								}
							}
							
							#TEMPLATE 77 (ok)
							my $template_77_cell_1 = $worksheet->get_cell(0, 0);
							my $template_77_cell_2 = $worksheet->get_cell(0, 1);
							my $template_77_cell_3 = $worksheet->get_cell(0, 2);
							my $template_77_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_77_cell_1 and $template_77_cell_2 and $template_77_cell_3 and $template_77_cell_4){
								my $value1 = clean_string($template_77_cell_1->Value);
								my $value2 = clean_string($template_77_cell_2->Value);
								my $value3 = clean_string($template_77_cell_3->Value);
								my $value4 = clean_string($template_77_cell_4->Value);
								if(($value1 eq "Data Difuzare") and ($value2 eq "Ora Difuzare") and ($value3 eq "Minute Difuzate") and ($value4 eq "Secunde Difuzate")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T77"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t77.pl $file");	
								}
							}
							
							#TEMPLATE 78 (ok)
							my $template_78_cell_1 = $worksheet->get_cell(15, 0);
							my $template_78_cell_2 = $worksheet->get_cell(15, 1);
							my $template_78_cell_3 = $worksheet->get_cell(15, 2);
							my $template_78_cell_4 = $worksheet->get_cell(15, 3);
							
							if($template_78_cell_1 and $template_78_cell_2 and $template_78_cell_3 and $template_78_cell_4){
								my $value1 = clean_string($template_78_cell_1->Value);
								my $value2 = clean_string($template_78_cell_2->Value);
								my $value3 = clean_string($template_78_cell_3->Value);
								my $value4 = clean_string($template_78_cell_4->Value);
								if(($value1 eq "Data Difuzare") and ($value2 eq "Ora Difuzare") and ($value3 eq "Minute Difuzate") and ($value4 eq "Sec. Dif.")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T78"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t78.pl $file");	
								}
							}
							
							#TEMPLATE 79 (ok)
							my $template_79_cell_1 = $worksheet->get_cell(4, 1);
							my $template_79_cell_2 = $worksheet->get_cell(4, 2);
							my $template_79_cell_3 = $worksheet->get_cell(4, 3);
							my $template_79_cell_4 = $worksheet->get_cell(4, 4);
							
							if($template_79_cell_1 and $template_79_cell_2 and $template_79_cell_3 and $template_79_cell_4){
								my $value1 = clean_string($template_79_cell_1->Value);
								my $value2 = clean_string($template_79_cell_2->Value);
								my $value3 = clean_string($template_79_cell_3->Value);
								my $value4 = clean_string($template_79_cell_4->Value);
								if(($value1 eq "TITLU") and ($value2 eq "COMPOZITOR / TEXTIER") and ($value3 eq "ARTIST") and ($value4 eq "LABEL")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T79"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t79.pl $file");	
								}
							}
							
							#TEMPLATE 80 (ok)
							my $template_80_cell_1 = $worksheet->get_cell(13, 1);
							my $template_80_cell_2 = $worksheet->get_cell(13, 2);
							my $template_80_cell_3 = $worksheet->get_cell(13, 3);
							my $template_80_cell_4 = $worksheet->get_cell(13, 4);
							
							if($template_80_cell_1 and $template_80_cell_2 and $template_80_cell_3 and $template_80_cell_4){
								my $value1 = clean_string($template_80_cell_1->Value);
								my $value2 = clean_string($template_80_cell_2->Value);
								my $value3 = clean_string($template_80_cell_3->Value);
								my $value4 = clean_string($template_80_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Interpret") and ($value4 eq "Titlu")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T80"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t80.pl $file");	
								}
							}
							
							#TEMPLATE 81 (ok)
							my $template_81_cell_1 = $worksheet->get_cell(0, 0);
							my $template_81_cell_2 = $worksheet->get_cell(0, 1);
							my $template_81_cell_3 = $worksheet->get_cell(0, 2);
							my $template_81_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_81_cell_1 and $template_81_cell_2 and $template_81_cell_3 and $template_81_cell_4){
								my $value1 = clean_string($template_81_cell_1->Value);
								my $value2 = clean_string($template_81_cell_2->Value);
								my $value3 = clean_string($template_81_cell_3->Value);
								my $value4 = clean_string($template_81_cell_4->Value);
								if(($value1 eq "Data difuzarii") and ($value2 eq "Ora difuzarii") and ($value3 eq "Minute difuzate") and ($value4 eq "Secunde difuzate")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T81"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t81.pl $file");	
								}
							}
							
							#TEMPLATE 82 (ok)
							my $template_82_cell_1 = $worksheet->get_cell(0, 0);
							my $template_82_cell_2 = $worksheet->get_cell(0, 1);
							my $template_82_cell_3 = $worksheet->get_cell(0, 2);
							my $template_82_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_82_cell_1 and $template_82_cell_2 and $template_82_cell_3 and $template_82_cell_4){
								my $value1 = clean_string($template_82_cell_1->Value);
								my $value2 = clean_string($template_82_cell_2->Value);
								my $value3 = clean_string($template_82_cell_3->Value);
								my $value4 = clean_string($template_82_cell_4->Value);
								if(($value1 eq "No") and ($value2 eq "Data") and ($value3 eq "Durata difuzarii (sec)") and ($value4 eq "title")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T82"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t82.pl $file");	
								}
							}
							
							#TEMPLATE 83 (ok)
							my $template_83_cell_1 = $worksheet->get_cell(0, 0);
							my $template_83_cell_2 = $worksheet->get_cell(0, 1);
							my $template_83_cell_3 = $worksheet->get_cell(0, 2);
							my $template_83_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_83_cell_1 and $template_83_cell_2 and $template_83_cell_3 and $template_83_cell_4){
								my $value1 = clean_string($template_83_cell_1->Value);
								my $value2 = clean_string($template_83_cell_2->Value);
								my $value3 = clean_string($template_83_cell_3->Value);
								my $value4 = clean_string($template_83_cell_4->Value);
								if(($value1 eq "No") and ($value2 eq "Data") and ($value3 eq "Durata") and ($value4 eq "Title")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T83"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t83.pl $file");	
								}
							}
=begin COMMENTS							
							#TEMPLATE 84
							my $template_84_cell_1 = $worksheet->get_cell(1, 0);
							my $template_84_cell_2 = $worksheet->get_cell(1, 1);
							my $template_84_cell_3 = $worksheet->get_cell(1, 2);
							my $template_84_cell_4 = $worksheet->get_cell(1, 3);
							
							if($template_84_cell_1 and $template_84_cell_2 and $template_84_cell_3 and $template_84_cell_4){
								my $value1 = clean_string($template_84_cell_1->Value);
								my $value2 = clean_string($template_84_cell_2->Value);
								my $value3 = clean_string($template_84_cell_3->Value);
								my $value4 = clean_string($template_84_cell_4->Value);
								if(($value1 eq "Titlu") and ($value2 eq "Minute") and ($value3 eq "Secunde") and ($value4 eq "Difuzari")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t84.pl $file");	
								}
							}
=end COMMENT
=end COMMENT
=cut							
							#TEMPLATE 85 (ok)
							my $template_85_cell_1 = $worksheet->get_cell(0, 0);
							my $template_85_cell_2 = $worksheet->get_cell(0, 1);
							my $template_85_cell_3 = $worksheet->get_cell(0, 2);
							my $template_85_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_85_cell_1 and $template_85_cell_2 and $template_85_cell_3 and $template_85_cell_4){
								my $value1 = clean_string($template_85_cell_1->Value);
								my $value2 = clean_string($template_85_cell_2->Value);
								my $value3 = clean_string($template_85_cell_3->Value);
								my $value4 = clean_string($template_85_cell_4->Value);
								if(($value1 eq "Artist / Grup") and ($value2 eq "Melodie") and ($value3 eq "tara") and ($value4 eq "Min.")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T85"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t85.pl $file");	
								}
							}
=begin COMMENTS							
							#TEMPLATE 86
							my $template_86_cell_1 = $worksheet->get_cell(5, 0);
							my $template_86_cell_2 = $worksheet->get_cell(5, 1);
							my $template_86_cell_3 = $worksheet->get_cell(5, 2);
							my $template_86_cell_4 = $worksheet->get_cell(5, 3);
							
							if($template_86_cell_1 and $template_86_cell_2 and $template_86_cell_3 and $template_86_cell_4){
								my $value1 = clean_string($template_86_cell_1->Value);
								my $value2 = clean_string($template_86_cell_2->Value);
								my $value3 = clean_string($template_86_cell_3->Value);
								my $value4 = clean_string($template_86_cell_4->Value);
								if(($value1 eq "NR. CRT.") and ($value2 eq "DATA DIFUZARII") and ($value3 eq "ORA DIFUZARII") and ($value4 eq "MINUTE")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t86.pl $file");	
								}
							}
=end COMMENT
=cut							
							#TEMPLATE 87 (ok)
							my $template_87_cell_1 = $worksheet->get_cell(8, 0);
							my $template_87_cell_2 = $worksheet->get_cell(8, 1);
							my $template_87_cell_3 = $worksheet->get_cell(8, 2);
							my $template_87_cell_4 = $worksheet->get_cell(8, 3);
							
							if($template_87_cell_1 and $template_87_cell_2 and $template_87_cell_3 and $template_87_cell_4){
								my $value1 = clean_string($template_87_cell_1->Value);
								my $value2 = clean_string($template_87_cell_2->Value);
								my $value3 = clean_string($template_87_cell_3->Value);
								my $value4 = clean_string($template_87_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Emisiune") and ($value3 eq "Spatiu emisie") and ($value4 eq "Titlu")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T87"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t87.pl $file");	
								}
							}
=begin COMMENTS							
							#TEMPLATE 88
							my $template_88_cell_1 = $worksheet->get_cell(0, 0);
							my $template_88_cell_2 = $worksheet->get_cell(0, 1);
							my $template_88_cell_3 = $worksheet->get_cell(0, 2);
							my $template_88_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_88_cell_1 and $template_88_cell_2 and $template_88_cell_3 and $template_88_cell_4){
								my $value1 = clean_string($template_88_cell_1->Value);
								my $value2 = clean_string($template_88_cell_2->Value);
								my $value3 = clean_string($template_88_cell_3->Value);
								my $value4 = clean_string($template_88_cell_4->Value);
								if(($value1 eq "DATA DIFUZARII") and ($value2 eq "NUMELE EMISIUNII") and ($value3 eq "ORA DIFUZARII") and ($value4 eq "MINUTE DIFUZATE")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t88.pl $file");	
								}
							}
							
							#TEMPLATE 89
							my $template_89_cell_1 = $worksheet->get_cell(7, 0);
							my $template_89_cell_2 = $worksheet->get_cell(7, 1);
							my $template_89_cell_3 = $worksheet->get_cell(7, 2);
							my $template_89_cell_4 = $worksheet->get_cell(7, 3);
							
							if($template_89_cell_1 and $template_89_cell_2 and $template_89_cell_3 and $template_89_cell_4){
								my $value1 = clean_string($template_89_cell_1->Value);
								my $value2 = clean_string($template_89_cell_2->Value);
								my $value3 = clean_string($template_89_cell_3->Value);
								my $value4 = clean_string($template_89_cell_4->Value);
								if(($value1 eq "Nr crt") and ($value2 eq "Data difuzarii") and ($value3 eq "Ora difuzarii") and ($value4 eq "Minute difuzate")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t89.pl $file");	
								}
							}
							
							#TEMPLATE 90 
							my $template_90_cell_1 = $worksheet->get_cell(0, 0);
							my $template_90_cell_2 = $worksheet->get_cell(0, 1);
							my $template_90_cell_3 = $worksheet->get_cell(0, 2);
							my $template_90_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_90_cell_1 and $template_90_cell_2 and $template_90_cell_3 and $template_90_cell_4){
								my $value1 = clean_string($template_90_cell_1->Value);
								my $value2 = clean_string($template_90_cell_2->Value);
								my $value3 = clean_string($template_90_cell_3->Value);
								my $value4 = clean_string($template_90_cell_4->Value);
								if(($value1 eq "MELODIE - INTERPRET") and ($value2 eq "DURATA") and ($value3 eq "NR. DIFUZARI") and ($value4 eq "MINUTAJ")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t90.pl $file");	
								}
							}
							
							#TEMPLATE 91
							my $template_91_cell_1 = $worksheet->get_cell(0, 0);
							my $template_91_cell_2 = $worksheet->get_cell(0, 1);
							my $template_91_cell_3 = $worksheet->get_cell(0, 2);
							my $template_91_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_91_cell_1 and $template_91_cell_2 and $template_91_cell_3 and $template_91_cell_4){
								my $value1 = clean_string($template_91_cell_1->Value);
								my $value2 = clean_string($template_91_cell_2->Value);
								my $value3 = clean_string($template_91_cell_3->Value);
								my $value4 = clean_string($template_91_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Per difuzarii") and ($value3 eq "Titlul melodiei") and ($value4 eq "Cantaret")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t91.pl $file");	
								}
							}
=end COMMENTS
=cut							
							#TEMPLATE 92 (ok)
							my $template_92_cell_1 = $worksheet->get_cell(0, 0);
							my $template_92_cell_2 = $worksheet->get_cell(0, 1);
							my $template_92_cell_3 = $worksheet->get_cell(0, 2);
							my $template_92_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_92_cell_1 and $template_92_cell_2 and $template_92_cell_3 and $template_92_cell_4){
								my $value1 = clean_string($template_92_cell_1->Value);
								my $value2 = clean_string($template_92_cell_2->Value);
								my $value3 = clean_string($template_92_cell_3->Value);
								my $value4 = clean_string($template_92_cell_4->Value);
								if(($value1 eq "Data difuzarii") and ($value2 eq "Ora difuzarii") and ($value3 eq "Min.") and ($value4 eq "Sec.")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T92"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t92.pl $file");	
								}
							}
=begin COMMENTS							
							#TEMPLATE 93
							my $template_93_cell_1 = $worksheet->get_cell(0, 0);
							my $template_93_cell_2 = $worksheet->get_cell(0, 1);
							my $template_93_cell_3 = $worksheet->get_cell(0, 2);
							my $template_93_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_93_cell_1 and $template_93_cell_2 and $template_93_cell_3 and $template_93_cell_4){
								my $value1 = clean_string($template_93_cell_1->Value);
								my $value2 = clean_string($template_93_cell_2->Value);
								my $value3 = clean_string($template_93_cell_3->Value);
								my $value4 = clean_string($template_93_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Ora difuzarii") and ($value4 eq "Minute difuzate")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t93.pl $file");	
								}
							}
=end COMMENTS
=cut							
							#TEMPLATE 94 (ok)
							my $template_94_cell_1 = $worksheet->get_cell(10, 0);
							my $template_94_cell_2 = $worksheet->get_cell(10, 1);
							my $template_94_cell_3 = $worksheet->get_cell(10, 2);
							my $template_94_cell_4 = $worksheet->get_cell(10, 3);
							
							if($template_94_cell_1 and $template_94_cell_2 and $template_94_cell_3 and $template_94_cell_4){
								my $value1 = clean_string($template_94_cell_1->Value);
								my $value2 = clean_string($template_94_cell_2->Value);
								my $value3 = clean_string($template_94_cell_3->Value);
								my $value4 = clean_string($template_94_cell_4->Value);
								if(($value1 eq "Ziua") and ($value2 eq "Spatiu orar") and ($value3 eq "Min.") and ($value4 eq "Sec.")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T94"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t94.pl $file");	
								}
							}
=begin COMMENTS							
							#TEMPLATE 95
							my $template_95_cell_1 = $worksheet->get_cell(8, 0);
							my $template_95_cell_2 = $worksheet->get_cell(8, 1);
							my $template_95_cell_3 = $worksheet->get_cell(8, 2);
							my $template_95_cell_4 = $worksheet->get_cell(8, 3);
							
							if($template_95_cell_1 and $template_95_cell_2 and $template_95_cell_3 and $template_95_cell_4){
								my $value1 = clean_string($template_95_cell_1->Value);
								my $value2 = clean_string($template_95_cell_2->Value);
								my $value3 = clean_string($template_95_cell_3->Value);
								my $value4 = clean_string($template_95_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Interval orar") and ($value3 eq "Emisiune") and ($value4 eq "Interpret")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t95.pl $file");	
								}
							}
=end COMMENTS
=cut							
							#TEMPLATE 96 (ok)
							my $template_96_cell_1 = $worksheet->get_cell(15, 0);
							my $template_96_cell_2 = $worksheet->get_cell(15, 1);
							my $template_96_cell_3 = $worksheet->get_cell(15, 2);
							my $template_96_cell_4 = $worksheet->get_cell(15, 3);
							
							if($template_96_cell_1 and $template_96_cell_2 and $template_96_cell_3 and $template_96_cell_4){
								my $value1 = clean_string($template_96_cell_1->Value);
								my $value2 = clean_string($template_96_cell_2->Value);
								my $value3 = clean_string($template_96_cell_3->Value);
								my $value4 = clean_string($template_96_cell_4->Value);
								if(($value1 eq "Nr.crt.") and ($value2 eq "Data radiodifuzarii") and ($value3 eq "Ora") and ($value4 eq "Durata film (Secunde)")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T96"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t96.pl $file");	
								}
							}
							
							#TEMPLATE 97 (ok)
							my $template_97_cell_1 = $worksheet->get_cell(13, 0);
							my $template_97_cell_2 = $worksheet->get_cell(13, 1);
							my $template_97_cell_3 = $worksheet->get_cell(13, 2);
							my $template_97_cell_4 = $worksheet->get_cell(13, 3);
							
							if($template_97_cell_1 and $template_97_cell_2 and $template_97_cell_3 and $template_97_cell_4){
								my $value1 = clean_string($template_97_cell_1->Value);
								my $value2 = clean_string($template_97_cell_2->Value);
								my $value3 = clean_string($template_97_cell_3->Value);
								my $value4 = clean_string($template_97_cell_4->Value);
								if(($value1 eq "Nr.crt.") and ($value2 eq "Data radiodifuzarii") and ($value3 eq "Ora") and ($value4 eq "Durata film (Secunde)")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T97"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t97.pl $file");	
								}
							}
							
							#TEMPLATE 98 (ok)
							my $template_98_cell_1 = $worksheet->get_cell(12, 0);
							my $template_98_cell_2 = $worksheet->get_cell(12, 1);
							my $template_98_cell_3 = $worksheet->get_cell(12, 2);
							my $template_98_cell_4 = $worksheet->get_cell(12, 3);
							
							if($template_98_cell_1 and $template_98_cell_2 and $template_98_cell_3 and $template_98_cell_4){
								my $value1 = clean_string($template_98_cell_1->Value);
								my $value2 = clean_string($template_98_cell_2->Value);
								my $value3 = clean_string($template_98_cell_3->Value);
								my $value4 = clean_string($template_98_cell_4->Value);
								if(($value1 eq "Nr.crt.") and ($value2 eq "Data radiodifuzarii") and ($value3 eq "Ora") and ($value4 eq "Durata film (Secunde)")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T98"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t98.pl $file");	
								}
							}
							 
							#TEMPLATE 99 (ok)
							my $template_99_cell_1 = $worksheet->get_cell(10, 0);
							my $template_99_cell_2 = $worksheet->get_cell(10, 1);
							my $template_99_cell_3 = $worksheet->get_cell(10, 2);
							my $template_99_cell_4 = $worksheet->get_cell(10, 3);
							
							if($template_99_cell_1 and $template_99_cell_2 and $template_99_cell_3 and $template_99_cell_4){
								my $value1 = clean_string($template_99_cell_1->Value);
								my $value2 = clean_string($template_99_cell_2->Value);
								my $value3 = clean_string($template_99_cell_3->Value);
								my $value4 = clean_string($template_99_cell_4->Value);
								if(($value1 eq "Nr.crt.") and ($value2 eq "Data radiodifuzarii") and ($value3 eq "Ora") and ($value4 eq "Durata film (Secunde)")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T99"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t99.pl $file");	
								}
							}
							
							#TEMPLATE 100 (ok)
							my $template_100_cell_1 = $worksheet->get_cell(1, 1);
							my $template_100_cell_2 = $worksheet->get_cell(1, 2);
							my $template_100_cell_3 = $worksheet->get_cell(1, 3);
							my $template_100_cell_4 = $worksheet->get_cell(1, 4);
							
							if($template_100_cell_1 and $template_100_cell_2 and $template_100_cell_3 and $template_100_cell_4){
								my $value1 = clean_string($template_100_cell_1->Value);
								my $value2 = clean_string($template_100_cell_2->Value);
								my $value3 = clean_string($template_100_cell_3->Value);
								my $value4 = clean_string($template_100_cell_4->Value);
								if(($value1 eq "Ziua") and ($value2 eq "Ora") and ($value3 eq "Minute") and ($value4 eq "Secunde")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T100"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t100.pl $file");	
								}
							}
							
							#TEMPLATE 101 (ok)
							my $template_101_cell_1 = $worksheet->get_cell(8, 0);
							my $template_101_cell_2 = $worksheet->get_cell(8, 1);
							my $template_101_cell_3 = $worksheet->get_cell(8, 2);
							my $template_101_cell_4 = $worksheet->get_cell(8, 3);
							
							if($template_101_cell_1 and $template_101_cell_2 and $template_101_cell_3 and $template_101_cell_4){
								my $value1 = clean_string($template_101_cell_1->Value);
								my $value2 = clean_string($template_101_cell_2->Value);
								my $value3 = clean_string($template_101_cell_3->Value);
								my $value4 = clean_string($template_101_cell_4->Value);
								if(($value1 eq "Day") and ($value2 eq "Hour") and ($value3 eq "Min") and ($value4 eq "Sec")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T101"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t101.pl $file");	
								}
							}
							
							#TEMPLATE 102 (ok)
							my $template_102_cell_1 = $worksheet->get_cell(0, 0);
							my $template_102_cell_2 = $worksheet->get_cell(0, 1);
							my $template_102_cell_3 = $worksheet->get_cell(0, 2);
							my $template_102_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_102_cell_1 and $template_102_cell_2 and $template_102_cell_3 and $template_102_cell_4){
								my $value1 = clean_string($template_102_cell_1->Value);
								my $value2 = clean_string($template_102_cell_2->Value);
								my $value3 = clean_string($template_102_cell_3->Value);
								my $value4 = clean_string($template_102_cell_4->Value);
								if(($value1 eq "Day") and ($value2 eq "Hour") and ($value3 eq "Min") and ($value4 eq "Sec")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T102"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t102.pl $file");	
								}
							}
=begin COMMENTS							
							#TEMPLATE 103
							my $template_103_cell_1 = $worksheet->get_cell(14, 0);
							my $template_103_cell_2 = $worksheet->get_cell(14, 1);
							my $template_103_cell_3 = $worksheet->get_cell(14, 2);
							my $template_103_cell_4 = $worksheet->get_cell(14, 3);
							
							if($template_103_cell_1 and $template_103_cell_2 and $template_103_cell_3 and $template_103_cell_4){
								my $value1 = clean_string($template_103_cell_1->Value);
								my $value2 = clean_string($template_103_cell_2->Value);
								my $value3 = clean_string($template_103_cell_3->Value);
								my $value4 = clean_string($template_103_cell_4->Value);
								if(($value1 eq "Nume interpret") and ($value2 eq "Titlul Piesei") and ($value3 eq "Durata (min)") and ($value4 eq "Casa de productie")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t103.pl $file");	
								}
							}
							
							#TEMPLATE 104
							my $template_104_cell_1 = $worksheet->get_cell(2, 4);
							my $template_104_cell_2 = $worksheet->get_cell(2, 6);
							my $template_104_cell_3 = $worksheet->get_cell(2, 7);
							my $template_104_cell_4 = $worksheet->get_cell(2, 9);
							
							if($template_104_cell_1 and $template_104_cell_2 and $template_104_cell_3 and $template_104_cell_4){
								my $value1 = clean_string($template_104_cell_1->Value);
								my $value2 = clean_string($template_104_cell_2->Value);
								my $value3 = clean_string($template_104_cell_3->Value);
								my $value4 = clean_string($template_104_cell_4->Value);
								if(($value1 eq "Titlu piesa") and ($value2 eq "Artist") and ($value3 eq "Orchestra Formatie") and ($value4 eq "Album")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t104.pl $file");	
								}
							}
							
							#TEMPLATE 105
							my $template_105_cell_1 = $worksheet->get_cell(0, 0);
							my $template_105_cell_2 = $worksheet->get_cell(0, 1);
							my $template_105_cell_3 = $worksheet->get_cell(0, 2);
							my $template_105_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_105_cell_1 and $template_105_cell_2 and $template_105_cell_3 and $template_105_cell_4){
								my $value1 = clean_string($template_105_cell_1->Value);
								my $value2 = clean_string($template_105_cell_2->Value);
								my $value3 = clean_string($template_105_cell_3->Value);
								my $value4 = clean_string($template_105_cell_4->Value);
								if(($value1 eq "Saptiu emisie") and ($value2 eq "Min") and ($value3 eq "Sec") and ($value4 eq "Cod inreg")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t105.pl $file");	
								}
							}
							
							#TEMPLATE 106
							my $template_106_cell_1 = $worksheet->get_cell(1, 0);
							my $template_106_cell_2 = $worksheet->get_cell(1, 1);
							my $template_106_cell_3 = $worksheet->get_cell(1, 2);
							my $template_106_cell_4 = $worksheet->get_cell(1, 3);
							
							if($template_106_cell_1 and $template_106_cell_2 and $template_106_cell_3 and $template_106_cell_4){
								my $value1 = clean_string($template_106_cell_1->Value);
								my $value2 = clean_string($template_106_cell_2->Value);
								my $value3 = clean_string($template_106_cell_3->Value);
								my $value4 = clean_string($template_106_cell_4->Value);
								if(($value1 eq "DATA") and ($value2 eq "ORA DIFUZARE") and ($value3 eq "MINUTE") and ($value4 eq "SECUNDE")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t106.pl $file");	
								}
							}
							
							#TEMPLATE 107
							my $template_107_cell_1 = $worksheet->get_cell(0, 0);
							my $template_107_cell_2 = $worksheet->get_cell(0, 1);
							my $template_107_cell_3 = $worksheet->get_cell(0, 2);
							my $template_107_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_107_cell_1 and $template_107_cell_2 and $template_107_cell_3 and $template_107_cell_4){
								my $value1 = clean_string($template_107_cell_1->Value);
								my $value2 = clean_string($template_107_cell_2->Value);
								my $value3 = clean_string($template_107_cell_3->Value);
								my $value4 = clean_string($template_107_cell_4->Value);
								if(($value1 eq "Nr. crt.") and ($value2 eq "Data difuzare") and ($value3 eq "Ora difuzare") and ($value4 eq "Minute difuzate")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t107.pl $file");	
								}
							}
							
							#TEMPLATE 108
							my $template_108_cell_1 = $worksheet->get_cell(0, 0);
							my $template_108_cell_2 = $worksheet->get_cell(0, 1);
							my $template_108_cell_3 = $worksheet->get_cell(0, 2);
							my $template_108_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_108_cell_1 and $template_108_cell_2 and $template_108_cell_3 and $template_108_cell_4){
								my $value1 = clean_string($template_108_cell_1->Value);
								my $value2 = clean_string($template_108_cell_2->Value);
								my $value3 = clean_string($template_108_cell_3->Value);
								my $value4 = clean_string($template_108_cell_4->Value);
								if(($value1 eq "Gen piesa") and ($value2 eq "Autor") and ($value3 eq "Interpret") and ($value4 eq "Orchestra")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t108.pl $file");	
								}
							}
							
							#TEMPLATE 109
							my $template_109_cell_1 = $worksheet->get_cell(0, 0);
							my $template_109_cell_2 = $worksheet->get_cell(0, 1);
							my $template_109_cell_3 = $worksheet->get_cell(0, 2);
							my $template_109_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_109_cell_1 and $template_109_cell_2 and $template_109_cell_3 and $template_109_cell_4){
								my $value1 = clean_string($template_109_cell_1->Value);
								my $value2 = clean_string($template_109_cell_2->Value);
								my $value3 = clean_string($template_109_cell_3->Value);
								my $value4 = clean_string($template_109_cell_4->Value);
								if(($value1 eq "Titlu") and ($value2 eq "Gen piesa") and ($value3 eq "Autor") and ($value4 eq "Interpret")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t109.pl $file");	
								}
							}
							
							#TEMPLATE 110
							my $template_110_cell_1 = $worksheet->get_cell(13, 1);
							my $template_110_cell_2 = $worksheet->get_cell(13, 2);
							my $template_110_cell_3 = $worksheet->get_cell(13, 3);
							my $template_110_cell_4 = $worksheet->get_cell(13, 4);
							
							if($template_110_cell_1 and $template_110_cell_2 and $template_110_cell_3 and $template_110_cell_4){
								my $value1 = clean_string($template_110_cell_1->Value);
								my $value2 = clean_string($template_110_cell_2->Value);
								my $value3 = clean_string($template_110_cell_3->Value);
								my $value4 = clean_string($template_110_cell_4->Value);
								if(($value1 eq "denumire fonograma") and ($value2 eq "interpret fonograma") and ($value3 eq "difuzari/") and ($value4 eq "difuzare/")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t110.pl $file");	
								}
							}
						
							#TEMPLATE 111
							my $template_111_cell_1 = $worksheet->get_cell(8, 0);
							my $template_111_cell_2 = $worksheet->get_cell(8, 1);
							my $template_111_cell_3 = $worksheet->get_cell(8, 2);
							my $template_111_cell_4 = $worksheet->get_cell(8, 3);
							
							if($template_111_cell_1 and $template_111_cell_2 and $template_111_cell_3 and $template_111_cell_4){
								my $value1 = clean_string($template_111_cell_1->Value);
								my $value2 = clean_string($template_111_cell_2->Value);
								my $value3 = clean_string($template_111_cell_3->Value);
								my $value4 = clean_string($template_111_cell_4->Value);
								if(($value1 eq "luna") and ($value2 eq "Radiodifuzor") and ($value3 eq "Titlu&Interpret") and ($value4 eq "Gen piesa")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t111.pl $file");	
								}
							}
							
							#TEMPLATE 112
							my $template_112_cell_1 = $worksheet->get_cell(1, 1);
							my $template_112_cell_2 = $worksheet->get_cell(1, 2);
							my $template_112_cell_3 = $worksheet->get_cell(1, 3);
							my $template_112_cell_4 = $worksheet->get_cell(1, 4);
							
							if($template_112_cell_1 and $template_112_cell_2 and $template_112_cell_3 and $template_112_cell_4){
								my $value1 = clean_string($template_112_cell_1->Value);
								my $value2 = clean_string($template_112_cell_2->Value);
								my $value3 = clean_string($template_112_cell_3->Value);
								my $value4 = clean_string($template_112_cell_4->Value);
								if(($value1 eq "Artist") and ($value2 eq "Titlu") and ($value3 eq "Durata") and ($value4 eq "Difuzari")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t112.pl $file");	
								}
							}

							#TEMPLATE 113
							my $template_113_cell_1 = $worksheet->get_cell(0, 0);
							my $template_113_cell_2 = $worksheet->get_cell(0, 1);
							my $template_113_cell_3 = $worksheet->get_cell(0, 2);
							my $template_113_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_113_cell_1 and $template_113_cell_2 and $template_113_cell_3 and $template_113_cell_4){
								my $value1 = clean_string($template_113_cell_1->Value);
								my $value2 = clean_string($template_113_cell_2->Value);
								my $value3 = clean_string($template_113_cell_3->Value);
								my $value4 = clean_string($template_113_cell_4->Value);
								if(($value1 eq "Campaign") and ($value2 eq "Channel") and ($value3 eq "Date") and ($value4 eq "Start time")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t113.pl $file");	
								}
							}
=end COMMENTS
=cut
							#TEMPLATE 114 (ok)
							my $template_114_cell_1 = $worksheet->get_cell(8, 2);
							my $template_114_cell_2 = $worksheet->get_cell(8, 3);
							my $template_114_cell_3 = $worksheet->get_cell(8, 4);
							my $template_114_cell_4 = $worksheet->get_cell(8, 5);
							
							if($template_114_cell_1 and $template_114_cell_2 and $template_114_cell_3 and $template_114_cell_4){
								my $value1 = clean_string($template_114_cell_1->Value);
								my $value2 = clean_string($template_114_cell_2->Value);
								my $value3 = clean_string($template_114_cell_3->Value);
								my $value4 = clean_string($template_114_cell_4->Value);
								if(($value1 eq "Nr. crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Ora difuzarii") and ($value4 eq "Spatiu emisie")){
									my $insert = $mango->db('unart_parsing')->collection('matched_files')->insert({ "FILE" => $file, "real_path" => realpath($file), "template" => "T114"});
									system("perl /var/perl-scripts/PERL/UNART/templates/t114.pl $file");	
								}
							}
=begin							
							#TEMPLATE 115
							my $template_115_cell_1 = $worksheet->get_cell(8, 2);
							my $template_115_cell_2 = $worksheet->get_cell(8, 3);
							my $template_115_cell_3 = $worksheet->get_cell(8, 4);
							my $template_115_cell_4 = $worksheet->get_cell(8, 5);
							
							if($template_115_cell_1 and $template_115_cell_2 and $template_115_cell_3 and $template_115_cell_4){
								my $value1 = clean_string($template_115_cell_1->Value);
								my $value2 = clean_string($template_115_cell_2->Value);
								my $value3 = clean_string($template_115_cell_3->Value);
								my $value4 = clean_string($template_115_cell_4->Value);
								if(($value1 eq "Nr. crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Ora difuzarii") and ($value4 eq "Spatiu emisie")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t115.pl $file");	
								}
							}
							
							#TEMPLATE 116
							my $template_116_cell_1 = $worksheet->get_cell(9, 2);
							my $template_116_cell_2 = $worksheet->get_cell(9, 3);
							my $template_116_cell_3 = $worksheet->get_cell(9, 4);
							my $template_116_cell_4 = $worksheet->get_cell(9, 5);
							
							if($template_116_cell_1 and $template_116_cell_2 and $template_116_cell_3 and $template_116_cell_4){
								my $value1 = clean_string($template_116_cell_1->Value);
								my $value2 = clean_string($template_116_cell_2->Value);
								my $value3 = clean_string($template_116_cell_3->Value);
								my $value4 = clean_string($template_116_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Denumire opera muzicala") and ($value4 eq "Interpret")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t116.pl $file");	
								}
							}
							
							#TEMPLATE 117
							my $template_117_cell_1 = $worksheet->get_cell(13, 0);
							my $template_117_cell_2 = $worksheet->get_cell(13, 1);
							my $template_117_cell_3 = $worksheet->get_cell(13, 2);
							my $template_117_cell_4 = $worksheet->get_cell(13, 3);
							
							if($template_117_cell_1 and $template_117_cell_2 and $template_117_cell_3 and $template_117_cell_4){
								my $value1 = clean_string($template_117_cell_1->Value);
								my $value2 = clean_string($template_117_cell_2->Value);
								my $value3 = clean_string($template_117_cell_3->Value);
								my $value4 = clean_string($template_117_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Interpret") and ($value4 eq "Titlu")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t117.pl $file");	
								}
							}
							
							#TEMPLATE 118
							my $template_118_cell_1 = $worksheet->get_cell(0, 4);
							my $template_118_cell_2 = $worksheet->get_cell(0, 5);
							my $template_118_cell_3 = $worksheet->get_cell(0, 6);
							my $template_118_cell_4 = $worksheet->get_cell(0, 7);
							
							if($template_118_cell_1 and $template_118_cell_2 and $template_118_cell_3 and $template_118_cell_4){
								my $value1 = clean_string($template_118_cell_1->Value);
								my $value2 = clean_string($template_118_cell_2->Value);
								my $value3 = clean_string($template_118_cell_3->Value);
								my $value4 = clean_string($template_118_cell_4->Value);
								if(($value1 eq "Executii") and ($value2 eq "Denumirea operelor muzicale difuzate in cadrul programului") and ($value3 eq "Autor muzica") and ($value4 eq "Interpret")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t118.pl $file");	
								}
							}
							
							#TEMPLATE 119
							my $template_119_cell_1 = $worksheet->get_cell(9, 1);
							my $template_119_cell_2 = $worksheet->get_cell(9, 2);
							my $template_119_cell_3 = $worksheet->get_cell(9, 3);
							my $template_119_cell_4 = $worksheet->get_cell(9, 4);
							
							if($template_119_cell_1 and $template_119_cell_2 and $template_119_cell_3 and $template_119_cell_4){
								my $value1 = clean_string($template_119_cell_1->Value);
								my $value2 = clean_string($template_119_cell_2->Value);
								my $value3 = clean_string($template_119_cell_3->Value);
								my $value4 = clean_string($template_119_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Sp. Emisie") and ($value4 eq "Titlu piesa")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t119.pl $file");	
								}
							}
							
							#TEMPLATE 120
							my $template_120_cell_1 = $worksheet->get_cell(0, 0);
							my $template_120_cell_2 = $worksheet->get_cell(0, 1);
							my $template_120_cell_3 = $worksheet->get_cell(0, 2);
							my $template_120_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_120_cell_1 and $template_120_cell_2 and $template_120_cell_3 and $template_120_cell_4){
								my $value1 = clean_string($template_120_cell_1->Value);
								my $value2 = clean_string($template_120_cell_2->Value);
								my $value3 = clean_string($template_120_cell_3->Value);
								my $value4 = clean_string($template_120_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Durata (min)") and ($value4 eq "Durata (sec)")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t120.pl $file");	
								}
							}
							
							#TEMPLATE 121
							my $template_121_cell_1 = $worksheet->get_cell(10, 0);
							my $template_121_cell_2 = $worksheet->get_cell(10, 1);
							my $template_121_cell_3 = $worksheet->get_cell(10, 2);
							my $template_121_cell_4 = $worksheet->get_cell(10, 3);
							
							if($template_121_cell_1 and $template_121_cell_2 and $template_121_cell_3 and $template_121_cell_4){
								my $value1 = clean_string($template_121_cell_1->Value);
								my $value2 = clean_string($template_121_cell_2->Value);
								my $value3 = clean_string($template_121_cell_3->Value);
								my $value4 = clean_string($template_121_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Minute") and ($value4 eq "Sec.")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t121.pl $file");	
								}
							}
							
							#TEMPLATE 122
							my $template_122_cell_1 = $worksheet->get_cell(1, 0);
							my $template_122_cell_2 = $worksheet->get_cell(1, 1);
							my $template_122_cell_3 = $worksheet->get_cell(1, 2);
							my $template_122_cell_4 = $worksheet->get_cell(1, 3);
							
							if($template_122_cell_1 and $template_122_cell_2 and $template_122_cell_3 and $template_122_cell_4){
								my $value1 = clean_string($template_122_cell_1->Value);
								my $value2 = clean_string($template_122_cell_2->Value);
								my $value3 = clean_string($template_122_cell_3->Value);
								my $value4 = clean_string($template_122_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Data difuzarii") and ($value3 eq "Minute") and ($value4 eq "Secunde")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t122.pl $file");	
								}
							}
							
							#TEMPLATE 123
							my $template_123_cell_1 = $worksheet->get_cell(3, 0);
							my $template_123_cell_2 = $worksheet->get_cell(3, 1);
							my $template_123_cell_3 = $worksheet->get_cell(3, 2);
							my $template_123_cell_4 = $worksheet->get_cell(3, 3);
							
							if($template_123_cell_1 and $template_123_cell_2 and $template_123_cell_3 and $template_123_cell_4){
								my $value1 = clean_string($template_123_cell_1->Value);
								my $value2 = clean_string($template_123_cell_2->Value);
								my $value3 = clean_string($template_123_cell_3->Value);
								my $value4 = clean_string($template_123_cell_4->Value);
								if(($value1 eq "Nr. Crt.") and ($value2 eq "Artist") and ($value3 eq "Titlu") and ($value4 eq "Minute")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t123.pl $file");	
								}
							}
							
							#TEMPLATE 124
							my $template_124_cell_1 = $worksheet->get_cell(8, 0);
							my $template_124_cell_2 = $worksheet->get_cell(8, 1);
							my $template_124_cell_3 = $worksheet->get_cell(8, 2);
							my $template_124_cell_4 = $worksheet->get_cell(8, 3);
							
							if($template_124_cell_1 and $template_124_cell_2 and $template_124_cell_3 and $template_124_cell_4){
								my $value1 = clean_string($template_124_cell_1->Value);
								my $value2 = clean_string($template_124_cell_2->Value);
								my $value3 = clean_string($template_124_cell_3->Value);
								my $value4 = clean_string($template_124_cell_4->Value);
								if(($value1 eq "Interpret") and ($value2 eq "Titlu") and ($value3 eq "Gen piesa") and ($value4 eq "Orchestra")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t124.pl $file");	
								}
							}
							
							#TEMPLATE 125
							my $template_125_cell_1 = $worksheet->get_cell(9, 0);
							my $template_125_cell_2 = $worksheet->get_cell(9, 1);
							my $template_125_cell_3 = $worksheet->get_cell(9, 2);
							my $template_125_cell_4 = $worksheet->get_cell(9, 3);
							
							if($template_125_cell_1 and $template_125_cell_2 and $template_125_cell_3 and $template_125_cell_4){
								my $value1 = clean_string($template_125_cell_1->Value);
								my $value2 = clean_string($template_125_cell_2->Value);
								my $value3 = clean_string($template_125_cell_3->Value);
								my $value4 = clean_string($template_125_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Ora de difuzare") and ($value4 eq "Titlu piesa")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t125.pl $file");	
								}
							}
							
							#TEMPLATE 126
							my $template_126_cell_1 = $worksheet->get_cell(6, 0);
							my $template_126_cell_2 = $worksheet->get_cell(6, 1);
							my $template_126_cell_3 = $worksheet->get_cell(6, 2);
							my $template_126_cell_4 = $worksheet->get_cell(6, 3);
							
							if($template_126_cell_1 and $template_126_cell_2 and $template_126_cell_3 and $template_126_cell_4){
								my $value1 = clean_string($template_126_cell_1->Value);
								my $value2 = clean_string($template_126_cell_2->Value);
								my $value3 = clean_string($template_126_cell_3->Value);
								my $value4 = clean_string($template_126_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Sp.") and ($value4 eq "Titlu piesa")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t126.pl $file");	
								}
							}
							
							#TEMPLATE 127
							my $template_127_cell_1 = $worksheet->get_cell(10, 0);
							my $template_127_cell_2 = $worksheet->get_cell(10, 1);
							my $template_127_cell_3 = $worksheet->get_cell(10, 2);
							my $template_127_cell_4 = $worksheet->get_cell(10, 3);
							
							if($template_127_cell_1 and $template_127_cell_2 and $template_127_cell_3 and $template_127_cell_4){
								my $value1 = clean_string($template_127_cell_1->Value);
								my $value2 = clean_string($template_127_cell_2->Value);
								my $value3 = clean_string($template_127_cell_3->Value);
								my $value4 = clean_string($template_127_cell_4->Value);
								if(($value1 eq "Nr.") and ($value2 eq "Emisiunea") and ($value3 eq "Durata") and ($value4 eq "Ziua difuzarii")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t127.pl $file");	
								}
							}
							
							#TEMPLATE 128
							my $template_128_cell_1 = $worksheet->get_cell(2, 0);
							my $template_128_cell_2 = $worksheet->get_cell(2, 1);
							my $template_128_cell_3 = $worksheet->get_cell(2, 2);
							my $template_128_cell_4 = $worksheet->get_cell(2, 3);
							
							if($template_128_cell_1 and $template_128_cell_2 and $template_128_cell_3 and $template_128_cell_4){
								my $value1 = clean_string($template_128_cell_1->Value);
								my $value2 = clean_string($template_128_cell_2->Value);
								my $value3 = clean_string($template_128_cell_3->Value);
								my $value4 = clean_string($template_128_cell_4->Value);
								if(($value1 eq "Nr  crt") and ($value2 eq "Data difuzarii") and ($value3 eq "Ora difuzarii") and ($value4 eq "Minute difuzate")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t128.pl $file");	
								}
							}
							
							#TEMPLATE 129
							my $template_129_cell_1 = $worksheet->get_cell(0, 0);
							my $template_129_cell_2 = $worksheet->get_cell(0, 1);
							my $template_129_cell_3 = $worksheet->get_cell(0, 2);
							my $template_129_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_129_cell_1 and $template_129_cell_2 and $template_129_cell_3 and $template_129_cell_4){
								my $value1 = clean_string($template_129_cell_1->Value);
								my $value2 = clean_string($template_129_cell_2->Value);
								my $value3 = clean_string($template_129_cell_3->Value);
								my $value4 = clean_string($template_129_cell_4->Value);
								if(($value1 eq "DENUMIRE EMISIUNE") and ($value2 eq "Realizator") and ($value3 eq "DIFUZARE") and ($value4 eq "NR EDITII")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t129.pl $file");	
								}
							}
							
							#TEMPLATE 130
							my $template_130_cell_1 = $worksheet->get_cell(8, 0);
							my $template_130_cell_2 = $worksheet->get_cell(8, 1);
							my $template_130_cell_3 = $worksheet->get_cell(8, 2);
							my $template_130_cell_4 = $worksheet->get_cell(8, 3);
							
							if($template_130_cell_1 and $template_130_cell_2 and $template_130_cell_3 and $template_130_cell_4){
								my $value1 = clean_string($template_130_cell_1->Value);
								my $value2 = clean_string($template_130_cell_2->Value);
								my $value3 = clean_string($template_130_cell_3->Value);
								my $value4 = clean_string($template_130_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "PROMO Emisiune") and ($value3 eq "Sp. Emisie") and ($value4 eq "Titlu piesa")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t130.pl $file");	
								}
							}
							
							#TEMPLATE 131
							my $template_131_cell_1 = $worksheet->get_cell(9, 0);
							my $template_131_cell_2 = $worksheet->get_cell(9, 1);
							my $template_131_cell_3 = $worksheet->get_cell(9, 2);
							my $template_131_cell_4 = $worksheet->get_cell(9, 3);
							
							if($template_131_cell_1 and $template_131_cell_2 and $template_131_cell_3 and $template_131_cell_4){
								my $value1 = clean_string($template_131_cell_1->Value);
								my $value2 = clean_string($template_131_cell_2->Value);
								my $value3 = clean_string($template_131_cell_3->Value);
								my $value4 = clean_string($template_131_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "PROMO Emisiune") and ($value3 eq "Sp. Emisie") and ($value4 eq "Titlu piesa")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t131.pl $file");	
								}
							}
						
							#TEMPLATE 132
							#my $template_132_cell_1 = $worksheet->get_cell(9, 0);
							#my $template_132_cell_2 = $worksheet->get_cell(9, 1);
							#my $template_132_cell_3 = $worksheet->get_cell(9, 2);
							#my $template_132_cell_4 = $worksheet->get_cell(9, 3);
							
							#if($template_132_cell_1 and $template_132_cell_2 and $template_132_cell_3 and $template_132_cell_4){
								#my $value1 = clean_string($template_132_cell_1->Value);
								#my $value2 = clean_string($template_132_cell_2->Value);
								#my $value3 = clean_string($template_132_cell_3->Value);
								#my $value4 = clean_string($template_132_cell_4->Value);
								#if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Sp. Emisie") and ($value4 eq "Titlu piesa")){
									#system("perl /var/perl-scripts/PERL/UNART/templates/t132.pl $file");	
								#}
							#}
							
							#TEMPLATE 133
							my $template_133_cell_1 = $worksheet->get_cell(0, 0);
							my $template_133_cell_2 = $worksheet->get_cell(0, 1);
							my $template_133_cell_3 = $worksheet->get_cell(0, 2);
							my $template_133_cell_4 = $worksheet->get_cell(0, 3);
							
							if($template_133_cell_1 and $template_133_cell_2 and $template_133_cell_3 and $template_133_cell_4){
								my $value1 = clean_string($template_133_cell_1->Value);
								my $value2 = clean_string($template_133_cell_2->Value);
								my $value3 = clean_string($template_133_cell_3->Value);
								my $value4 = clean_string($template_133_cell_4->Value);
								if(($value1 eq "Data") and ($value2 eq "Emisiune") and ($value3 eq "Sp. Emisie") and ($value4 eq "Titlu piesa")){
									system("perl /var/perl-scripts/PERL/UNART/templates/t133.pl $file");	
								}
							}
=end COMMENT
=cut	
						}							
						}	
					}elsif($extension eq ".XLSX"){
						#print $file,"\n";
					}elsif($extension eq ".CSV"){
						#print $file,"\n";
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
