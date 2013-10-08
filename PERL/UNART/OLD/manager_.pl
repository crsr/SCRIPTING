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
									next; #if the file isn't accesible or protected or smthelse ..parse the next file/sheet;
								}
								my($count_row, $count_column, $data_sheet, $cell, $sheet_name); # set variables for parsing
									foreach my $data_sheet (@{$workbook->{Worksheet}}) {
										my $data_sheet_name = $data_sheet->{Name};
										$sheet_name = undiacritic($data_sheet->{Name});
										for(my $count_row = $data_sheet->{MinRow} ; 	
											defined $data_sheet->{MaxRow} && $count_row <= $data_sheet->{MaxRow} ; $count_row++) {
												for(my $count_column = $data_sheet->{MinCol} ;
													defined $data_sheet->{MaxCol} && $count_column <= $data_sheet->{MaxCol} ; $count_column++) {
														$cell = $data_sheet->{Cells}[$count_row][$count_column]; # set cell value;
														if($cell) {
															if(($cell->Value eq 'Nr. crt.' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Data difuzarii' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Emisiune' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Min.' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Sec.' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'Titlu piesa' and $count_column == 5 and $count_row == 0) and ($cell->Value eq 'Artist' and $count_column == 7 and $count_row == 0)) {
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t1.pl $file");
																print STDOUT " -> T1\n";
															} elsif (($cell->Value eq 'Nr.' and $count_column == 0 and $count_row == 9) and ($cell->Value eq 'Data' and $count_column == 1 and $count_row == 9) and ($cell->Value eq 'Emisiune' and $count_column == 2 and $count_row == 9) and ($cell->Value eq 'Denumire opera muzicala' and $count_column == 3 and $count_row == 9) and ($cell->Value eq 'Interpret' and $count_column == 4 and $count_row == 9) and ($cell->Value eq 'Nr. difuzari' and $count_column == 7 and $count_row == 9) and ($cell->Value eq 'Min.' and $count_column == 8 and $count_row == 9) and ($cell->Value eq 'Sec.' and $count_column == 9 and $count_row == 9)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t2.pl $file");
																print STDOUT " -> T2\n";
															} elsif (($cell->Value eq 'Emisiune' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Titlu' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Interpret' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Nr.Difuzari' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'Min.' and $count_column == 5 and $count_row == 0) and ($cell->Value eq 'Sex.' and $count_column == 6 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t3.pl $file");
																print STDOUT " -> T3\n";
															} elsif (($cell->Value eq 'Minute' and $count_column == 0 and $count_row == 2) and ($cell->Value eq 'Secunde' and $count_column == 1 and $count_row == 2) and ($cell->Value eq 'Artist' and $count_column == 2 and $count_row == 2) and ($cell->Value eq 'Titlu piesa' and $count_column == 3 and $count_row == 2) and ($cell->Value eq 'Numar difuzari pe sapt' and $count_column == 4 and $count_row == 2)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t4.pl $file");
																print STDOUT " -> T4\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 9) and ($cell->Value eq 'Emisiune' and $count_column == 1 and $count_row == 9) and ($cell->Value eq 'Titlu piesa' and $count_column == 3 and $count_row == 9) and ($cell->Value eq 'Interpreti' and $count_column == 6 and $count_row == 9) and ($cell->Value eq 'Nr. Difuzari' and $count_column == 12 and $count_row == 9) and ($cell->Value eq 'Min' and $count_column == 13 and $count_row == 9) and ($cell->Value eq 'Sec' and $count_column == 14 and $count_row == 9)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t5.pl $file");
																print STDOUT " -> T5\n";
															} elsif (($cell->Value eq 'Ed.' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Data' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Emisiune' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Nr. Dif' and $count_column == 5 and $count_row == 0) and ($cell->Value eq 'Artist' and $count_column == 6 and $count_row == 0) and ($cell->Value eq 'Titlu piesa' and $count_column == 7 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t6.pl $file");
																print STDOUT " -> T6\n";
															} elsif (($cell->Value eq 'Ed.' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Data' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Emisiune' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Min' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Sec' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'Nr. Dif.' and $count_column == 5 and $count_row == 0) and ($cell->Value eq 'Artist' and $count_column == 6 and $count_row == 0) and ($cell->Value eq 'Titlu piesa' and $count_column == 8 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t7.pl $file");
																print STDOUT " -> T7\n";
															} elsif (($cell->Value eq 'Ziua' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'min' and $count_column == 1 and $count_row == 1) and ($cell->Value eq 'Sec' and $count_column == 2 and $count_row == 1) and ($cell->Value eq 'Muzica' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Artist' and $count_column == 6 and $count_row == 0) and ($cell->Value eq 'Titlu piesa' and $count_column == 7 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t8.pl $file");
																print STDOUT " -> T8\n";
															} elsif (($cell->Value eq 'Min' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Sec' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Nr. Dif.' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Artist' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Titlu track' and $count_column == 4 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t9.pl $file");
																print STDOUT " -> T9\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Titlu piesa' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Interpreti' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Nr. Dif.' and $count_column == 6 and $count_row == 0) and ($cell->Value eq 'min' and $count_column == 7 and $count_row == 1) and ($cell->Value eq 'sec' and $count_column == 8 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t10.pl $file");
																print STDOUT " -> T10\n";
															} elsif (($cell->Value eq 'DATA' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'EMISIUNE' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'TITLU' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'INTERPRETI' and $count_column == 5 and $count_row == 0) and ($cell->Value eq 'NR.' and $count_column == 8 and $count_row == 0) and ($cell->Value eq 'MIN' and $count_column == 9 and $count_row == 0) and ($cell->Value eq 'SEC' and $count_column == 10 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t11.pl $file");
																print STDOUT " -> T11\n";
															} elsif (($cell->Value eq 'EMISIUNE' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'TITLU PIESA' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'NR. DIFUZARI' and $count_column == 7 and $count_row == 0) and ($cell->Value eq 'MIN' and $count_column == 8 and $count_row == 0) and ($cell->Value eq 'SEC' and $count_column == 9 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t12.pl $file");
																print STDOUT " -> T12\n";
															} elsif (($cell->Value eq 'Nr.' and $count_column == 0 and $count_row == 13) and ($cell->Value eq 'Minute dufizate' and $count_column == 2 and $count_row == 13) and ($cell->Value eq 'Secounde fifuzate' and $count_column == 3 and $count_row == 13) and ($cell->Value eq 'Titlu fonograma' and $count_column == 4 and $count_row == 13) and ($cell->Value eq 'Nume artist' and $count_column == 5 and $count_row == 13)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t13.pl $file");
																print STDOUT " -> T13\n";
															} elsif (($cell->Value eq 'DATA' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'ARTIST/A' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'NUME MELODIE' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'DURATA' and $count_column == 6 and $count_row == 0) and ($cell->Value eq 'NR DIF' and $count_column == 7 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t14.pl $file");
																print STDOUT " -> T14\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 12) and ($cell->Value eq 'Durata' and $count_column == 2 and $count_row == 12) and ($cell->Value eq 'Interpret' and $count_column == 3 and $count_row == 12) and (($cell->Value eq 'Op, Muzicala' or $cell->Value eq '') and $count_column == 4 and $count_row == 12) ){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t15.pl $file");
																print STDOUT " -> T15\n";
															} elsif (($cell->Value eq 'DATA DIFUZARII' and $count_column == 0 and $count_row == 7) and ($cell->Value eq 'ORA DIFUZARII' and $count_column == 1 and $count_row == 7) and ($cell->Value eq 'MINUTE' and $count_column == 2 and $count_row == 7) and ($cell->Value eq 'SECUNDE' and $count_column == 3 and $count_row == 7) and ($cell->Value eq 'TITLU PIESA' and $count_column == 4 and $count_row == 7) and ($cell->Value eq 'ARTIST' and $count_column == 5 and $count_row == 7)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t16.pl $file");
																print STDOUT " -> T16\n";
															} elsif (($cell->Value eq 'Nr. crt.' and $count_column == 0 and $count_row == 2) and ($cell->Value eq 'Data difuzarii' and $count_column == 1 and $count_row == 2) and ($cell->Value eq 'Minute difuzate' and $count_column == 3 and $count_row == 2) and ($cell->Value eq 'Secunde difuzate' and $count_column == 4 and $count_row == 2) and ($cell->Value eq 'Titlu fonograma' and $count_column == 5 and $count_row == 2) and ($cell->Value eq 'Nume Artist' and $count_column == 6 and $count_row == 2)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t17.pl $file");
																print STDOUT " -> T17\n";
															} elsif (($cell->Value eq 'Nr. crt.  ' and $count_column == 0 and $count_row == 7) and ($cell->Value eq 'Data difuzare' and $count_column == 1 and $count_row == 7) and ($cell->Value eq 'Min.' and $count_column == 3 and $count_row == 7) and ($cell->Value eq 'Sec' and $count_column == 4 and $count_row == 7) and ($cell->Value eq 'Titlul emisiunii' and $count_column == 6 and $count_row == 7) and ($cell->Value eq 'Titlul piesei' and $count_column == 7 and $count_row == 7)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t18.pl $file");
																print STDOUT " -> T18\n";
															} elsif (($cell->Value eq 'nr crt' and $count_column == 0 and $count_row == 1) and ($cell->Value eq 'data dif' and $count_column == 1 and $count_row == 1) and ($cell->Value eq 'min' and $count_column == 3 and $count_row == 1) and ($cell->Value eq 'sec' and $count_column == 4 and $count_row == 1) and ($cell->Value eq 'titlu' and $count_column == 5 and $count_row == 1) and ($cell->Value eq 'artist' and $count_column == 6 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t19.pl $file");
																print STDOUT " -> T19\n";
															} elsif (($cell->Value eq 'DATA' and $count_column == 0 and $count_row == 1) and ($cell->Value eq 'ARTIST' and $count_column == 2 and $count_row == 1) and ($cell->Value eq 'MELODIE' and $count_column == 3 and $count_row == 1) and ($cell->Value eq 'Durata/piesa' and $count_column == 4 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t20.pl $file");
																print STDOUT " -> T20\n";
															} elsif (($cell->Value eq 'DATA' and $count_column == 0 and $count_row == 1) and ($cell->Value eq 'ARTIST' and $count_column == 2 and $count_row == 1) and ($cell->Value eq 'MELODIE' and $count_column == 3 and $count_row == 1) and ($cell->Value eq 'Min' and $count_column == 4 and $count_row == 2) and ($cell->Value eq 'Sec' and $count_column == 5 and $count_row == 2)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t21.pl $file");
																print STDOUT " -> T21\n";
															} elsif (($cell->Value eq 'Nr. Crt.' and $count_column == 0 and $count_row == 14) and ($cell->Value eq 'Data difuzarii' and $count_column == 1 and $count_row == 14) and ($cell->Value eq 'Emisiunea' and $count_column == 2 and $count_row == 14) and ($cell->Value eq 'Titlul Piesei ' and $count_column == 3 and $count_row == 14) and ($cell->Value eq 'Artistul ' and $count_column == 4 and $count_row == 14) and ($cell->Value eq 'Minute ' and $count_column == 5 and $count_row == 14) and ($cell->Value eq 'Secunde ' and $count_column == 6 and $count_row == 14)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t22.pl $file");
																print STDOUT " -> T22\n";
															} elsif (($cell->Value eq 'Canal' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Data' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Ora' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Distribuitor' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Titlul original' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'Durata' and $count_column == 5 and $count_row == 0) and ($cell->Value eq 'Reluare' and $count_column == 6 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t23.pl $file");
																print STDOUT " -> T23\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 2) and ($cell->Value eq 'Emisiune' and $count_column == 1 and $count_row == 2) and ($cell->Value eq 'Titlu piesa' and $count_column == 3 and $count_row == 2) and ($cell->Value eq 'Minute ' and $count_column == 12 and $count_row == 2) and ($cell->Value eq 'Secunde' and $count_column == 13 and $count_row == 2) and ($cell->Value eq 'nr difuzari + reluari' and $count_column == 14 and $count_row == 2)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t24.pl $file");
																print STDOUT " -> T24\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 1) and ($cell->Value eq 'Emisiune' and $count_column == 1 and $count_row == 1) and ($cell->Value eq 'Titlu piesa' and $count_column == 3 and $count_row == 1) and ($cell->Value eq 'Minute ' and $count_column == 14 and $count_row == 1) and ($cell->Value eq 'Secunde' and $count_column == 15 and $count_row == 1) and ($cell->Value eq 'Nr. Difuzari' and $count_column == 13 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t25.pl $file");
																print STDOUT " -> T25\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 1) and ($cell->Value eq 'Min.' and $count_column == 2 and $count_row == 1) and ($cell->Value eq 'Sec.' and $count_column == 3 and $count_row == 1) and ($cell->Value eq 'Titlul pesei' and $count_column == 6 and $count_row == 1) and ($cell->Value eq 'Autor' and $count_column == 7 and $count_row == 1) and ($cell->Value eq 'Interpret' and $count_column == 10 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t26.pl $file");
																print STDOUT " -> T26\n";
															} elsif (($cell->Value eq 'data ' and $count_column == 0 and $count_row == 1) and ($cell->Value eq ' ora difuzare' and $count_column == 1 and $count_row == 1) and ($cell->Value eq 'numele filmului' and $count_column == 2 and $count_row == 1) and ($cell->Value eq 'durata' and $count_column == 4 and $count_row == 1) and ($cell->Value eq 'Producator' and $count_column == 7 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t27.pl $file");
																print STDOUT " -> T27\n";
															} elsif (($cell->Value eq 'DATA RADIODIFUZARII' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'CRONOMETRAJ FILM  (SECUNDE)' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'TITLUL FILMULUI' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'REGIZOR' and $count_column == 5 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t28.pl $file");
																print STDOUT " -> T28\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Durata secunde' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Titlu' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'Regia' and $count_column == 7 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t29.pl $file");
																print STDOUT " -> T29\n";
															} elsif (($cell->Value eq 'Nr. Crt.' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Data difuzarii' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Minute' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Secunde' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Titlu piesa' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'Artist' and ($count_column == 6 or $count_column == 8) and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t30.pl $file");
																print STDOUT " -> T30\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Durata' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Durata secunde' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'Titlu' and $count_column == 5 and $count_row == 0) and ($cell->Value eq 'Denumire MCS' and $count_column == 6 and $count_row == 0) and ($cell->Value eq 'Regie' and $count_column == 8 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t31.pl $file");
																print STDOUT " -> T31\n";
															} elsif (($cell->Value eq 'Canal' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Data' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Durata secunde' and $count_column == 5 and $count_row == 0) and ($cell->Value eq 'Titlu' and $count_column == 7 and $count_row == 0) and ($cell->Value eq 'Regie' and $count_column == 10 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t32.pl $file");
																print STDOUT " -> T32\n";
															} elsif (($cell->Value eq 'Nr. crt.' and $count_column == 0 and $count_row == 2) and ($cell->Value eq 'Data difuzarii' and $count_column == 1 and $count_row == 2) and ($cell->Value eq 'Min' and $count_column == 2 and $count_row == 2) and ($cell->Value eq 'Sec' and $count_column == 3 and $count_row == 2) and ($cell->Value eq 'Titlu piesa' and $count_column == 4 and $count_row == 2) and ($cell->Value eq 'Artist' and $count_column == 6 and $count_row == 2)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t33.pl $file");
																print STDOUT " -> T33\n";
															} elsif (($cell->Value eq 'Nr. Crt.' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Post Radio' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Data' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Denumirea operei muzicale' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'Interpret' and $count_column == 7 and $count_row == 0) and ($cell->Value eq 'Minute' and $count_column == 8 and $count_row == 0) and ($cell->Value eq 'Secunde' and $count_column == 9 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t34.pl $file");
																print STDOUT " -> T34\n";
															} elsif (($cell->Value eq 'ID' and $count_column == 0 and $count_row == 1) and ($cell->Value eq 'date_played' and $count_column == 1 and $count_row == 1) and ($cell->Value eq 'duration' and $count_column == 5 and $count_row == 1) and ($cell->Value eq 'artist' and $count_column == 6 and $count_row == 1) and ($cell->Value eq 'title' and $count_column == 7 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t35.pl $file");
																print STDOUT " -> T35\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Emisiune' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Titlu' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Interpret' and $count_column == 5 and $count_row == 0) and ($cell->Value eq 'Nr difuzari' and $count_column == 8 and $count_row == 0) and ($cell->Value eq 'Min' and $count_column == 9 and $count_row == 0) and ($cell->Value eq 'Sec' and $count_column == 10 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t36.pl $file");
																print STDOUT " -> T36\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 1 and $count_row == 10) and ($cell->Value eq 'Emisiune' and $count_column == 2 and $count_row == 10) and ($cell->Value eq 'Titlu' and $count_column == 4 and $count_row == 10) and ($cell->Value eq 'Interpret' and $count_column == 6 and $count_row == 10) and ($cell->Value eq 'Nr.Difuzari' and $count_column == 12 and $count_row == 10) and ($cell->Value eq 'Minute' and $count_column == 13 and $count_row == 10) and ($cell->Value eq 'Secunde' and $count_column == 14 and $count_row == 10)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t37.pl $file");
																print STDOUT " -> T37\n";
															} elsif (($cell->Value eq 'DATA DIFUZARII' and $count_column == 0 and $count_row == 7) and ($cell->Value eq 'MINUTE' and $count_column == 2 and $count_row == 7) and ($cell->Value eq 'SECUNDE' and $count_column == 3 and $count_row == 7) and ($cell->Value eq 'TITLU PIESA' and $count_column == 4 and $count_row == 7) and ($cell->Value eq 'ARTIST' and $count_column == 6 and $count_row == 7)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t38.pl $file");
																print STDOUT " -> T38\n";
															} elsif (($cell->Value eq 'Nr. crt.' and $count_column == 2 and $count_row == 8) and ($cell->Value eq 'Data difuzarii' and $count_column == 3 and $count_row == 8) and ($cell->Value eq 'Minute difuzate' and $count_column == 6 and $count_row == 8) and ($cell->Value eq 'Secunde difuzate' and $count_column == 7 and $count_row == 8) and ($cell->Value eq 'Numar difuzari' and $count_column == 8 and $count_row == 8) and ($cell->Value eq 'Titlul piesa' and $count_column == 12 and $count_row == 8) and ($cell->Value eq 'Artist/Interpret' and $count_column == 21 and $count_row == 8)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t39.pl $file");
																print STDOUT " -> T39\n";
															} elsif (($cell->Value eq 'Data difuzarii' and $count_column == 0 and $count_row == 2) and ($cell->Value eq 'Nr minute difuzate' and $count_column == 2 and $count_row == 2) and ($cell->Value eq 'Nr secunde difuzate' and $count_column == 3 and $count_row == 2) and ($cell->Value eq 'Titlul piesei' and $count_column == 4 and $count_row == 2) and ($cell->Value eq 'Interpretul / Trupa' and $count_column == 5 and $count_row == 2)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t40.pl $file");
																print STDOUT " -> T40\n";
															} elsif (($cell->Value eq 'Data difuzarii' and $count_column == 0 and $count_row == 1) and ($cell->Value eq 'Nr minute difuzate' and $count_column == 2 and $count_row == 1) and ($cell->Value eq 'Nr secunde difuzate' and $count_column == 3 and $count_row == 1) and ($cell->Value eq 'Titlul piesei' and $count_column == 4 and $count_row == 1) and ($cell->Value eq 'Interpretul / Trupa' and $count_column == 5 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t41.pl $file");
																print STDOUT " -> T41\n";
															} elsif (($cell->Value eq 'Interpret' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Producator' and $count_column == 5 and $count_row == 0) and ($cell->Value eq 'Nr.Difuzari' and $count_column == 7 and $count_row == 0) and ($cell->Value eq 'Min.' and $count_column == 8 and $count_row == 0) and ($cell->Value eq 'Sec.' and $count_column == 9 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t42.pl $file");
																print STDOUT " -> T42\n";
															} elsif (($cell->Value eq 'NR CRT' and $count_column == 0 and $count_row == 8) and ($cell->Value eq 'DATA DIFUZARII' and $count_column == 1 and $count_row == 8) and ($cell->Value eq 'MINUTE' and $count_column == 3 and $count_row == 8) and ($cell->Value eq 'SECUNDE' and $count_column == 4 and $count_row == 8) and ($cell->Value eq 'TITLU PIESA' and $count_column == 5 and $count_row == 8) and ($cell->Value eq 'ARTIST' and $count_column == 7 and $count_row == 8)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t43.pl $file");
																print STDOUT " -> T43\n";
															} elsif (($cell->Value eq '' and $count_column == 0 and $count_row == 7) and ($cell->Value eq 'DATA DIFUZARII' and $count_column == 1 and $count_row == 7) and ($cell->Value eq 'MINUTE' and $count_column == 3 and $count_row == 7) and ($cell->Value eq 'SECUNDE' and $count_column == 4 and $count_row == 7) and ($cell->Value eq 'TITLU PIESA' and $count_column == 5 and $count_row == 7) and ($cell->Value eq 'ARTIST' and $count_column == 7 and $count_row == 7)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t44.pl $file");
																print STDOUT " -> T44\n";
															} elsif (($cell->Value eq 'DateTime' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Artist' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Title' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'PlayCount' and $count_column == 7 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t45.pl $file");
																print STDOUT " -> T45\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 7) and ($cell->Value eq 'EMISIUNE' and $count_column == 1 and $count_row == 7) and ($cell->Value eq 'Interpret' and $count_column == 3 and $count_row == 7) and ($cell->Value eq 'Titlu' and $count_column == 4 and $count_row == 7) and ($cell->Value eq 'NR. Difuzari' and $count_column == 11 and $count_row == 7) and ($cell->Value eq 'Minute' and $count_column == 12 and $count_row == 7) and ($cell->Value eq 'Secunde' and $count_column == 13 and $count_row == 7)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t46.pl $file");
																print STDOUT " -> T46\n";
															} elsif (($cell->Value eq 'DATA DIFUZARE' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'ORA DIFUZARE' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'ARTIST' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'PIESA' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'DURATA DIFUZARE' and $count_column == 4 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t47.pl $file");
																print STDOUT " -> T47\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 8) and ($cell->Value eq 'Emisiune' and $count_column == 1 and $count_row == 8) and ($cell->Value eq 'Interpret' and $count_column == 3 and $count_row == 8) and ($cell->Value eq 'Titlu' and $count_column == 4 and $count_row == 8) and ($cell->Value eq 'Min' and $count_column == 12 and $count_row == 8) and ($cell->Value eq 'Sec' and $count_column == 13 and $count_row == 8)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t48.pl $file");
																print STDOUT " -> T48\n";
															} elsif (($cell->Value eq 'Day' and $count_column == 0 and $count_row == 5) and ($cell->Value eq 'Min' and $count_column == 2 and $count_row == 5) and ($cell->Value eq 'Sec' and $count_column == 3 and $count_row == 5) and ($cell->Value eq 'Artist' and $count_column == 4 and $count_row == 5) and ($cell->Value eq 'Song' and $count_column == 5 and $count_row == 5)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t49.pl $file");
																print STDOUT " -> T49\n";
															} elsif (($cell->Value eq 'Nume Spot' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Voce' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Nume artist/compozitor piesa fundal' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'Timp (s)' and $count_column == 7 and $count_row == 0) and ($cell->Value eq 'Nr de difuzari' and $count_column == 8 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t50.pl $file");
																print STDOUT " -> T50\n";
															} elsif (($cell->Value eq 'NR. CRT' and $count_column == 0 and $count_row == 5) and ($cell->Value eq 'DATA DIFUZARE' and $count_column == 1 and $count_row == 5) and ($cell->Value eq 'MINUTE' and $count_column == 3 and $count_row == 5) and ($cell->Value eq 'SECUNDE' and $count_column == 4 and $count_row == 5) and ($cell->Value eq 'TITLU PIESA' and $count_column == 5 and $count_row == 5) and ($cell->Value eq 'ARTIST' and $count_column == 7 and $count_row == 5)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t51.pl $file");
																print STDOUT " -> T51\n";
															} elsif (($cell->Value eq 'Data dif.' and $count_column == 0 and $count_row == 6) and ($cell->Value eq 'Ora difuzare' and $count_column == 1 and $count_row == 6) and ($cell->Value eq 'Min.difuzate' and $count_column == 2 and $count_row == 6) and ($cell->Value eq 'Sec.difuzate' and $count_column == 3 and $count_row == 6) and ($cell->Value eq 'Interpret' and $count_column == 4 and $count_row == 6) and ($cell->Value eq 'Titlu piesa' and $count_column == 5 and $count_row == 6) and ($cell->Value eq 'Nr. Difuzari' and $count_column == 12 and $count_row == 6)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t52.pl $file");
																print STDOUT " -> T52\n";
															} elsif (($cell->Value eq 'Nr.crt' and $count_column == 0 and $count_row == 6) and ($cell->Value eq 'Data' and $count_column == 1 and $count_row == 6) and ($cell->Value eq 'Minute' and $count_column == 3 and $count_row == 6) and ($cell->Value eq 'Secunde' and $count_column == 4 and $count_row == 6) and ($cell->Value eq 'Artist' and $count_column == 5 and $count_row == 6) and ($cell->Value eq 'Piesa' and $count_column == 6 and $count_row == 6)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t53.pl $file");
																print STDOUT " -> T53\n";
															} elsif (($cell->Value eq 'Ziua' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Numar Difuzari' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Minute' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Secunde' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Artist' and $count_column == 4 and $count_row == 0) and ($cell->Value eq 'Titlu Piesa' and $count_column == 5 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t54.pl $file");
																print STDOUT " -> T54\n";
															} elsif (($cell->Value eq 'Zi' and $count_column == 0 and $count_row == 6) and ($cell->Value eq 'Luna' and $count_column == 1 and $count_row == 6) and ($cell->Value eq 'An' and $count_column == 2 and $count_row == 6) and ($cell->Value eq 'Ora' and $count_column == 3 and $count_row == 6) and ($cell->Value eq 'Min' and $count_column == 4 and $count_row == 6) and ($cell->Value eq 'Sec' and $count_column == 5 and $count_row == 6)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t55.pl $file");
																print STDOUT " -> T55\n";
															} elsif (($cell->Value eq 'Data difuzarii' and $count_column == 0 and $count_row == 14) and ($cell->Value eq 'Minute dif.' and $count_column == 1 and $count_row == 14) and ($cell->Value eq 'Secunde dif' and $count_column == 2 and $count_row == 14) and ($cell->Value eq ' Interpret' and $count_column == 3 and $count_row == 14) and ($cell->Value eq 'Titlu piesa' and $count_column == 4 and $count_row == 14) and ($cell->Value eq 'Compozitor' and $count_column == 5 and $count_row == 14)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t56.pl $file");
																print STDOUT " -> T56\n";
															} elsif (($cell->Value eq 'Ziua' and $count_column == 1 and $count_row == 1) and ($cell->Value eq 'Ora' and $count_column == 2 and $count_row == 1) and ($cell->Value eq 'Minute' and $count_column == 3 and $count_row == 1) and ($cell->Value eq 'Secunde' and $count_column == 4 and $count_row == 1) and ($cell->Value eq 'Artist' and $count_column == 5 and $count_row == 1) and ($cell->Value eq 'Titlu piesa' and $count_column == 6 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t57.pl $file");
																print STDOUT " -> T57\n";
															} elsif (($cell->Value eq 'Post TV/Radio' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Emisiune' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Titlu opera muzicala' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Durata minute, secunde' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Autor muzica' and $count_column == 5 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t58.pl $file");
																print STDOUT " -> T58\n";
															} elsif (($cell->Value eq 'Nr crt' and $count_column == 0 and $count_row == 13) and ($cell->Value eq 'DATA DIFUZARII' and $count_column == 1 and $count_row == 13) and ($cell->Value eq 'ORA DIFUZARII' and $count_column == 2 and $count_row == 13) and ($cell->Value eq 'MINUTE' and $count_column == 3 and $count_row == 13) and ($cell->Value eq 'SECUNDE' and $count_column == 4 and $count_row == 13) and ($cell->Value eq 'TITLU PIESA' and $count_column == 5 and $count_row == 13)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t59.pl $file");
																print STDOUT " -> T59\n";
															} elsif (($cell->Value eq 'Nr' and $count_column == 0 and $count_row == 9) and ($cell->Value eq 'DATA DIFUZARII' and $count_column == 1 and $count_row == 9) and ($cell->Value eq 'ORA DIFUZARII' and $count_column == 2 and $count_row == 9) and ($cell->Value eq 'MINUTE' and $count_column == 3 and $count_row == 9) and ($cell->Value eq 'SECUNDE' and $count_column == 4 and $count_row == 9) and ($cell->Value eq 'TITLU PIESA' and $count_column == 5 and $count_row == 9)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t60.pl $file");
																print STDOUT " -> T60\n";
															}  elsif (($cell->Value eq 'Nr crt' and $count_column == 0 and $count_row == 7) and ($cell->Value eq 'Data' and $count_column == 1 and $count_row == 7) and ($cell->Value eq 'Min' and $count_column == 3 and $count_row == 7) and ($cell->Value eq 'Sec' and $count_column == 4 and $count_row == 7) and ($cell->Value eq 'Artist' and $count_column == 5 and $count_row == 7) and ($cell->Value eq 'Piesa' and $count_column == 6 and $count_row == 7)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t61.pl $file");
																print STDOUT " -> T61\n";
															} elsif (($cell->Value eq 'Nr crt' and $count_column == 0 and $count_row == 8) and ($cell->Value eq ' Data difuzãrii ' and $count_column == 1 and $count_row == 8) and ($cell->Value eq ' Ora difuzãrii ' and $count_column == 2 and $count_row == 8) and ($cell->Value eq ' Minute difuzate ' and $count_column == 3 and $count_row == 8) and ($cell->Value eq ' Secunde difuzate ' and $count_column == 4 and $count_row == 8) and ($cell->Value eq ' Titlul piesei ' and $count_column == 5 and $count_row == 8)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t62.pl $file");
																print STDOUT " -> T62\n";
															} elsif (($cell->Value eq 'Date' and $count_column == 0 and $count_row == 5) and ($cell->Value eq 'Hour' and $count_column == 1 and $count_row == 5) and ($cell->Value eq 'Minutes' and $count_column == 2 and $count_row == 5) and ($cell->Value eq 'Seconds' and $count_column == 3 and $count_row == 5) and ($cell->Value eq 'Song' and ($count_column == 4 or $count_column == 5) and $count_row == 5)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t63.pl $file");
																print STDOUT " -> T63\n";
															} elsif (($cell->Value eq 'Date' and $count_column == 0 and $count_row == 3) and ($cell->Value eq 'Hour' and $count_column == 1 and $count_row == 3) and ($cell->Value eq 'Minutes' and $count_column == 2 and $count_row == 3) and ($cell->Value eq 'Seconds' and $count_column == 3 and $count_row == 3) and ($cell->Value eq 'Song' and $count_column == 4 and $count_row == 3)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t64.pl $file");
																print STDOUT " -> T64\n";
															} elsif (($cell->Value eq 'Nr Crt' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Data Difuzarii' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Ora Difuzarii' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Minute Difuzate' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'Secunde Difuzate' and $count_column == 4 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t65.pl $file");
																print STDOUT " -> T65\n";
															} elsif (($cell->Value eq 'Ziua' and $count_column == 1 and $count_row == 3) and ($cell->Value eq 'Ora Dif.' and $count_column == 2 and $count_row == 3) and ($cell->Value eq 'Titlu Spot' and $count_column == 3 and $count_row == 3)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t66.pl $file");
																print STDOUT " -> T66\n";
															} elsif (($cell->Value eq 'NrCrt' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'DataDifuzarii' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'OraDifuzarii' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'MinuteDifuzate' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'SecundeDifuzate' and $count_column == 4 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t67.pl $file");
																print STDOUT " -> T67\n";
															} elsif (($cell->Value eq 'Ziua' and $count_column == 0 and $count_row == 1) and ($cell->Value eq 'Ora sau Spaţiu orar' and $count_column == 1 and $count_row == 1) and ($cell->Value eq 'Minute' and $count_column == 2 and $count_row == 1) and ($cell->Value eq 'Secunde' and $count_column == 3 and $count_row == 1) and ($cell->Value eq 'Artist' and $count_column == 4 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t68.pl $file");
																print STDOUT " -> T68\n";
															} elsif (($cell->Value eq 'DATA DIFUZARII' and $count_column == 0 and $count_row == 7) and ($cell->Value eq 'ORA DIFUZARII' and $count_column == 1 and $count_row == 7) and ($cell->Value eq 'MINUTE' and $count_column == 2 and $count_row == 7) and ($cell->Value eq 'SECUNDE' and $count_column == 3 and $count_row == 7) and ($cell->Value eq 'TITLU PIESA' and $count_column == 4 and $count_row == 7)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t69.pl $file");
																print STDOUT " -> T69\n";
															} elsif (($cell->Value eq 'DATA DIFUZARII' and $count_column == 0 and $count_row == 7) and ($cell->Value eq 'POST RADIO' and $count_column == 1 and $count_row == 7) and ($cell->Value eq 'TITLU OPERA MUZICALA' and $count_column == 2 and $count_row == 7) and ($cell->Value eq 'EMISIUNE' and $count_column == 3 and $count_row == 7) and ($cell->Value eq 'SPATIU EMISIUNE' and $count_column == 4 and $count_row == 7)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t70.pl $file");
																print STDOUT " -> T70\n";
															} elsif (($cell->Value eq 'DATA' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'ORA' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'DURATA' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'INTERPRET' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'MELODIE' and $count_column == 4 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t71.pl $file");
																print STDOUT " -> T71\n";
															} elsif (($cell->Value eq 'Day' and $count_column == 0 and $count_row == 7) and ($cell->Value eq 'Min' and $count_column == 2 and $count_row == 7) and ($cell->Value eq 'Sec' and $count_column == 3 and $count_row == 7) and ($cell->Value eq 'Artist' and $count_column == 4 and $count_row == 7) and ($cell->Value eq 'Song' and $count_column == 5 and $count_row == 7)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t72.pl $file");
																print STDOUT " -> T72\n";
															} elsif (($cell->Value eq 'nr.crt' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'firma/campanie' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'artist/titlu' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'durata spot ' and $count_column == 3 and $count_row == 0) and ($cell->Value eq 'nr difuzari ' and $count_column == 4 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t73.pl $file");
																print STDOUT " -> T73\n";
															} elsif (($cell->Value eq 'data' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'ora' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'durata' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'interpret + titlu' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t74.pl $file");
																print STDOUT " -> T74\n";
															} elsif (($cell->Value eq 'Num' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Vox1' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Vox2' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Id' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t75.pl $file");
																print STDOUT " -> T75\n";
															} elsif (($cell->Value eq 'Nr crt.' and $count_column == 0 and $count_row == 10) and ($cell->Value eq 'Data' and $count_column == 1 and $count_row == 10) and ($cell->Value eq 'Spatiu emisie' and $count_column == 2 and $count_row == 10) and ($cell->Value eq 'Minute' and $count_column == 3 and $count_row == 10)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t76.pl $file");
																print STDOUT " -> T76\n";
															} elsif (($cell->Value eq 'Data Difuzare' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Ora Difuzare' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Minute Difuzate' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Secunde Difuzate' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t77.pl $file");
																print STDOUT " -> T77\n";
															} elsif (($cell->Value eq 'Data Difuzare' and $count_column == 0 and $count_row == 15) and ($cell->Value eq 'Ora Difuzare' and $count_column == 1 and $count_row == 15) and ($cell->Value eq 'Minute Difuzate' and $count_column == 2 and $count_row == 15) and ($cell->Value eq 'Sec. Dif.' and $count_column == 3 and $count_row == 15)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t78.pl $file");
																print STDOUT " -> T78\n";
															} elsif (($cell->Value eq 'TITLU ' and $count_column == 1 and $count_row == 4) and ($cell->Value eq 'COMPOZITOR / TEXTIER' and $count_column == 2 and $count_row == 4) and ($cell->Value eq 'ARTIST' and $count_column == 3 and $count_row == 4) and ($cell->Value eq 'LABEL' and $count_column == 4 and $count_row == 4)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t79.pl $file");
																print STDOUT " -> T79\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 13) and ($cell->Value eq 'Emisiune' and $count_column == 1 and $count_row == 13) and ($cell->Value eq 'Interpret' and $count_column == 2 and $count_row == 13) and ($cell->Value eq 'Titlu' and $count_column == 3 and $count_row == 13)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t80.pl $file");
																print STDOUT " -> T80\n";
															} elsif (($cell->Value eq 'Data difuzarii' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Ora difuzarii' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Minute difuzate' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Secunde difuzate' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t81.pl $file");
																print STDOUT " -> T81\n";
															} elsif (($cell->Value eq 'No' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Data' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Durata difuzarii (sec)' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'title' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t82.pl $file");
																print STDOUT " -> T82\n";
															} elsif (($cell->Value eq 'No' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Data' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Durata' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Title' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t83.pl $file");
																print STDOUT " -> T83\n";
															} elsif (($cell->Value eq 'Titlu' and $count_column == 0 and $count_row == 1) and ($cell->Value eq 'Minute' and $count_column == 1 and $count_row == 1) and ($cell->Value eq 'Secunde' and $count_column == 2 and $count_row == 1) and ($cell->Value eq 'Difuzari' and $count_column == 3 and $count_row == 1)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t84.pl $file");
																print STDOUT " -> T84\n";
															} elsif (($cell->Value eq 'Artist / Grup' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Melodie' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'tara' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Min.' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t85.pl $file");
																print STDOUT " -> T85\n";
															} elsif (($cell->Value eq 'NR. CRT.' and $count_column == 0 and $count_row == 5) and ($cell->Value eq 'DATA DIFUZARII' and $count_column == 1 and $count_row == 5) and ($cell->Value eq 'ORA DIFUZARII' and $count_column == 2 and $count_row == 5) and ($cell->Value eq 'MINUTE' and $count_column == 3 and $count_row == 5)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t86.pl $file");
																print STDOUT " -> T86\n";
															} elsif (($cell->Value eq 'Nr. Crt.' and $count_column == 0 and $count_row == 8) and ($cell->Value eq 'Emisiune' and $count_column == 1 and $count_row == 8) and ($cell->Value eq 'Spatiu emisie' and $count_column == 2 and $count_row == 8) and ($cell->Value eq 'Titlu' and $count_column == 3 and $count_row == 8)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t87.pl $file");
																print STDOUT " -> T87\n";
															} elsif (($cell->Value eq 'DATA DIFUZARII' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'NUMELE EMISIUNII' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'ORA DIFUZARII' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'MINUTE DIFUZATE' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t88.pl $file");
																print STDOUT " -> T88\n";
															} elsif (($cell->Value eq 'Nr crt' and $count_column == 0 and $count_row == 7) and ($cell->Value eq ' Data difuzãrii ' and $count_column == 1 and $count_row == 7) and ($cell->Value eq ' Ora difuzãrii ' and $count_column == 2 and $count_row == 7) and ($cell->Value eq ' Minute difuzate ' and $count_column == 3 and $count_row == 7) and ($cell->Value eq ' Secunde difuzate ' and $count_column == 4 and $count_row == 7) and ($cell->Value eq ' Titlul piesei ' and $count_column == 5 and $count_row == 7)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t89.pl $file");
																print STDOUT " -> T90\n";
															} elsif (($cell->Value eq 'MELODIE - INTERPRET' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'DURATA' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'NR. DIFUZARI' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'MINUTAJ' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t91.pl $file");
																print STDOUT " -> T91\n";
															} elsif (($cell->Value eq 'Nr. Crt.' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Per difuzarii' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Titlul melodiei' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Cantaret' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t92.pl $file");
																print STDOUT " -> T92\n";
															} elsif (($cell->Value eq 'Data difuzarii' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Ora difuzarii' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Min.' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Sec.' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t93.pl $file");
																print STDOUT " -> T93\n";
															} elsif (($cell->Value eq 'Nr. Crt.' and $count_column == 0 and $count_row == 0) and ($cell->Value eq 'Data difuzarii' and $count_column == 1 and $count_row == 0) and ($cell->Value eq 'Ora difuzarii' and $count_column == 2 and $count_row == 0) and ($cell->Value eq 'Minute difuzate' and $count_column == 3 and $count_row == 0)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t94.pl $file");
																print STDOUT " -> T94\n";
															} elsif (($cell->Value eq 'Ziua' and $count_column == 0 and $count_row == 10) and ($cell->Value eq 'Spaţiu orar' and $count_column == 1 and $count_row == 10) and ($cell->Value eq 'Min.' and $count_column == 2 and $count_row == 10) and ($cell->Value eq 'Sec.' and $count_column == 3 and $count_row == 10)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t95.pl $file");
																print STDOUT " -> T95\n";
															} elsif (($cell->Value eq 'Data' and $count_column == 0 and $count_row == 8) and ($cell->Value eq 'Interval orar' and $count_column == 1 and $count_row == 8) and ($cell->Value eq 'Emisiune' and $count_column == 2 and $count_row == 8) and ($cell->Value eq 'Interpret' and $count_column == 3 and $count_row == 8)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t96.pl $file");
																print STDOUT " -> T96\n";
															} elsif (($cell->Value eq 'Nr.crt.' and $count_column == 0 and $count_row == 15) and ($cell->Value eq 'Data radiodifuzarii' and $count_column == 1 and $count_row == 15) and ($cell->Value eq 'Ora ' and $count_column == 2 and $count_row == 15) and ($cell->Value eq 'Durata film (Secunde)' and $count_column == 3 and $count_row == 15)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t97.pl $file");
																print STDOUT " -> T97\n";
															} elsif (($cell->Value eq 'Nr.crt.' and $count_column == 0 and $count_row == 13) and ($cell->Value eq 'Data radiodifuzarii' and $count_column == 1 and $count_row == 13) and ($cell->Value eq 'Ora ' and $count_column == 2 and $count_row == 13) and ($cell->Value eq 'Durata film (Secunde)' and $count_column == 3 and $count_row == 13)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t98.pl $file");
																print STDOUT " -> T98\n";
															} elsif (($cell->Value eq 'Nr.crt.' and $count_column == 0 and $count_row == 12) and ($cell->Value eq 'Data radiodifuzarii' and $count_column == 1 and $count_row == 12) and ($cell->Value eq 'Ora ' and $count_column == 2 and $count_row == 12) and ($cell->Value eq 'Durata film (Secunde)' and $count_column == 3 and $count_row == 12)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t99.pl $file");
																print STDOUT " -> T99\n";
															} elsif (($cell->Value eq 'Nr.crt.' and $count_column == 0 and $count_row == 10) and ($cell->Value eq 'Data radiodifuzarii' and $count_column == 1 and $count_row == 10) and ($cell->Value eq 'Ora ' and $count_column == 2 and $count_row == 10) and ($cell->Value eq 'Durata film (Secunde)' and $count_column == 3 and $count_row == 10)){
																print STDOUT "Fisier ".$file;
																	system("perl /var/perl-scripts/PERL/UNART/templates/t100.pl $file");
																print STDOUT " -> T100\n";
															} else {
																my $old_path = abs_path($file);
																my $new_path = abs_path($file);
																$new_path =~ s/IMPORT/UNMATCHED/; #set new path (string replace)
																#$new_path =~ s/xls/residuum/; #set new path (string replace)
																my($filename_to_move, $directories_to_move) = fileparse($new_path); # get directories tree for new tree creation
																make_path($directories_to_move);
																move($old_path, $new_path);
																unlink($old_path);
																next;
															}															
														}
													}
											}								
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

my $end_run = time();
my $run_time = $end_run - $start_run;
print STDOUT "Timp executie $run_time secunde\n";
print STDOUT "STOP\n";
