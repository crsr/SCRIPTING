use strict;
use warnings;
use DBI;
use MongoDB::Connection;
use MongoDB::Database;
use MongoDB::Cursor;
use Data::Dumper;
use POSIX qw/strftime/;
use Cwd 'realpath';
use Cwd 'abs_path';
use FileHandle;
use File::Basename;
use File::Find::Rule;
use File::Path qw( make_path );
use File::Spec;
use File::Copy;
use IO::Handle;
use List::MoreUtils qw(uniq);
use diagnostics -verbose;
my $file = $ARGV[0];
print Dumper($file);
die();
my $env = 1;
$Data::Dumper::Indent =2;
$Data::Dumper::Pair = " : ";
my $mongodb_connection = MongoDB::Connection->new(host=>"mongodb://127.0.0.1:27017");
my $database = $mongodb_connection->get_database('unart_parsing');
my $database_name = "unart";
my $database_host = "127.0.0.1";
my $database_uname = "unart";
my $database_pwd = "unart";
my $pg_connection = DBI->connect("dbi:Pg:dbname=$database_name;host=$database_host","$database_uname","$database_pwd");
my $collection = $database->get_collection("parsed")->find();
my $count = $collection->count;
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
		$logfile = "tranzit_".$log_file_data.".log";
		$full_path = File::Spec->catfile( $full_path, $logfile );
		if($env == 0){
			open(STDOUT,'>>',$full_path) or die "Nu se poate creea fisierul pentru log!"; #open file for writing (append)
		} 
	}

	if ( !-d $directories ) {
		make_path $directories or die "Nu se poate creea structura";
	}
if($count > 1){
	my $stmt = $pg_connection->prepare("INSERT INTO first_buffer (id,valoare,coloana,rand,tip,an,luna,fisier,sheet,post,template) VALUES(?,?,?,?,?,?,?,?,?,?,?)");
	#my $stmt = $pg_connection->prepare("INSERT INTO first_buffer2 (data_difuzare,emisiune,minute,secunde,opera,artist,template) VALUES(?,?,?,?,?,?,?)");
	while (my $doc = $collection->next){ 
		$stmt->execute( $doc->{_id}, $doc->{VALOARE}, $doc->{COLOANA}, $doc->{RAND}, $doc->{TIP}, $doc->{AN}, $doc->{LUNA}, $doc->{FISIER}, $doc->{SHEET}, $doc->{POST}, $doc->{TEMPLATE} );
		#if($doc->{TEMPLATE} eq "T1"){
		#	my @insert_data;
		#	my $col = $doc->{COLOANA}; # cache frequently referenced item.
		#	my $rows = $doc->{RAND};
		#	if ( $rows != 0 and $col > 0 and $col != 6 and $col < 8 ) {
		#		$insert_data[$col][$rows] = $doc->{VALOARE};					
		#	}
		#	print Dumper(@insert_data);
			#$stmt->execute( @insert_data[1..6], $doc->{TEMPLATE} );
		#}
	}
	
}

