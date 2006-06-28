#!/usr/bin/perl

#########################################################################################
#											#
# 	sci_run_ephin_plot_main.perl: a drving script to extract and plot ephin data.	#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		this script needs another script: get_ephin.perl			#
#											#
#		last update: Jun 28, 2006						#
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

$web_dir       = '/data/mta/www/mta_interrupt_test/';
$house_keeping = '/data/mta/www/mta_interrupt_test/house_keeping/';
#################################################################

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

	system("perl $bin_dir/get_ephin.perl $start[$k] $end[$k] $usr $pword $name[$k]");

	$data_file_name = "$web_dir".'/Data_dir/'."$name[$k]".'_eph.txt';
	system("mv ephin_data.txt $data_file_name");

	$gif_name       = "$web_dir".'/Ephin_plot/'."$name[$k]".'_eph.gif';
	$ps_name        = "$web_dir".'/Ps_dir/'."$name[$k]".'_eph.ps';

	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $gif_name");

	system("mv pgplot.ps $ps_name");
}
