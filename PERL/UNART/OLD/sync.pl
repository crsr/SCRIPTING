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
#my $pg_connection2 = DBI->connect("dbi:Pg:dbname=$database_name;host=$database_host","$database_uname","$database_pwd");
#select all active artists
my $artists = $pg_connection->prepare("SELECT id,(firstname || ' ' || lastname) as artist_name FROM public.artists WHERE status = 't'");
$artists->execute();
my ($artist_id,$artist_name);
$artists->bind_columns(\($artist_id,$artist_name));
while($artists->fetch){
	#for each artist, search records in frist_buffer

	my $matches = $pg_connection->prepare("SELECT * FROM public.first_buffer WHERE valoare ilike '%$artist_name%'");
	#
	# cautam restul celulelor din rand.
	#
	#
	$matches->execute();
	my ($id,$valoare,$coloana,$rand,$tip,$an,$luna,$fisier,$sheet);
	$matches->bind_columns(\($id,$valoare,$coloana,$rand,$tip,$an,$luna,$fisier,$sheet));
	while($matches->fetch){
		print Dumper($rand); 
		my $matches_first_rows = $pg_connection->prepare("SELECT * FROM public.first_buffer WHERE rand = '$rand' AND coloana <> '$coloana' AND fisier = '$fisier' AND sheet = '$sheet' ");
		$matches_first_rows->execute();
		#$matches_first_rows->bind_columns(\($id,$valoare,$coloana,$rand,$tip,$an,$luna,$fisier,$sheet));
		
		while(my $ref =  $matches_first_rows->fetchrow_hashref()){
			my @values = $ref->{valoare};
			print Dumper(@values);
		#$insert = $pg_connection->prepare("INSERT INTO second_buffer (id,valoare,coloana,rand,tip,an,luna,fisier,sheet) VALUES(?,?,?,?,    ?,?,?,?,?)");
                #$insert->execute();
		}
	}
}
#my @match_artists = $artists->fetchall_arrayref([0]);
#my @match_artists_name = $artists->fetchall_arrayref([1]);
#print Dumper(@match_artists);
#print Dumper($test->[0]); 
#my @artists_id = map {$_->[0]} @{$artists->fetchall_arrayref};
#my @artists_name = map {$_->[1]} @{$artists->fetchall_arrayref};
#print Dumper(@artists_id);
#print Dumper(@artists_name);


#foreach my $row(@match_artists){
#while(@row = $artists->fetchall_arrayref){
#print Dumper($row->{1});
#print Dumper($row->[1]),"\n";
#my $matches = $pg_connection->prepare("SELECT * FROM public.first_buffer WHERE valoare ilike '%%'");
#$matches->execute();
#while(@rows_matches = $matches->fetchrow_array){
 # print @rows_matches,"\n";
#}
#my @rows_matches = mi-fetchmap {$_->[0]} @{$matches->fetchall_arrayref};

#foreach my $rowf(@rows_matches){
#	print Dumper($rowf);

#}#
#}

#	foreach my $row(@rows){
#	my @splitter = split /\s+/,$row;
#	foreach my $split (@splitter){
#		print $split,"\n";
#		print scalar(keys %splitter),"\n";
#	}
#	 print Dumper(@splitter);
	#print scalar(grep {define $_} @splitter);	
#}
die();


	my $stmt = $pg_connection->prepare("INSERT INTO first_buffer (id,valoare,coloana,rand,tip,an,luna,fisier,sheet) VALUES(?,?,?,?,?,?,?,?,?)");
	
	
		$stmt->execute($doc->{_id},$doc->{VALOARE},$doc->{COLOANA},$doc->{RAND},$doc->{TIP},$doc->{AN},$doc->{LUNA},$doc->{FISIER},$doc->{SHEET});
		

	



