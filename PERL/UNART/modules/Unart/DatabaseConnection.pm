package Unart::DatabaseConnection;
use strict;
use warnings;
use Mango;
use DBI;

my $mango->new('mongodb://127.0.0.1:27017'); # DB connection


my $database_name = "unart";
my $database_host = "127.0.0.1";
my $database_uname = "unart";
my $database_pwd = "unart";
my $pg_connection = DBI->connect("dbi:Pg:dbname=$database_name;host=$database_host","$database_uname","$database_pwd");

my $mongo_database = 'unart_parsing';
my $mongo_collection = 'parsed';

my $var = 'var1';
