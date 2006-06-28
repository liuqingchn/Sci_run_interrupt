#!/usr/bin/perl

#########################################################################################
#											#
# 	ephin_plot_main.perl: a drving script to extract and plot ephin data.		#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		this script needs another script: get_ephin.perl			#
#											#
#		last update: Jun 27, 2006						#
#											#
#########################################################################################

#
#--- set directories
#

$bin_dir = '/data/mta/MTA/bin/';

#
#-- input file name
#

print "Input file: ";
$data_file = <STDIN>;
chomp $data_file;

#
#--- arc4gl user name
#

print "User: ";
$usr = <STDIN>;
chomp $usr;

#
#--- arc4gl password
#

print "PSWD: ";
$pword = <STDIN>;
chomp $pword;

open(FH, "$data_file");
@name  = ();
@start = ();
@stop  = ();
$total = 0;

while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@name,$atemp[0]);
	push(@start, $atemp[1]);
	push(@end, $atemp[2]);
	$total++;
}
close(FH);

for($k = 0; $k < $total; $k++){

#
#--- call get_ephin.perl which actually extracts ephin data from archieve
#

	system("perl ./get_ephin.perl $start[$k] $end[$k] $usr $pword $name[$k]");
####	system("perl $bin_dir/get_ephin.perl $start[$k] $end[$k] $usr $pword $name[$k]");

	$new_name  = './Ephin_plot/'."$name[$k]".'_eph.gif';
	$new_name2 = "$name[$k]".'_eph.ps';

	$data_file_name = "$name[$k]".'_eph.txt';
	system("mv ephin_data.txt ./Data_dir/$data_file_name");

	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $new_name");

	system("mv pgplot.ps ./Ps_dir/$new_name2");
}
