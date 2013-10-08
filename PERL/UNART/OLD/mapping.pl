#use strict;
use warnings;
#use Mango;
use DBI;
use POSIX qw/strftime/;
use File::Basename;
use File::Spec;
use File::Path qw( make_path );
#use MongoDB::Examples;
use MongoDB::Connection;
use MongoDB::Database;
use MongoDB::Cursor;
use Data::Dumper;
$Data::Dumper::Indent = 2;
$Data::Dumper::Pair = " : ";
my $mongodb_connection = MongoDB::Connection->new(host=>"mongodb://127.0.0.1:27017");
my $database = $mongodb_connection->get_database('unart_parsing');
my $data_base_name = "unart";
my $data_base_host = "127.0.0.1";
my $data_base_uname = "unart";
my $data_base_pwd = "unart";
my $pg_connection = DBI->connect("dbi:Pg:dbname=$data_base_name;host=$data_base_host", "$data_base_uname", "$data_base_pwd");
my $artists = $pg_connection->prepare("SELECT (firstname || ' ' || lastname) as artist_name FROM public.artists");
$artists->execute();

my @rows = map {$_->[0]} @{$artists->fetchall_arrayref};
foreach my $row(@rows){
	my @split = split(/\s+/,$row);
	print Dumper(@split);
	#$search_matches = $mango->db('unart_parsing')->collection('parsed')->find({VALOARE=>gr/Ioana/})->count();
	my $collection = $database->get_collection('parsed')->find({"VALOARE"=>"/videograma/"});
	#print Dumper($collection);
	my $num = $collection->count;
	print $num;
	#my @objects = $collection->all;
	#	print Dumper(@objects);
	#while( my $finded = $collection->next){
	#	print Dumper($finded);
	#}

}
die();
