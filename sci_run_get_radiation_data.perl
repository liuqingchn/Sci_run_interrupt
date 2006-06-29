#!/usr/bin/perl

#########################################################################################
#											#
#	sci_run_get_radiation_data.perl: get NOAA data for radiaiton plots		#
#											#
#		this script must be run on rhodes to access noaa data			#
#											#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jun 29, 2006						#
#											#
#########################################################################################

#################################################################
#
#--- setting directories
#

$bin_dir       = '/data/mta4/MTA/bin/';
$data_dir      = '/data/mta4/MTA/data/';
$web_dir       = '/data/mta/www/mta_interrupt/';
$house_keeping = '/data/mta/www/mta_interrupt/house_keeping/';

#################################################################

#
#--- find today's date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

#
#--- find date of 2 days ago
#

$year = $uyear + 1900;
$mon  = $umon  + 1;
$day  = $umday - 2;

#
#--- for the case, the date we are looking for falls into the previous month...
#

if($day < 1){
	$mon--;
	if($mon < 1){
		$mon = 12;
		$year--;
	}
	if($mon == 1 || $mon == 3 || $mon == 5 ||  $mon == 7 || $mon == 8
		 || $mon == 10 || $mon == 12){
			$day = 31;
	}elsif($mon == 2){
		$chk = 4.0 * int (0.25 * $year);
		if($year == $chk){
			$day = 29;
		}else{
			$day = 28;
		}
	}else{
		$day = 30;
	}
}

if($mon < 10){
	$mon = '0'."$mon";
}

if($day < 10){
	$day = '0'."$day";
}

#
#--- input file name
#

$file_name = '/data/mta4/www/DAILY/mta_rad/ACE/'."$year$mon$day".'_ace_epam_5m.txt';

#
#--- output file name
#

$out_file  = "rad_data$year";

open(FH,  "$file_name");
open(OUT, ">> $house_keeping/$out_file");

#
#--- remove comment lines and append to the data file
#

OUTER:
while(<FH>){
	chomp $_;
	if($_ =~ /^\#/ || $_ =~ /^:/){
		next OUTER;
	}
	print OUT  "$_\n";
}
close(FH);




