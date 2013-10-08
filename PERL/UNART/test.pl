use POSIX;
 use Data::Dumper;
my $test = "7,1,2012";
my @splitted = split(',',$test);
my $return = @splitted[2] . '-' . @splitted[1] . '-' . @splitted[0];
print Dumper($return);

my $min = '2.0';
my $sec = '35.06';
my $dif = '3';
my $total = (($min * 60) + $sec) * $dif;
print $total;