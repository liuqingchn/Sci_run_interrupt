#!/usr/bin/perl 
use PGPLOT;

#################################################################################
#										#
#	extract_goes.perl: extract GOES-11 data and plot the results		#
#										#
#		author: t. isobe (tisobe@cfa.harvard.edu)			#
#										#
#		last update: Mar 22, 2010					#
#										#
#	P1    .8 -   4.0 MeV protons (Counts/cm2 sec sr MeV) Uncorrected	#
#	P2   4.0 -   9.0 MeV protons (Counts/cm2 sec sr MeV) Uncorrected	#
#	P5  40.0 -  80.0 MeV protons (Counts/cm2 sec sr MeV) Uncorrected	#
#										#
#################################################################################


#################################################################
#
#--- setting directories
#

open(FH, './dir_list');
@list = ();
while(<FH>){
        chomp $_;
        push(@list, $_);
}
close(FH);

$bin_dir       = $list[0];
$data_dir      = $list[1];
$web_dir       = $list[2];
$house_keeping = $list[3];

################################################################

#
#--- data input example: 
#
#	name       start             stop
#	20061213   2006:12:13:22:44  2006:12:16:13:42
#

$name  = $ARGV[0];
$begin = $ARGV[1];		#--- sci run interruption started
$end   = $ARGV[2];		#--- sci run interruption finished

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
		$pday  = 31 - $pay;
	}else{
		if($pmon == 2){
			$chk   = 4.0 *int(0.25 * $pyear);
			if($chk == $pyear){
				$pday =  29 - $pday;
			}else{
				$pday =  28 - $pday;
			}
		}elsif($pmon ==1 || $pmon == 3 || $pmon == 5 || $pmon == 7
			|| $pmon == 8  || $pmon == 10){
				$pday = 31 - $pday;
		}else{
				$pday = 30 - $pday;
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


#
#--- create a html address which includes the data
#

@ctemp = split(//, $pyear);
$file = 'G105'."$ctemp[2]$ctemp[3]"."$pmon".'.TXT';
$html = 'http://goes.ngdc.noaa.gov/data/avg/'."$pyear".'/'."$file";

#
#---lynx convert html page into ascii data file
#

system("/opt/local/bin/lynx -source $html >./Working_dir/temp_data");
open(FH, "./Working_dir/temp_data");

#
#--- read the data and save needed data points
#

@day  = ();
@time = ();
@p1   = ();
@p2   = ();
@p5   = ();
$tot  = 0;
$chk  = 0;

OUTER:
while(<FH>){
	chomp $_;
	if($chk == 0 && $_ =~ /------------------------/){
		$chk = 1;
		next OUTER;
	}elsif($chk == 0){
		next OUTER;
	}
	@atemp = split(/\s+/, $_);
	@btemp = split(//, $atemp[0]);
	$year  = "$btemp[0]$btemp[1]";
	$mon   = "$btemp[2]$btemp[3]";
	$day   = "$btemp[4]$btemp[5]";
	@btemp = split(//, $atemp[1]);
	$hour  = "$btemp[0]$btemp[1]";
	$min   = "$btemp[2]$btemp[2]";
	
	$time = date_to_fyear($year, $mon, $day, $hour, $min);
	if($time >= $start && $time <= $stop){
		push(@date, $time);
		push(@p1,   $atemp[10]);
		push(@p2,   $atemp[11]);
		push(@p5,   $atemp[14]);
		$tot++;
	}
}
close(FH);

#
#--- check whether we need to open another file or not
#

$chk = 0;
if($pyear == $peyear){			#---- next month of the same year
	if($pmon < $pemon){
		$chk = 1;
	}
}elsif($peyar < $peyear){		#---- jan of the next year
	$chk = 1;
}

if($chk == 1){
#
#--- yes we need to read another data set from the next month
#
	@ctemp = split(//, $peyear);
	$file = 'G105'."$ctemp[2]$ctemp[3]"."$pemon".'.TXT';
	$html = 'http://goes.ngdc.noaa.gov/data/avg/'."$peyear".'/'."$file";

	system("/opt/local/bin/lynx -source $html >./Working_dir/temp_data");
	open(FH, "./Working_dir/temp_data");
	
	OUTER:
	while(<FH>){
		chomp $_;
		if($chk == 0 && $_ =~ /------------------------/){
			$chk = 1;
			next OUTER;
		}elsif($chk == 0){
			next OUTER;
		}
		@atemp = split(/\s+/, $_);
		@btemp = split(//, $atemp[0]);
		$year  = "$btemp[0]$btemp[1]";
		$mon   = "$btemp[2]$btemp[3]";
		$day   = "$btemp[4]$btemp[5]";
		@btemp = split(//, $atemp[1]);
		$hour  = "$btemp[0]$btemp[1]";
		$min   = "$btemp[2]$btemp[2]";
		
		$time = date_to_fyear($year, $mon, $day, $hour, $min);
		if($time >= $start && $time <= $stop){
			push(@date, $time);
			push(@p1,   $atemp[10]);
			push(@p2,   $atemp[11]);
			push(@p5,   $atemp[14]);
			$tot++;
		}
	}
	close(FH);
}


system("rm ./Working_dir/temp_data");

#
#--- ploting starts here
#

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,3);
pgsch(2);
pgslw(4);

#
#--- data for the plotting is ydate. 
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

#
#-- convert all date into ydate
#

@xdate = ();
for($m = 0; $m < $tot; $m++){
	@atemp = split(/\./, $date[$m]);
	$chk   = 4.0 * int(0.25 * $atemp[0]);
	if($chk == $atemp[0]){
		$base = 366;
	}else{
		$base = 365;
	}
	$xp = ($date[$m] - $atemp[0]) * $base;
	push(@xdate, $xp);
}

#
#--- printing out the data
#

$out = "/data/mta_www/mta_interrupt/Data_dir/$name".'_goes.txt';
open(OUT, ">$out");
print OUT "Scient Run Interruption: $begin\n\n";
print OUT "dofy\t\tp1\t\tp2\t\tp5\n";
print OUT "-------------------------------------------------------------------\n";

for($m = 0; $m < $tot; $m++){
	$sdate = sprintf "%4.3f", $xdate[$m];
	print OUT "$sdate\t\t$p1[$m]\t$p2[$m]\t$p5[$m]\n";
}


#
#----- p1
#

$ylab = 'Log(p1 Rate)';
$ymin = -3;
@temp = sort{$a<=>$b} @p1;
$ymax = $temp[$cnt-1];
$ymax = int(log($ymax)/2.302585093) + 1;

pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
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
pgmove($rbeg, $ymin);
pgdraw($rbeg, $ymax);

$ym = $ymax - 0.1 * ($ymax - $ymin);

pgptxt($rbeg, $ym, 0, left, interruption);

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
pgmove($rend, $ymin);
pgdraw($rend, $ymax);
#pgmove($xmin, 2.477);
#pgdraw($xmax, 2.477);
pgsci(1);

#
#--- plot data points
#

$p1min  = 1e14;
$p1tmin = 0;
$p1max  = 1e-14;
$p1tmax = 0;
$p1int  = -999;
$sum    = 0;
$sum2   = 0;
$stot   = 0;
pgsch(4);
OUTER:
for($m = 0; $m < $tot -1; $m++){
	
	if($p1[$m] <= 0){
		next OUTER;
	}
	$ydata = log($p1[$m])/2.302585093;
        pgpt(1, $xdate[$m], $ydata, 1);

	if($xdate[$m] < $rbeg || $xdata[$m] > $rend){
		next OUTER;
	}

	if($p1min > $p1[$m]){
		$p1min  = $p1[$m];
		$p1tmin = $xdate[$m];
	}
	if($p1max < $p1[$m]){
		$p1max  = $p1[$m];
		$p1tmax = $xdate[$m];
	}
	if($p1int == -999 && $xdate[$m] >= $rbeg){
		$p1int = $p1[$m];
	}
	$sum  += $p1[$m];
	$sum2 += $p1[$m] * $p1[$m];
	$stot++;

}
pgsch(2);

$p1avg = $sum/$stot;
$p1sig = sqrt($sum2/$stot - $p1avg * $p1avg);


#
#--- plot radation balt location
#

plot_box();

#
#----- p2
#

$ylab = 'Log(p2 Rate)';
$ymin = -3;
@temp = sort{$a<=>$b} @p2;
$ymax = $temp[$cnt-1];
$ymax = int(log($ymax)/2.302585093) + 1;

pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
pglab('Day of Year', $ylab, $title);

pgsci(2);
pgmove($rbeg, $ymin);
pgdraw($rbeg, $ymax);

$ym = $ymax - 0.1 * ($ymax - $ymin);

pgptxt($rbeg, $ym, 0, left, interruption);

pgmove($rend, $ymin);
pgdraw($rend, $ymax);
#pgmove($xmin, 2.477);
#pgdraw($xmax, 2.477);
pgsci(1);

$p2min  = 1e14;
$p2tmin = 0;
$p2max  = 1e-14;
$p2tmax = 0;
$p2int  = -999;
$sum    = 0;
$sum2   = 0;
$stot   = 0;
pgsch(4);
OUTER:
for($m = 0; $m < $tot -1; $m++){

	if($p2[$m] <= 0){
		next OUTER;
	}
	$ydata = log($p2[$m])/2.302585093;
        pgpt(1, $xdate[$m], $ydata, 1);

	if($xdate[$m] < $rbeg || $xdata[$m] > $rend){
		next OUTER;
	}

	if($p2min > $p2[$m]){
		$p2min  = $p2[$m];
		$p2tmin = $xdate[$m];
	}
	if($p2max < $p2[$m]){
		$p2max  = $p2[$m];
		$p2tmax = $xdate[$m];
	}
	if($p2int == -999 && $xdate[$m] >= $rbeg){
		$p2int = $p2[$m];
	}
	$sum  += $p2[$m];
	$sum2 += $p2[$m] * $p2[$m];
	$stot++;
}
pgsch(2);

$p2avg = $sum/$stot;
$p2sig = sqrt($sum2/$stot - $p2avg * $p2avg);

plot_box();

#
#----- p5
#

$ylab = 'Log(p5 Rate)';
$ymin = -3;
@temp = sort{$a<=>$b} @p5;
$ymax = $temp[$cnt-1];
$ymax = int(log($ymax)/2.302585093) + 1;

pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
pglab('Day of Year', $ylab, $title);

pgsci(2);
pgmove($rbeg, $ymin);
pgdraw($rbeg, $ymax);

$ym = $ymax - 0.1 * ($ymax - $ymin);

pgptxt($rbeg, $ym, 0, left, interruption);

pgmove($rend, $ymin);
pgdraw($rend, $ymax);
#pgmove($xmin, 2.477);
#pgdraw($xmax, 2.477);
pgsci(1);

$p5min  = 1e14;
$p5tmin = 0;
$p5max  = 1e-14;
$p5tmax = 0;
$p5int  = -999;
$sum    = 0;
$sum2   = 0;
$stot   = 0;
pgsch(4);
OUTER:
for($m = 0; $m < $tot -1; $m++){

	if($p5[$m] <= 0){
		next OUTER;
	}
	$ydata = log($p5[$m])/2.302585093;
        pgpt(1, $xdate[$m], $ydata, 1);

	if($xdate[$m] < $rbeg || $xdata[$m] > $rend){
		next OUTER;
	}

	if($p5min > $p5[$m]){
		$p5min  = $p5[$m];
		$p5tmin = $xdate[$m];
	}
	if($p5max < $ydata){
		$p5max  = $p5[$m];
		$p5tmax = $xdate[$m];
	}
	if($p5int == -999 && $xdate[$m] >= $rbeg){
		$p5int = $p5[$m];
	}
	$sum  += $p5[$m];
	$sum2 += $p5[$m] * $p5[$m];
	$stot++;
}
pgsch(2);

$p5avg = $sum/$stot;
$p5sig = sqrt($sum2/$stot - $p5avg * $p5avg);

plot_box();

pgclos();

$out_gif = "$web_dir/GOES_plot/"."$name".'_goes.gif';
$out_ps  = "$web_dir/Ps_dir/"."$name".'_goes.ps';

#system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmcrop| pnmflip -r270 | ppmtogif > $out_gif");
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|  pnmflip -r270 | ppmtogif > $out_gif");

system("mv pgplot.ps $out_ps");



$p1min  = sprintf "%2.3e", $p1min;
$p1tmin = sprintf "%4.3f", $p1tmin;
$p1max  = sprintf "%2.3e", $p1max;
$p1tmax = sprintf "%4.3f", $p1tmax;
$p1avg  = sprintf "%2.3e", $p1avg;
$p1sig  = sprintf "%2.3e", $p1sig;
$p1int  = sprintf "%2.3e", $p1int;

$p2min  = sprintf "%2.3e", $p2min;
$p2tmin = sprintf "%4.3f", $p2tmin;
$p2max  = sprintf "%2.3e", $p2max;
$p2tmax = sprintf "%4.3f", $p2tmax;
$p2avg  = sprintf "%2.3e", $p2avg;
$p2sig  = sprintf "%2.3e", $p2sig;
$p2int  = sprintf "%2.3e", $p2int;

$p5min  = sprintf "%2.3e", $p5min;
$p5tmin = sprintf "%4.3f", $p5tmin;
$p5max  = sprintf "%2.3e", $p5max;
$p5tmax = sprintf "%4.3f", $p5tmax;
$p5avg  = sprintf "%2.3e", $p5avg;
$p5sig  = sprintf "%2.3e", $p5sig;
$p5int  = sprintf "%2.3e", $p5int;


$out = "$web_dir/GOES_plot/"."$name".'_text';
open(OUT, ">$out");
print OUT "\t\tAvg\t\t\t Max\t\tTime\t\tMin\t\tTime\tValue at Interruption Started\n";
print OUT "--------------------------------------------------------------------------------------------------------------------------\n";
print OUT "p1\t\t$p1avg+/-$p1sig\t";
print OUT "$p1max\t$p1tmax\t\t";
print OUT "$p1min\t$p1tmin\t\t";
print OUT "$p1int\n";

print OUT "p2\t\t$p2avg+/-$p2sig\t";
print OUT "$p2max\t$p2tmax\t\t";
print OUT "$p2min\t$p2tmin\t\t";
print OUT "$p2int\n";

print OUT "p5\t\t$p5avg+/-$p5sig\t";
print OUT "$p5max\t$p5tmax\t\t";
print OUT "$p5min\t$p5tmin\t\t";
print OUT "$p5int\n";
close(OUT);









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
        }

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
}

###############################################################
### plot_box: create radiation zone box on the plot         ###
###############################################################

sub plot_box{
	my($j, $ydiff);
        pgsci(12);
        for($j = 0; $j < $ent_cnt; $j++){
                @dtmp = split(/\(/, $rad_entry[$j]);
                @etmp = split(/\)/, $dtmp[1]);
                @ftmp = split(/\,/, $etmp[0]);
                $r_start = $ftmp[0] - $subt;
                $r_end   = $ftmp[1] - $subt;
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

