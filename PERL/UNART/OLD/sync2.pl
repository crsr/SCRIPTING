use warnings;
use DBI;
use Data::Dumper;
$Data::Dumper::Indent =3;
$Data::Dumper::Pair = " : ";


my $database_name = "unart";
my $database_host = "127.0.0.1";
my $database_uname = "unart";
my $database_pwd = "unart";
my $pg_connection = DBI->connect("dbi:Pg:dbname=$database_name;host=$database_host","$database_uname","$database_pwd");

my $artists = $pg_connection->prepare("SELECT (firstname || ' ' || lastname) as artist_name FROM public.artists WHERE status = 't'");
$artists->execute();
my @rows = map {$_->[0]} @{$artists->fetchall_arrayref};
	foreach my $row(@rows){
	my @splitter = split /\s+/,$row;
	foreach my $split (@splitter){
		print $split,"\n";
		print scalar(keys %splitter),"\n";
	}
	 print Dumper(@splitter);
	#print scalar(grep {define $_} @splitter);	
}
die();


	my $stmt = $pg_connection->prepare("INSERT INTO first_buffer (id,valoare,coloana,rand,tip,an,luna,fisier,sheet) VALUES(?,?,?,?,?,?,?,?,?)");
	
	
		$stmt->execute($doc->{_id},$doc->{VALOARE},$doc->{COLOANA},$doc->{RAND},$doc->{TIP},$doc->{AN},$doc->{LUNA},$doc->{FISIER},$doc->{SHEET});
		

	


