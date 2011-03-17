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
#		last update: Mar 17, 2011						#
#											#
#########################################################################################

#################################################################
#
#--- setting directories
#

open(FH, "/data/mta/Script/Interrupt/house_keeping/dir_list");

@atemp = ();
while(<FH>){
        chomp $_;
        push(@atemp, $_);
}
close(FH);

$bin_dir       = $atemp[0];
$data_dir      = $atemp[1];
$web_dir       = $atemp[2];
$house_keeping = $atemp[3];

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
			$day = 31 - $day;
	}elsif($mon == 2){
		$chk = 4.0 * int (0.25 * $year);
		if($year == $chk){
			$day = 29 - $day;
		}else{
			$day = 28 - $day;
		}
	}else{
		$day = 30 - $day;
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




