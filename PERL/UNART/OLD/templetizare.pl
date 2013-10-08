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


my $fb = $pg_connection->prepare("SELECT * FROM public.first_buffer");
$fb->execute();
my ($id,$valoare,$coloana,$rand,$tip,$an,$luna,$fisier,$sheet,$post,$template);
$fb->bind_columns(\($id,$valoare,$coloana,$rand,$tip,$an,$luna,$fisier,$sheet,$post,$template));
while($fb->fetch){
	my $stmt = $pg_connection->prepare("INSERT INTO first_buffer2 (data_difuzare,emisiune,minute,secunde,opera,artist,template) VALUES(?,?,?,?,?,?,?)");
	if($template eq "T1"){
		my @insert_data;
		if ( $coloana >= 0 and $coloana != 6 and $coloana < 8 ) {
				if($rand != 0) {
					if($coloana == 0){
						$insert_data[0] = $valoare;
					} elsif($coloana == 1){
						$insert_data[1] = $valoare;
					} elsif($coloana == 2){
						$insert_data[2] = $valoare;
					}
					$fb->execute( @insert_data[0], @insert_data[1], @insert_data[2], @insert_data[3], @insert_data[4], @insert_data[5], "T1" );
					print Dumper(@insert_data);
				}					
			}
	}
}


