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
#use diagnostics -verbose;
my $limit = $ARGV[0];
my $env = 0;
$Data::Dumper::Indent = 2;
$Data::Dumper::Pair = " : ";
my $mongodb_connection = MongoDB::Connection->new(host=>"mongodb://127.0.0.1:27017");
my $database = $mongodb_connection->get_database('unart_parsing');
my $database_name = "unart";
my $database_host = "127.0.0.1";
my $database_uname = "postgres";
my $database_pwd = "postgres";
my $pg_connection = DBI->connect("dbi:Pg:dbname=$database_name;host=$database_host","$database_uname","$database_pwd");
my $collection = $database->get_collection("parsed")->find( { STATUS => 0} )->limit($limit);
my $count = $collection->count;
my $log_data = strftime("%Y-%m-%d %H-%M-%S", localtime);
my $log_file_data = strftime("%Y-%m-%d", localtime);
	#
	# Log file and structure
	#
	my $full_path = "/var/www/html/unart/LOGS/";
	my ( $logfile, $directories ) = fileparse $full_path;
	if ( !$logfile ) {
		$logfile = "tranzit.log";
		$full_path = File::Spec->catfile( $full_path, $logfile );
		if($env == 0){
			open(STDOUT,'>>',$full_path) or die "Nu se poate creea fisierul pentru log!"; #open file for writing (append)
		} 
	}

	if ( !-d $directories ) {
		make_path $directories or die "Nu se poate creea structura";
	}	
if($count > 1){
	my $stmt = $pg_connection->prepare("INSERT INTO first_buffer (fb_data_difuzare,fb_emisiune,fb_minute,fb_secunde,fb_opera,fb_artist,fb_template,fb_luna,fb_an,fb_post,fb_nr_difuzari,fb_import_id,fb_import_timestamp) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)");
	print STDOUT $log_data.":".$limit,"\n";
	while (my $doc = $collection->next){ 	
		$database->get_collection("parsed")->update( { _id => $doc->{_id} }, { '$set' => { STATUS => 1 } } );
		$stmt->execute( $doc->{DATA_DIFUZARE}, $doc->{EMISIUNE}, $doc->{MINUTE}, $doc->{SECUNDE}, $doc->{OPERA}, $doc->{ARTIST}, $doc->{TEMPLATE}, $doc->{LUNA}, $doc->{AN}, $doc->{POST}, $doc->{NR_DIFUZARI}, $doc->{_id}, $log_data );
	}
	
}

