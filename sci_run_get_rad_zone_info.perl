#!/usr/bin/perl

#########################################################################################
#											#
#	sci_run_get_rad_zone_info.perl: find expected radiation zone timing		#
#											#
#	    this script must be run on rhodes to see the radiation zone information	#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: May 30, 2007						#
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
#---if you supply year and month, this script extracts rad zone information
#--- for that month and the next. otherwise, this month and the next
#

$year = $ARGV[0];
$mon  = $ARGV[1];

if($year =~ /\d/ && $mon =~ /\d/){
	$umon = $mon--;
}else{

#
#--- find today's date
#

	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

	$year = $uyear + 1900;
	$cmon = $umon + 1;
}

#
#--- change the month name from a digit to a word
#

month_dig_lett();

$year1 = $year;
$mon1  = $cmon;

#
#--- check also the next month
#

$year2 = $year1;
$cmon  = $umon + 2;

if($cmon > 12){
	$year2++;
	$cmon = 1;
}

month_dig_lett();

$mon2  = $cmon;

#
#--- extract radiation zone information for this month and the next
#

$name = "$mon1".'*';
system("cat /data/mpcrit1/mplogs/$year1/$name/ofls/*dot|grep RADZONE >  ./zout");

$name = "$mon2".'*';
system("cat /data/mpcrit1/mplogs/$year2/$name/ofls/*dot|grep RADZONE >> ./zout");

#
#---- extract needed information (entry/exit and date)
#

$infile    = 'zout';
@line_save = ();

clean_entry();

system("rm zout");

#
#--- read the past data
#

open(FH, "$house_keeping/rad_zone_info");
@rad_zone = ();
$cnt      = 0;
while(<FH>){
	chomp $_;
	push(@rad_zone, $_);
	$cnt++;
}
close(FH);

#
#--- append the new information
#

foreach $ent (@line_save){
	push(@rad_zone, $ent);
	$cnt++;
}

#
#--- sort by time
#

@save = ();
foreach $ent (@rad_zone){
	@atemp  = split(/\s+/, $ent);
	$line = "$atemp[1]\t$atemp[2]\t$atemp[0]";
	push(@save, $line);
}

@temp = sort{$a<=>$b}@save;

#
#--- remove duplicates
#

$chk = shift(@temp);
@new = ("$chk");
OUTER:
foreach $ent (@temp){
	if($ent =~ /$chk/){
		next OUTER;
	}
	push(@new, $ent);
	$chk = $ent;
}
	

#
#---  before print out the data, make sure that no two enter(or exit) occurs 
#---  consequtively
#

$ind = '';
system("mv $house_keeping/rad_zone_info $house_keeping/rad_zone_info~");

open(OUT, ">$house_keeping/rad_zone_info");
OUTER:
foreach $ent (@new){
	@atemp = split(/\s+/, $ent);
	if($atemp[2] =~ /$ind/){
		$ind = $atemp[2];
		next OUTER;
	}
	$ind = $atemp[2];
	print OUT "$atemp[2]\t$atemp[0]\t$atemp[1]\n";
}

###############################################################################
### clean_entry: extract only needed information from rad zone info         ###
###############################################################################

sub clean_entry{

	open(FH, "$infile");
	while(<FH>){
		chomp $_;
		$_ =~ s/ATS\,2_RADZONE_//g;
		$_ =~ s/\,TIME=/<>/g;
		@atemp = split(/\s+/, $_);
		$line = $atemp[0];
		@atemp = split(/<>/, $line);
		$time  = $atemp[1];
		find_dom();
		$line = "$atemp[0]\t$dom\t$atemp[1]";
		push(@line_save, $line);
	}
	close(FH);
}
		

###############################################################################
### find_dom: find DOM from year/ydate/hour/min/sec                         ###
###############################################################################

sub find_dom{
        @btemp = split(/:/, $time);
        $dom = $btemp[1] + $btemp[2]/24 + $btemp[3]/1440.0 + $btemp[4]/86400.0;
        if($btemp[0] == 1999){
                $dom -= 202;
        }else{
                $dom = $dom + 163 + ($btemp[0] - 2000) * 365;
                if($btemp[0] > 2000) {
                        $dom++;
                }
                if($btemp[0] > 2004) {
                        $dom++;
                }
                if($btemp[0] > 2008) {
                        $dom++;
                }
                if($btemp[0] > 2012) {
                        $dom++;
                }
        }
}

#############################################################
### month_dig_lett: change month name from digit to letter ##
#############################################################

sub month_dig_lett {
        if($cmon == 1){
                $cmon ='JAN';
        }elsif($cmon == 2) {
                $cmon ='FEB';
        }elsif($cmon == 3) {
                $cmon ='MAR';
        }elsif($cmon == 4) {
                $cmon ='APR';
        }elsif($cmon == 5) {
                $cmon ='MAY';
        }elsif($cmon == 6) {
                $cmon ='JUN';
        }elsif($cmon == 7) {
                $cmon ='JUL';
        }elsif($cmon == 8) {
                $cmon ='AUG';
        }elsif($cmon == 9) {
                $cmon ='SEP';
        }elsif($cmon == 10) {
                $cmon ='OCT';
        }elsif($cmon == 11) {
                $cmon ='NOV';
        }elsif($cmon == 12) {
                $cmon ='DEC';
        }
}

