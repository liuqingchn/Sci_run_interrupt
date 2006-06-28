#!/usr/bin/perl

#########################################################################################
#											#
#	sci_run_compute_gap.perl: compute science time lost 				#
#				(interuption total - radiation zone)			#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jun 28, 2006						#
#											#
#########################################################################################

#################################################################
#
#--- setting directories
#

$bin_dir       = /data/mta4/MTA/bin/;
$data_dir      = /data/mta4/MTA/data/;
$web_dir       = /data/mta/www/mta_interrupt/;
$house_keeping = /data/mta/www/mta_interrupt/house_keeping/;

$web_dir       = /data/mta/www/mta_interrupt_test/;
$house_keeping = /data/mta/www/mta_interrupt_test/house_keeping/;
#################################################################

$file = $ARGV[0];
#
#--- read radiation zone informtion
#

@rad_zone  = ();
@date_list = ();
open(FH, "$house_keeping/rad_zone_list");

while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@date_list, $atemp[0]);
	push(@rad_zone,  $atemp[1]);
}
close(FH);

open(FH,  "$file");
open(OUT, ">temp_out");

while(<FH>){
#
#--- read data from the list
#
	chomp $_;
	@atemp  = split(/\s+/, $_);
	$date   = $atemp[0];
	$tstart = $atemp[1];
	$tstop  = $atemp[2];
	@btemp  = split(/:/, $atemp[1]);
	$ydate  = find_ydate($btemp[0], $btemp[1], $btemp[2]);
	$time   = "$btemp[3]:$btemp[4]:$btemp[5]";
	$start  = cnv_time_to_t1998($btemp[0],$ydate,$time);
	@btemp  = split(/:/, $atemp[2]);
	$ydate  = find_ydate($btemp[0], $btemp[1], $btemp[2]);
	$time   = "$btemp[3]:$btemp[4]:$btemp[5]";
	$end    = cnv_time_to_t1998($btemp[0],$ydate,$time);
	$stat   = $atemp[4];

	$cnt = 0;
	OUTER:
	foreach $ent (@date_list){
		if($date == $ent){
			last OUTER;
		}
		$cnt++;
	}

	$line  = $rad_zone[$cnt];
	@alist = split(/:/, $line);
	$sum   = 0;

	foreach $ent  (@alist){
		@ctemp = split(/\,/, $ent);
		$p_beg = $ctemp[0];
		$p_end = $ctemp[1];
		$p_beg =~ s/\)//g;
		$p_beg =~ s/\(//g;
		$p_end =~ s/\)//g;
		$p_end =~ s/\(//g;

		$p_beg *= 86400;
		$p_end *= 86400;
		$p_beg += 48902399;
		$p_end += 48902399;
		
		if($p_beg <= $start && $p_end > $start && $p_end <= $end){
			$sum += $p_end - $start;
		}elsif($p_beg >= $start && $p_end <= $end){
			$sum += $p_end - $p_beg;
		}elsif($p_beg >= $start && $p_beg < $end && $p_end > $end){
			$sum += $end - $p_beg;
		}elsif($start >= $p_beg && $end <= $p_end){
			$sum += $end - $start;
		}
	}

	$diff  = $end - $start - $sum;

	$diff /= 1000;
	$gap   = sprintf "%5.1f", $diff;

	print OUT "$date\t$tstart\t$tstop\t$gap\t$stat\n";
}
close(OUT);
close(FH);

system("mv $house_keeping/all_data $house_keeping/all_data~");
system("cp temp_out $file");
system("cat $house_keeping/all_data >> temp_out");
system("mv temp_out $house_keeping/all_data");


##################################################################
### cnv_time_to_t1998: change time format to sec from 1998.1.1 ###
##################################################################

sub cnv_time_to_t1998{

#######################################################
#       Input   $year: year
#               $ydate: date from Jan 1
#               $hour:$min:$sec:
#
#       Output  $t1998<--- returned
#######################################################

        my($totyday, $totyday, $ttday, $t1998);
        my($year, $ydate, $hour, $min, $sec);
        ($year, $ydate, $hour, $min, $sec) = @_;

        $totyday = 365*($year - 1998);
        if($year > 2000){
                $totyday++;
        }
        if($year > 2004){
                $totyday++;
        }
        if($year > 2008){
                $totyday++;
        }
        if($year > 2012){
                $totyday++;
        }

        $ttday = $totyday + $ydate - 1;
        $t1998 = 86400 * $ttday  + 3600 * $hour + 60 * $min +  $sec;

        return $t1998;
}


##################################################
### find_ydate: change month/day to y-date     ###
##################################################

sub find_ydate {

##################################################
#       Input   $tyear: year
#               $tmonth: month
#               $tday:   day of the month
#
#       Output  $ydate: day from Jan 1<--- returned
##################################################

        my($tyear, $tmonth, $tday, $ydate, $chk);
        ($tyear, $tmonth, $tday) = @_;

        if($tmonth == 1){
                $ydate = $tday;
        }elsif($tmonth == 2){
                $ydate = $tday + 31;
        }elsif($tmonth == 3){
                $ydate = $tday + 59;
        }elsif($tmonth == 4){
                $ydate = $tday + 90;
        }elsif($tmonth == 5){
                $ydate = $tday + 120;
        }elsif($tmonth == 6){
                $ydate = $tday + 151;
        }elsif($tmonth == 7){
                $ydate = $tday + 181;
        }elsif($tmonth == 8){
                $ydate = $tday + 212;
        }elsif($tmonth == 9){
                $ydate = $tday + 243;
        }elsif($tmonth == 10){
                $ydate = $tday + 273;
        }elsif($tmonth == 11){
                $ydate = $tday + 304;
        }elsif($tmonth == 12 ){
                $ydate = $tday + 333;
        }
        $chk = 4 * int (0.25 * $tyear);
        if($chk == $tyear && $tmonth > 2){
                $ydate++;
        }
        return $ydate;
}
