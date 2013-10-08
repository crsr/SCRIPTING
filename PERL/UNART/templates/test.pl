#
#
#	T1 template script
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

use DBI;
use Spreadsheet::ParseExcel;
use Data::Dumper;
sub clean_string($); 
#binmode STDOUT, ":utf8";

my $log_data = strftime("%Y-%m-%d %H-%M-%S", localtime);
my $log_file_data = strftime("%Y-%m-%d", localtime);

#
# Lists for search patterns
#
my @months = ("ianuarie", "februarie", "martie", "aprilie", "mai", "iunie", "iulie", "august", "septembrie", "octombrie", "noiembrie", "decembrie"); 
my @years = ("2011", "2012", "2013");
#my @channels = ("RADIOFIR","PACRISTV","TVH20","MAGICFM","TVR2","RADIOSUPERFM","ETALONTV","FOCUSTV","PROFM","ACASATV","ROMANTICATV","NOTATV","PROTVINTERNATIONAL","RADIOINFINIT","RADIOTECUCI","RADIOIMPACT21","SOMESTV","TVVALAHIA","HFM20","TVMUNTENIA","RADIOSEMNALALEXANDRIA","RADIOWESTCITY","SPORTRO","BETTERFM","RADIOTGJIU","ROCKFM","RADIOMINISAT","RADIOKFM","TOP1TV","ANTENA3","FAVORITTV","RADIODADA","ACTIVTV","MYNELETV","ROMANIATV","RADIODREAMFM","ACTIVFM","RADIOWHITEFM","RADIOSUDCRAIOVA","SOROZAT","KISSFM","PVTV","V24","RTTFM","ASTV","RADIOHIT","GSPTV","EUROPAFM","RADIOVIBEFM","RADIOTOP","RADIOBIGFM","TVSIRIUS","COLUMNATV","TELEM","RADIOCAMPI","ATLASFM","REALITATEATV","RADIOSEVERIN","TVSEVERIN","VIVAFM","ITSYBITSY","PROTVONLINE","EUFORIA","RADIOEMARAMURES","ARENAFM","PRIZMATV","TRANSILVANIALIVE","TVARAD","ANTENA2","MUSCELTV","WESTCITY","RADIOTEX","PROTVONLINE","IMPACTTV","ALEXANDRIATV","RADIOAS","RADIOMPLUS","RADIOGAGA","TVT89","CLICKFM","TVRCULTURAL","RADIOGUERRILLA","TVRCLUJ","RADIOIMPACTBAIAMARE","ERDELYTV","SZEKELYTV","UTV","PROTV","CFM","TVATLAS","RADIOBOOM","STUDIOB","RADIODENS","MUSICFM","BANATFM","RADIO1GALATI","NATIONALFM","RADIOENERGY","EVENIMENTTV","RADIOBRASOVSUPERFM","NORDVESTTV","UNUTV","RADIOERDELY","DOLCESPORT2","ETNOTV","RADIOUNISON","RADIOCOLOR","TOP1TV","DOLCEINFO","N24PLUS","SRTV","RADIOFRISSFM","RADIOSUD","HITMC","TVT89","RADIOWYL","RADIOMARIA","RADIOSTILDEJ","TELEUNIVERSITATEATV","DREAMFM","Film2","FTV","WYLTV","SUPERFM","TVSUDEST","PROTVINTERNATIONAL","HUNEDOARATV","RADIOZZIMNICEA","RADIODENS","RADIODELTATULCEA","COOL","MDITV","ROMANTICFM","ROMTV","TVVALCEA","RADIOALFABACAU","RADIOIMPULS","RADIO21","RADIOUNUALEXANDRIA","RADIOIMPACT","ROMANTICARAD","TRANSILVANIACHANNELTV","DoQ","RADIOSICULUS","RADIOSTARFAGARAS","RADIOLIDER","TVALPHAMEDIA","HFM20","MOOZTV","ROMANTICA","ACASATVGOLD","SMARTFM","TVMUSICMIX","TVTARGOVISTE","RADIOPRAHOVA","RADIOTERRA","BANATTV","RADIOSKY","EVENIMENTULSIBIAN","ANTENA1","KANALD","SUPERFM","DANCEFM","TVTRANSILVANIA","ALBATV","SIGHETFM","PARTYTV","RADIONAPOCAFM","NAPOCAFM","RADIOKITONESTI","REFLEKTORTV","RADIOCAMPUS","TRANSILVANIALOOK","TVRM","PRIMATV","RADIOVIPP","TVBACAU","B1TV","INEDITTV","RADIOPRIMA","WORDRADIOSON","PROCINEMA","RADIOUNU","RADIOGALAXY","TVSIGHET","SRR","SIRIUSTV","RADIOVOCESCAMPI","TARAFTV","RADIORING","RADIOZU","DAMBOVITATV","RADIOFUN","TVRINTERNATIONAL","MTV","CITYRADIO","MEDIATV","SPORTKLUB","RADIOSPORTTOTALFM","RFI","RADIOVOX","POPULARTV","RADIOWYLFM","RADIOFAVORIT","RADIOPAPRIKA","KISSTV","TVEMARAMURES","RADIOROMANTICARAD","RADIOHORION","ABSOLUTTV","RADIOVALCEA","RADIONORDEST","MUSICTV","RADIOORION","RADIONOVAFM","DOINAFM","MDIFM","NATIONALTV","RADIOEVENIMENTAIUD","GOLDFM","SPORTTOTAL","Film","PROTV","TVR3","PULSFM","MEDIATVSUCEAVA","SPORTKLUB","ANTENA4EUFORIA","OLTTV","RADIOPARTIUM","DOLCESPORT","NOVAFM","LBM");

	#postgres connection and queries
	my @channels_list = ();
	my $pg_connection;
	my $data_base_name = "unart";
	my $data_base_host = "localhost";
	my $data_base_uname = "postgres";
	my $data_base_pwd = "postgres";
	$pg_connection = DBI->connect("dbi:Pg:dbname=$data_base_name;host=$data_base_host", "$data_base_uname", "$data_base_pwd");

	#my $sth = $pg_connection->prepare("SELECT channel_title FROM public.channels");
	#$sth->execute();
	#my @row_ary  = $sth->selectall_arrayref;
	#print @row_ary;

my $emps = $pg_connection->selectall_arrayref(
      "SELECT channel_id,channel_title FROM public.channels",
      { Slice => {} }
  );
  
  foreach my $emp ( @$emps ) {
      print Dumper($emp);
  }

my $end_run = time();
my $run_time = $end_run - $start_run;
print STDOUT "Timp executie $run_time secunde\n";
print STDOUT "STOP\n";







