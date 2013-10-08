#
#	
#	Start chain scripts:
#	1. folders_processing.pl
#	2. files_processing.pl
#	3. filter_process.pl
#	4. empty_folders_processing.pl
#
#	This script will be called from app!!
#	[UNART - INCRYS]
#
	use strict;
        use warnings;
	use File::Path qw( make_path );
	make_path("/var/www/html/LOGS/");
	#system("perl D:\\WORK\\REPOS\\PERL\\UNART\\folders_renaming.pl");
	system("perl /var/perl-scripts/PERL/UNART/folders_processing.pl");	
