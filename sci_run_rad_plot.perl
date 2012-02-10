#!/usr/bin/perl 
use PGPLOT;

#################################################################################
#										#
#	extract_ephin.perl: extract Ephin data and plot the results		#
#										#
#		author: t. isobe (tisobe@cfa.harvard.edu)			#
#										#
#		last update: Feb 10, 2012					#
#										#
#################################################################################


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


$dare   = `cat $data_dir/.dare`;
$hakama = `cat $data_dir/.hakama`;
chomp $dare;
chomp $hakama;

################################################################

#
#--- data input example: 
#
#	name       start             stop
#	20061213   2006:12:13:22:44  2006:12:16:13:42
#

$file = $ARGV[0];
open(FH, "$file");
$input = <FH>;
close(FH);
chomp $input;
@atemp = split(/\s+/, $input);

$name  = $atemp[0];
$begin = $atemp[1];		#--- sci run interruption started
$end   = $atemp[2];		#--- sci run interruption finished

#
#--- change date  to fractional year format
#
@atemp = split(/:/, $begin);
$byear = $atemp[0];
$bmon  = $atemp[1];
$bday  = $atemp[2];
$bhour = $atemp[3];
$bmin  = $atemp[4];

$rstart = date_to_fyear($byear, $bmon, $bday, $bhour, $bmin);

@atemp = split(/:/, $end);
$eyear = $atemp[0];
$emon  = $atemp[1];
$eday  = $atemp[2];
$ehour = $atemp[3];
$emin  = $atemp[4];

$rstop = date_to_fyear($eyear, $emon, $eday, $ehour, $emin);

#
#--- read radiaiton zone for the period named "$name"
#--- this need $house_keeping/rad_zone_list with the current data
#

read_rad_zone();


#
#-- set up the ploting period: start begin 2 days before the interruption
#

$pyear = $byear;
$pmon  = int($bmon);
$pday  = int($bday -2);
$phour = int($bhour);
$pmin  = int($bmin);


if($pday < 1){
	$pmon = $bmon -1;
	if($pmon < 1){
		$pmon  = 12;
		$pyear = $byear -1;
		$pday  = 31 + $pday;
	}else{
		if($pmon == 2){
			$chk   = 4.0 *int(0.25 * $pyear);
			if($chk == $pyear){
				$pday =  29 + $pday;
			}else{
				$pday =  28 + $pday;
			}
		}elsif($pmon ==1 || $pmon == 3 || $pmon == 5 || $pmon == 7
			|| $pmon == 8  || $pmon == 10){
				$pday = 31 + $pday;
		}else{
				$pday = 30 + $pday;
		}
	}
}

#
#--- the plotting period finishes 5 days after the plot starting date
#

$peyear = $pyear;
$pemon  = int($pmon);
$peday  = int($pday +5);
$pehour = int($phour);
$pemin  = int($pmin);

if($pemon == 2){
	$chk   = 4.0 *int(0.25 * $peyear);
	if($chk == $peyear){
		$base = 29;
	}else{
		$base = 28;
	}
	if($peday > $base){
		$pemon = 3;
		$peday -= $base;
	}
}elsif($pemon ==12){
	if($peday > 31){
		$peyear++;
		$pemon = 1;
		$peday -= 31;
	}
}elsif($pemon ==1 || $pemon == 3 || $pemon == 5 || $pemon == 7
	|| $pemon == 8  || $pemon == 10){
	if($peday > 31){
		$pemon++;
		$peday -= 31;
	}
}else{
	if($peday > 30){
		$pemon++;
		$peday -= 30;
	}
}

#
#--- adjust naming format, and change into fraq year format
#

if($pmon < 10){
	$pmon = '0'."$pmon";
}
if($pday < 10){
	$pday = '0'."$pday";
}
if($phour < 10){
	$phour = '0'."$phour";
}
if($pmin < 10){
	$pmin = '0'."$pmin";
}

$start = date_to_fyear($pyear, $pmon, $pday, $phour, $pmin);
$start_ydate = find_ydate($pyear, $pmon, $pday);

if($pemon < 10){
	$pemon = '0'."$pemon";
}
if($peday < 10){
	$peday = '0'."$peday";
}
if($pehour < 10){
	$pehour = '0'."$pehour";
}
if($pemin < 10){
	$pemin = '0'."$pemin";
}

$stop = date_to_fyear($peyear, $pemon, $peday, $pehour, $pemin);
$stop_ydate = find_ydate($peyear, $pemon, $peday);


#
#--- if the interruption time is longer than the plotting period, run the second
#--- round of the plotting routine, and create another panel.
#

$run_second = 0;
if($rstop > $stop){
	$run_second = 1;

#
#-- for this plot, set up the ploting period: start begin 3 days after the interruption
#

	$p2year = $byear;
	$p2mon  = int($bmon);
	$p2day  = int($bday +3);
	$p2hour = int($bhour);
	$p2min  = int($bmin);
	
	
	if($p2day < 1){
		$p2mon = $bmon -1;
		if($p2mon < 1){
			$p2mon  = 12;
			$p2year = $byear -1;
			$p2day  = 31 + $p2day;
		}else{
			if($p2mon == 2){
				$chk   = 4.0 *int(0.25 * $p2year);
				if($chk == $p2year){
					$p2day =  29 + $p2day;
				}else{
					$p2day =  28 + $p2day;
				}
			}elsif($p2mon ==1 || $p2mon == 3 || $p2mon == 5 || $p2mon == 7
				|| $p2mon == 8  || $p2mon == 10){
					$p2day = 31 + $p2day;
			}else{
					$p2day = 30 + $p2day;
			}
		}
	}
	
#
#--- the plotting period finishes 5 days after the plot starting date
#
	
	$p2eyear = $p2year;
	$p2emon  = int($p2mon);
	$p2eday  = int($p2day +5);
	$p2ehour = int($p2hour);
	$p2emin  = int($p2min);
	
	if($p2emon == 2){
		$chk   = 4.0 *int(0.25 * $p2eyear);
		if($chk == $p2eyear){
			$base = 29;
		}else{
			$base = 28;
		}
		if($p2eday > $base){
			$p2emon = 3;
			$p2eday -= $base;
		}
	}elsif($p2emon ==12){
		if($p2eday > 31){
			$p2eyear++;
			$p2emon = 1;
			$p2eday -= 31;
		}
	}elsif($p2emon ==1 || $p2emon == 3 || $p2emon == 5 || $p2emon == 7
		|| $p2emon == 8  || $p2emon == 10){
		if($p2eday > 31){
			$p2emon++;
			$p2eday -= 31;
		}
	}else{
		if($p2eday > 30){
			$p2emon++;
			$p2eday -= 30;
		}
	}

#
#--- adjust naming format, and change into fraq year format
#

	if($p2mon < 10){
		$p2mon = '0'."$p2mon";
	}
	if($p2day < 10){
		$p2day = '0'."$p2day";
	}
	if($p2hour < 10){
		$p2hour = '0'."$p2hour";
	}
	if($p2min < 10){
		$p2min = '0'."$p2min";
	}
	
	$start2 = date_to_fyear($p2year, $p2mon, $p2day, $p2hour, $p2min);
	
	if($p2emon < 10){
		$p2emon = '0'."$p2emon";
	}
	if($p2eday < 10){
		$p2eday = '0'."$p2eday";
	}
	if($p2ehour < 10){
		$p2ehour = '0'."$p2ehour";
	}
	if($p2emin < 10){
		$p2emin = '0'."$p2emin";
	}
	
	$stop2 = date_to_fyear($p2eyear, $p2emon, $p2eday, $p2ehour, $p2emin);
}



@btemp = split(//, $pyear);
$arc_start = "$pmon/$pday/$btemp[2]$btemp[3],$phour:$pmin:00";

if($run_second == 0){
	@btemp = split(//, $peyear);
	$arc_stop = "$pemon/$peday/$btemp[2]$btemp[3],$pehour:$pemin:00";
}else{
	@btemp = split(//, $p2eyear);
	$arc_stop = "$p2emon/$p2eday/$btemp[2]$btemp[3],$p2ehour:$p2emin:00";
}

#
#--- data extraction starts here
#

open(PR, '>./arch_file');
print PR "operation=retrieve\n";
print PR "dataset=flight\n";
print PR "detector=ephin\n";
print PR "level=1\n";
print PR "filetype=ephrates\n";
print PR "tstart=$arc_start\n";
print PR "tstop=$arc_stop\n";
print PR "go\n";
close(PR);

system(" echo $hakama |arc4gl -U$dare -Sarcocc -i arch_file");
system("mv ephinf*.gz Working_dir");
system("gzip -d ./Working_dir/*gz");
system("ls ./Working_dir/ephinf*_lc1.fits > zlist");
system('rm arch_file');

#
#--- read the data and save needed data points
#

@list  = ();
@xdate = ();
@p4    = ();
@p41   = ();
@e1300 = ();
@e150  = ();
$tot   = 0;

open(FH, './zlist');

while(<FH>){
	chomp $_;
	push(@list, $_);

	$input_file = $_;

#	$line = "$input_file".'[cols time, scp4, scp41, sce1300]';
	$line = "$input_file".'[cols time, sce150, sce1300]';
	system("dmlist \"$line\" opt='data' > ./zout");

	open(IN, './zout');
	while(<IN>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($atemp[1] =~ /\d/ && $atemp[2] =~ /\d/
			&& $atemp[3] =~ /\d/ && $atemp[4] =~ /\d/){
			$in_time = `axTime3 $atemp[2] u s u d`;

			to_dofy2();

			push(@xdate, $dofy);
			if($atemp[3] == 0){
				$atemp[3] = 1.0e-4;
			}
			if($atemp[4] == 0){
				$atemp[4] = 1.0e-4;
			}
			if($atemp[5] == 0){
				$atemp[5] = 1.0e-4;
			}
#			$p4d    = (log($atemp[3]))/2.302585093;
#			$p41d   = (log($atemp[4]))/2.302585093;
#			$e1300d = (log($atemp[5]))/2.302585093;
#			push(@p4,    $p4d);
#			push(@p41,   $p41d);
#			push(@e1300, $e1300d);

#			push(@p4,    $atemp[3]);
#			push(@p41,   $atemp[4]);
			push(@e150,  $atemp[3]);
			push(@e1300, $atemp[4]);
			$tot++;
		}
	}
	close(IN);
	system("rm ./zout");
}
close(FH);
system("rm ./zlist");
system("rm ./Working_dir/*fits");


#
#--- find HRC sheild rate
#

#
#--- set dataseeker input file
#

open(OUT, '>./ds_file');
print OUT 'columns=mtahrc..hrcveto_avg',"\n";
print OUT 'timestart='."$pyear:$start_ydate:$phour:$pmin:00\n";
print OUT 'timestop='."$peyear:$stop_ydate:$pehour:$pemin:00\n";
close(OUT);

#
#--- call dataseeker
#

system("rm ./veto.fits");
system("punlearn dataseeker; dataseeker.pl infile=ds_file print=yes outfile=veto.fits");
system("dmlist \"veto.fits[cols time,shevart_avg]\" outfile=sheild_events.dat opt=data");

@time = ();
@veto = ();
$count = 0;

open(FH, "./sheild_events.dat");

$kstart = 0;
OUTER:
while(<FH>){
        chomp $_;
        @atemp = split(/\s+/, $_);
        if($atemp[3] =~/\d/){
		$ttime = sec1998_to_fracyear($atemp[2]);
		$tyear = int($ttime);
		$chk   = 4.0 * int(0.25 * $tyear);
		$base  = 365;
		if($chk == $tyear){
			$base = 366;
		}
		$fdate = $base * ($ttime - $tyear);

                push(@time, $fdate);
                push(@veto, $atemp[3]);
                $count++;
        }elsif($atemp[3] eq ''){
		$ttime = sec1998_to_fracyear($atemp[1]);
		$tyear = int($ttime);
		$chk   = 4.0 * int(0.25 * $tyear);
		$base  = 365;
		if($chk == $tyear){
			$base = 366;
		}
		$fdate = $base * ($ttime - $tyear);

                push(@time, $fdate);
                push(@veto, $atemp[2]);
                $count++;
        }
}
close(FH);


@hrc = ();
$j = 0;
$k = 0; 

if($time[0] < $xdate[0]){
	while($time[$j] < $xdate[0]){
		$j++;
	}
}elsif($time[0] > $xdate[0]){
	while($teim[0] > $xdate[$k]){
		$k++;
	}
}
$hrc[$k] = $veto[$j];

$range = 1.38888888888e-3 / $base;

for($i = $k+1; $i < $tot; $i++){


	$tbeg = $xdate[$i] - $range;
	$tend = $xdate[$i] + $range;
###print "I AM HERE2: $j<---: $time[$j] <--> $tbeg<--->$tend<--> $xdate[$i]\n";
	if($j > $count - 2){
		$hrc[$i] = $veto[$cnt-1];

	}elsif($time[$j] >=$tbeg && $teim[$j] < $tend){
		$hrc[$i] = $veto[$j];

	}elsif($time[$j] < $tbeg){
		while($time[$j] < $tbeg){
			$j++;
		}
		$hrc[$i] = $veto[$j];

	}elsif($time[$j] >= $tend){
		while($time[$j] >= $tend){
			$j--;
		}
		$hrc[$i] = $veto[$j];
	}
}



#
#--- printing out the data
#

$out = "/data/mta_www/mta_interrupt/Data_dir/$name".'_eph.txt';

open(OUT, ">$out");
print OUT "Scient Run Interruption: $begin\n\n";
print OUT "dofy\t\hrc\t\te150\t\te1300\n";
print OUT "-------------------------------------------------------------------\n";

for($m = 0; $m < $tot; $m++){
	$sdate = sprintf "%4.3f", $xdate[$m];
#	$p4s   = sprintf "%4.3e", $p4[$m];
#	$p41s  = sprintf "%4.3e", $p41[$m];
	$hrcs  = sprintf "%4.3e", $hrc[$m];
	$e150s = sprintf "%4.3e", $e150[$m];
	$e1300s= sprintf "%4.3e", $e1300[$m];
#	print OUT "$sdate\t\t$p4s\t$p41s\t$e1300s\n";
	print OUT "$sdate\t\t$hrcs\t$e150s\t$e1300s\n";
}


#
#--- setting for stat info gathering
#

$hrcmin  = 1e14;
$hrctmin = 0;
$hrcmax  = 1e-14;
$hrctmax = 0;
$hrcint  = -999;
$sum4    = 0;
$sum4_2  = 0;
$stot4   = 0;

$e150min  = 1e14;
$e150tmin = 0;
$e150max  = 1e-14;
$e150tmax = 0;
$e150int  = -999;
$sum41    = 0;
$sum41_2  = 0;
$stot41   = 0;

$e1300min   = 1e14;
$e1300tmin  = 0;
$e1300max   = 1e-14;
$e1300tmax  = 0;
$e1300int   = -999;
$sume1300   = 0;
$sume1300_2 = 0;
$stote1300  = 0;

#
#--- plot starts here
#

#
#--- set overall y axis range
#

$ymin = -3;
@temp = sort{$a<=>$b} @hrc;
$ymax = $temp[$cnt-1];
$ymax = int(log($ymax)/2.302585093) + 1;

@temp = sort{$a<=>$b} @e150;
$ymax2= $temp[$cnt-1];
$ymax2= int(log($ymax)/2.302585093) + 1;

if($ymax2 > $ymax){
	$ymax = $ymax2;
}

@temp = sort{$a<=>$b} @e1300;
$ymax3= $temp[$cnt-1];
$ymax3= int(log($ymax)/2.302585093) + 1;

if($ymax3 > $ymax){
	$ymax = $ymax3;
}
$ymax++;

#
#--- date for the plotting is ydate. 
#

@atemp = split(/\./, $start);
$chk   = 4.0 * int(0.25 * $atemp[0]);
if($chk == $atemp[0]){
	$base = 366;
}else{
	$base = 365;
}

$xmin = ($start - $atemp[0])  * $base;

@btemp = split(/\./, $stop);
$chk   = 4.0 * int(0.25 * $btemp[0]);
if($chk == $btemp[0]){
	$base2 = 366;
}else{
	$base2 = 365;
}

#
#--- if year changes, pretend the date continues from the prev. year
#

$xmax = ($stop - $btemp[0]) * $base2;
if($btemp[0] > $atemp[0]){
	$xmax += $base;
}

$xmin = sprintf "%4.2f", $xmin;
$xmax = sprintf "%4.2f", $xmax;


$run_second_ind = 0;
plot_data ();

#
#--- if the interruption is longer than 5 days plotting period, 
#--- create the second plot
#

if($run_second > 0){
	$start = $start2;
	$stop  = $stop2;

#
#--- date for the plotting is ydate. 
#

	@atemp = split(/\./, $start);
	$chk   = 4.0 * int(0.25 * $atemp[0]);
	if($chk == $atemp[0]){
		$base = 366;
	}else{
		$base = 365;
	}
	
	$xmin = ($start - $atemp[0])  * $base;
	
	@btemp = split(/\./, $stop);
	$chk   = 4.0 * int(0.25 * $btemp[0]);
	if($chk == $btemp[0]){
		$base2 = 366;
	}else{
		$base2 = 365;
	}

#
#--- if year changes, pretend the date continues from the prev. year
#

	$xmax = ($stop - $btemp[0]) * $base2;
	if($btemp[0] > $atemp[0]){
		$xmax += $base;
	}
	
	$xmin = sprintf "%4.2f", $xmin;
	$xmax = sprintf "%4.2f", $xmax;

	$run_second_ind = 1;

	plot_data();
}
	
#
#--- compute average and sigma of the radiation doses
#

$hrcavg = $sum4/$stot4;
$hrcsig = sqrt($sum4_2/$stot4 - $p4avg * $p4avg);

$e150avg = $sum41/$stot41;
$e150sig = sqrt($sum41_2/$stot41 - $p41avg * $p41avg);

$e1300avg = $sume1300/$stote1300;
$e1300sig = sqrt($sume1300_2/$stote1300 - $e1300avg * $e1300avg);

#
#--- print out stat info
#

$hrcmin  = sprintf "%2.3e", $hrcmin;
$hrctmin = sprintf "%4.3f", $hrctmin;
$hrcmax  = sprintf "%2.3e", $hrcmax;
$hrctmax = sprintf "%4.3f", $hrctmax;
$hrcavg  = sprintf "%2.3e", $hrcavg;
$hrcsig  = sprintf "%2.3e", $hrcsig;
$hrcint  = sprintf "%2.3e", $hrcint;

$e150min  = sprintf "%2.3e", $e150min;
$e150tmin = sprintf "%4.3f", $e150tmin;
$e150max  = sprintf "%2.3e", $e150max;
$e150tmax = sprintf "%4.3f", $e150tmax;
$e150avg  = sprintf "%2.3e", $e150avg;
$e150sig  = sprintf "%2.3e", $e150sig;
$e150int  = sprintf "%2.3e", $e150int;

$e1300min  = sprintf "%2.3e", $e1300min;
$e1300tmin = sprintf "%4.3f", $e1300tmin;
$e1300max  = sprintf "%2.3e", $e1300max;
$e1300tmax = sprintf "%4.3f", $e1300tmax;
$e1300avg  = sprintf "%2.3e", $e1300avg;
$e1300sig  = sprintf "%2.3e", $e1300sig;
$e1300int  = sprintf "%2.3e", $e1300int;

$out = "$web_dir/Ephin_plot/"."$name".'_txt';

open(OUT, ">$out");
print OUT "\t\tAvg\t\t\t Max\t\tTime\t\tMin\t\tTime\tValue at Interruption Started\n";
print OUT "--------------------------------------------------------------------------------------------------------------------------\n";
print OUT "hrc\t\t$hrcavg+/-$hrcsig\t";
print OUT "$hrcmax\t$hrctmax\t\t";
print OUT "$hrcmin\t$hrctmin\t\t";
print OUT "$hrcint\n";

print OUT "e150\t\t$e150avg+/-$e150sig\t";
print OUT "$e150max\t$e150tmax\t\t";
print OUT "$e150min\t$e150tmin\t\t";
print OUT "$e150int\n";

print OUT "e1300\t\t$e1300avg+/-$e1300sig\t";
print OUT "$e1300max\t$e1300tmax\t\t";
print OUT "$e1300min\t$e1300tmin\t\t";
print OUT "$e1300int\n";
close(OUT);




#########################################################################################
#########################################################################################
#########################################################################################

sub plot_data{

#
#--- ploting starts here
#

	pgbegin(0, '"./pgplot.ps"/cps',1,1);
	pgsubp(1,3);
	pgsch(2);
	pgslw(4);

#
#----- HRC shield
#

	$ylab = 'Log(HRC Shield Rate)';
	
	$hymin = $ymin + 2;
	$hymax = $ymax + 2;
#	pgenv($xmin, $xmax, $hymin, $hymax, 0 , 0);

#
#---- new setting 02/09/2012
#
	$hymin = 3.4;
	$hymax = 4.6;

	pgenv($xmin, $xmax, $hymin, $hymax, 0 , 0);
	pglab('Day of Year', $ylab, $title);
	
	pgsci(2);

#
#-- plot the interruption starting point
#

	@atemp = split(/\./, $rstart);
	$chk   = 4.0 * int(0.25 * $atemp[0]);
	if($chk == $atemp[0]){
		$base = 366;
	}else{
		$base = 365;
	}
	$rbeg = ($rstart - $atemp[0]) * $base;
	if($run_second_ind == 0){
		pgmove($rbeg, $hymin);
		pgdraw($rbeg, $hymax);
	
		$ym = $hymax - 0.1 * ($hymax - $hymin);
		pgptxt($rbeg, $ym, 0, left, interruption);
	}

#
#--- plot the end of the interruption
#

	@atemp = split(/\./, $rstop);
	$chk   = 4.0 * int(0.25 * $atemp[0]);
	if($chk == $atemp[0]){
		$base = 366;
	}else{
		$base = 365;
	}
	$rend = ($rstop - $atemp[0]) * $base;

	if($run_second == 0 || $run_second_ind > 0){
		pgmove($rend, $hymin);
		pgdraw($rend, $hymax);
	}

#	pgmove($xmin, 2.477);
#	pgdraw($xmax, 2.477);
	pgsci(1);

#
#--- plot data points
#
	pgsch(4);
	OUTER:
	for($m = 0; $m < $tot -1; $m++){
		
		if($hrc[$m] <= 0){
			next OUTER;
		}
		if($xdate[$m] < $xmin){
			next OUTER;
		}
		if($xdate[$m] > $xmax){
			last OUTER;
		}

		$ydata = log($hrc[$m])/2.302585093;
        	pgpt(1, $xdate[$m], $ydata, 1);
	
		if($xdate[$m] < $rbeg || $xdata[$m] > $rend){
			next OUTER;
		}
	
		if($hrcmin > $hrc[$m]){
			$hrcmin  = $hrc[$m];
			$hrctmin = $xdate[$m];
		}
		if($hrcmax < $hrc[$m]){
			$hrcmax  = $hrc[$m];
			$hrctmax = $xdate[$m];
		}
		if($hrcint == -999 && $xdate[$m] >= $rbeg){
			$hrcint = $hrc[$m];
		}
		$sum4   += $hrc[$m];
		$sum4_2 += $hrc[$m] * $hrc[$m];
		$stot4++;

	}
	pgsch(2);


#
#--- plot radation balt location
#

	$ytemp = $ymin;
	$ymin  = $hymin;

	$ytemp2= $ymax;
	$ymax  = $hymax;

	plot_box();

	$ymin = $ytemp;
	$ymax = $ytemp2;

#
#----- e150
#

	$ylab = 'Log(e150 Rate)';
	
	pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
	pglab('Day of Year', $ylab, $title);
	
	pgsci(2);
	if($run_second_ind == 0){
		pgmove($rbeg, $ymin);
		pgdraw($rbeg, $ymax);
	
		$ym = $ymax - 0.1 * ($ymax - $ymin);
		pgptxt($rbeg, $ym, 0, left, interruption);
	}
	
	if($run_second == 0 || $run_second_ind > 0){
		pgmove($rend, $ymin);
		pgdraw($rend, $ymax);
	}
	
#	pgmove($xmin, 1.0);
#	pgdraw($xmax, 1.0);
	pgmove($xmin, 2.0);
	pgdraw($xmax, 2.0);
	pgsci(1);

	pgsch(4);
	OUTER:
	for($m = 0; $m < $tot -1; $m++){
	
		if($e150[$m] <= 0){
			next OUTER;
		}
		if($xdate[$m] < $xmin){
			next OUTER;
		}
		if($xdate[$m] > $xmax){
			last OUTER;
		}

		$ydata = log($e150[$m])/2.302585093;
        	pgpt(1, $xdate[$m], $ydata, 1);
	
		if($xdate[$m] < $rbeg || $xdata[$m] > $rend){
			next OUTER;
		}
	
		if($e150min > $e150[$m]){
			$e150min  = $e150[$m];
			$e150tmin = $xdate[$m];
		}
		if($e150max < $e150[$m]){
			$e150max  = $e150[$m];
			$e150tmax = $xdate[$m];
		}
		if($e150int == -999 && $xdate[$m] >= $rbeg){
			$e150int = $e150[$m];
		}
		$sum41   += $e150[$m];
		$sum41_2 += $e150[$m] * $e150[$m];
		$stot41++;
	}
	pgsch(2);
	
	plot_box();

#
#----- e1300
#

	$ylab = 'Log(e1300 Rate)';
	
	pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
	pglab('Day of Year', $ylab, $title);
	
	pgsci(2);
	if($run_second_ind == 0){
		pgmove($rbeg, $ymin);
		pgdraw($rbeg, $ymax);

		$ym = $ymax - 0.1 * ($ymax - $ymin);
		pgptxt($rbeg, $ym, 0, left, interruption);
	}

	if($run_second == 0 || $run_second_ind > 0){
		pgmove($rend, $ymin);
		pgdraw($rend, $ymax);
	}
	pgmove($xmin, 1.301);
	pgdraw($xmax, 1.301);
	pgsci(1);
	
	pgsch(4);
	OUTER:
	for($m = 0; $m < $tot -1; $m++){
	
		if($e1300[$m] <= 0){
			next OUTER;
		}
		if($xdate[$m] < $xmin){
			next OUTER;
		}
		if($xdate[$m] > $xmax){
			last OUTER;
		}

		$ydata = log($e1300[$m])/2.302585093;
        	pgpt(1, $xdate[$m], $ydata, 1);
	
		if($xdate[$m] < $rbeg || $xdata[$m] > $rend){
			next OUTER;
		}
	
		if($e1300min > $e1300[$m]){
			$e1300min  = $e1300[$m];
			$e1300tmin = $xdate[$m];
		}
		if($e1300max < $ydata){
			$e1300max  = $e1300[$m];
			$e1300tmax = $xdate[$m];
		}
		if($e1300int == -999 && $xdate[$m] >= $rbeg){
			$e1300int = $e1300[$m];
		}
		$sume1300   += $e1300[$m];
		$sume1300_2 += $e1300[$m] * $e1300[$m];
		$stote1300++;
	}
	pgsch(2);
	
	plot_box();
	
	pgclos();

	if($run_second_ind == 0){
		$out_gif = "$web_dir/Ephin_plot/"."$name".'_eph.gif';
		$out_ps  = "$web_dir/Ps_dir/"."$name".'_eph.ps';
#$out_gif = "./$name".'_eph.gif';
#$out_ps  = "./$name".'_eph.ps';
	}else{
		$out_gif = "$web_dir/Ephin_plot/"."$name".'_eph_pt2.gif';
		$out_ps  = "$web_dir/Ps_dir/"."$name".'_eph_pt2.ps';
#$out_gif = "./$name".'_eph_pt2.gif';
#$out_ps  = "./$name".'_eph_pt2.ps';
	}
	
#	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmcrop| pnmflip -r270 | ppmtogif > $out_gif");
	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|  pnmflip -r270 | ppmtogif > $out_gif");

	system("mv pgplot.ps $out_ps");
	
}


###################################################################
###################################################################
###################################################################

sub date_to_fyear{
	my($year, $mon, $day, $hour, $min);
	($year, $mon, $day, $hour, $min) = @_;

	if($year < 1000){
		if($year > 70){
			$year = '19'."$year";
		}else{
			$year = '20'."$year";
		}
	}

	$chk = 4.0 * int(0.25 * $year);
	if($chk == $year){
		$base = 366;
	}else{
		$base = 365;
	}

	$fday = int($day) +  $hour/24 + $min/1440;
	$add = 0;
	if($mon == 2){
		$add = 31;
	}elsif($mon == 3){
		$add = 59;
	}elsif($mon == 4){
		$add = 90;
	}elsif($mon == 5){
		$add = 120;
	}elsif($mon == 6){
		$add = 151;
	}elsif($mon == 7){
		$add = 181;
	}elsif($mon == 8){
		$add = 212;
	}elsif($mon == 9){
		$add = 243;
	}elsif($mon == 10){
		$add = 273;
	}elsif($mon == 11){
		$add = 304;
	}elsif($mon == 12){
		$add = 334;
	}
	if($base == 366 && $mon > 2){
		$add++;
	}
	$year += ($fday + $add)/$base;
	
	return($year);
}


###############################################################
### read_rad_zone: read radiation zone information          ###
###############################################################

sub read_rad_zone{
	my(@atemp);

        if($byear == 1999){
               	$subt = - 202;
        }else{
               	$subt = 365 *($byear - 2000) + 163;
               	if($byear > 2000){
                       	$subt++;
               	}
                if($byear > 2004){
                        $subt++;
                }
                if($byear > 2008){
                        $subt++;
                }
                if($byear > 2012){
                        $subt++;
                }
                if($byear > 2016){
                        $subt++;
                }
                if($byear > 2020){
                        $subt++;
                }
                if($byear > 2024){
                        $subt++;
                }
                if($byear > 2028){
                        $subt++;
                }
        }
	
	if($byear < 2003){
        	open(FH, "$house_keeping/rad_zone_list");
        	OUTER:
        	while(<FH>){
                	chomp $_;
                	@atemp = split(/\s+/, $_);
                	if($atemp[0] eq $name){
                        	$line = $_;
                        	last OUTER;
                	}
        	}
	
        	@atemp = split(/\s+/, $line);
        	@rad_entry = split(/:/, $atemp[1]);
        	$ent_cnt = 0;
        	foreach (@rad_entry){
                	$ent_cnt++;
        	}
	}else{
		extract_rad_zone_info();
		$ent_cnt = $pcnt;
	}
}

###############################################################
### plot_box: create radiation zone box on the plot         ###
###############################################################

sub plot_box{
	my($j, $ydiff);
        pgsci(12);
	OUTER:
        for($j = 0; $j < $ent_cnt; $j++){
                @dtmp = split(/\(/, $rad_entry[$j]);
                @etmp = split(/\)/, $dtmp[1]);
                @ftmp = split(/\,/, $etmp[0]);
                $r_start = $ftmp[0] - $subt;
                $r_end   = $ftmp[1] - $subt;
		if($r_end < $r_start){
			next OUTER;
		}

                if($r_start < $xmin){
                        $r_start = $xmin;
                }
                if($r_end > $xmax){
                        $r_end = $xmax;
                }
                pgshs (0.0, 1.0, 0.0);
                $ydiff = $ymax - $ymin;
                $yt = 0.05*$ydiff;
                $ytop = $ymin + $yt;
                pgsfs(4);
                pgrect($r_start,$r_end,$ymin,$ytop);
                pgsfs(1);
        }
        pgsci(1);
}

##############################################################
### to_dofy: change date to day of the year                ###
##############################################################

sub to_dofy{
#	my($uyear, $umonth, $uday);

#	($uyear, $umonth, $uday) = @_;

        if($umonth == 1){
                $add = 0;
        }elsif($umonth == 2){
                $add = 31;
        }elsif($umonth == 3){
                $add = 59;
        }elsif($umonth == 4){
                $add = 90;
        }elsif($umonth == 5){
                $add = 120;
        }elsif($umonth == 6){
                $add = 151;
        }elsif($umonth == 7){
                $add = 181;
        }elsif($umonth == 8){
                $add = 212;
        }elsif($umonth == 9){
                $add = 243;
        }elsif($umonth == 10){
                $add = 273;
        }elsif($umonth == 11){
                $add = 304;
        }elsif($umonth == 12){
                $add = 334;
        }

	$chk = 4.0 * int(0.25 * $uyear);
	if($chk == $uyear){

                if($umonth > 2){
                        $add += 1;
                }
        }

        $dofy = $uday + $add;
}


##############################################################
#### to_dofy2: day of the year fraction version            ###
##############################################################

sub to_dofy2{

        @rtemp = split(/:/,$in_time);
        $uyear = $rtemp[0];
        $uyday = $rtemp[1];

        $hour  = $rtemp[2];
        $min   = $rtemp[3];

        $frac  = $hour/24 + $min/1440;

        $dofy = $uyday + $frac;
}

###################################################################################
### read_rad_zone: read rad zone and create the list for the specified period   ###
###################################################################################

sub extract_rad_zone_info{
	my ($start, $stop, @pstart, @pstop, @dom);
	open(FH,"$house_keeping/rad_zone_info");

	@ind    = ();
	@rtime  = ();
	@rtime2 = ();
	$rtot   = 0;
	
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		push(@ind,    $atemp[0]);
		push(@rtime,  $atemp[1]);
		push(@rtime2, $atemp[2]);
		$rtot++;
	}
	close(FH);
	
	@atemp = split(/:/, $begin);
	$dom   = conv_date_dom($atemp[0],$atemp[1],$atemp[2]);
	$start = $dom - 8;
	
	@atemp = split(/:/, $end);
	$dom   = conv_date_dom($atemp[0],$atemp[1],$atemp[2]);
	$stop  = $dom + 8;
	
	@pstart = ();
	@pstop  = ();
	$pcnt   = 0;
	OUTER:
	for($i = 0; $i < $rtot; $i++){
		if($rtime[$i] < $start){
			next OUTER;
		}elsif($rtime[$i] >= $start && $rtime[$i] < $stop){
			if($ind[$i] =~ /ENTRY/i){
				push(@pstart, $rtime[$i]);	
			}elsif($ind[$i] =~ /EXIT/i){
				if(($pstart[$pcnt] != 0) && ($pstart[$pcnt] < $rtime[$i])){
					push(@pstop, $rtime[$i]);
					$pcnt++;
				}
			}
		}elsif($rtime[$i] > $stop){
			last OUTER;
		}
	}
	
	
	@rad_entry = ();
	for($i = 0; $i < $pcnt; $i++){
		$line = "($pstart[$i],$pstop[$i])";
		push(@rad_entry, $line);
	}
}	



###########################################################################
###      conv_date_dom: modify data/time format                       #####
###########################################################################

sub conv_date_dom {

#############################################################
#       Input:  $year: year in a format of 2004
#               $month: month in a formt of  5 or 05
#               $day:   day in a formant fo 5 05
#
#       Output: acc_date: day of mission returned
#############################################################

        my($year, $month, $day, $chk, $acc_date);

        ($year, $month, $day) = @_;

        $acc_date = ($year - 1999) * 365;

        if($year > 2000 ) {
                $acc_date++;
        }elsif($year >  2004 ) {
                $acc_date += 2;
        }elsif($year > 2008) {
                $acc_date += 3;
        }elsif($year > 2012) {
                $acc_date += 4;
        }elsif($year > 2016) {
                $acc_date += 5;
        }elsif($year > 2020) {
                $acc_date += 6;
        }elsif($year > 2024) {
                $acc_date += 7;
        }

        $acc_date += $day - 1;
        if ($month == 2) {
                $acc_date += 31;
        }elsif ($month == 3) {
                $chk = 4.0 * int(0.25 * $year);
                if($year == $chk) {
                        $acc_date += 59;
                }else{
                        $acc_date += 58;
                }
        }elsif ($month == 4) {
                $acc_date += 90;
        }elsif ($month == 5) {
                $acc_date += 120;
        }elsif ($month == 6) {
                $acc_date += 151;
        }elsif ($month == 7) {
                $acc_date += 181;
        }elsif ($month == 8) {
                $acc_date += 212;
        }elsif ($month == 9) {
                $acc_date += 243;
        }elsif ($month == 10) {
                $acc_date += 273;
        }elsif ($month == 11) {
                $acc_date += 304;
        }elsif ($month == 12) {
                $acc_date += 334;
        }
        $acc_date -= 202;
        return $acc_date;
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
                $ydate = $tday + 334;
        }
        $chk = 4 * int (0.25 * $tyear);
        if($chk == $tyear && $tmonth > 2){
                $ydate++;
        }

	return $ydate;
}

###############################################################################
###sec1998_to_fracyear: change sec from 1998 to time in year               ####
###############################################################################

sub sec1998_to_fracyear{

        my($t_temp, $normal_year, $leap_year, $year, $j, $k, $chk, $jl, $base, $yfrac, $year_date);

        ($t_temp) = @_;

        $t_temp +=  86400;

        $normal_year = 31536000;
        $leap_year   = 31622400;
        $year        = 1998;

        $j = 0;
        OUTER:
        while($t_temp > 1){
                $jl = $j + 2;
                $chk = 4.0 * int(0.25 * $jl);
                if($chk == $jl){
                        $base = $leap_year;
                }else{
                        $base = $normal_year;
                }

                if($t_temp > $base){
                        $year++;
                        $t_temp -= $base;
                        $j++;
                }else{
                        $yfrac = $t_temp/$base;
                        $year_date = $year + $yfrac;
                        last OUTER;
                }
        }

        return $year_date;
}


