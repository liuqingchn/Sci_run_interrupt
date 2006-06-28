#!/usr/bin/perl

#################################################################################################
#												#
#	sci_run_print_html.perl: print indivisual html page					#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: Jun 28, 2006							#
#												#
#################################################################################################

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
#--- if the next input is given as arguments, use it, otherwise, ask
#--- a user to type it in.
#

$date_list      = $ARGV[0]; 

if($date_list eq ''){
	print "Time List: ";            # a list of science run interruption
	$date_list = <STDIN>;
	chomp $date_list;
}

open(FH, "$date_list");

@hardness = ();

open(OUT1, '>./auto_list');
open(OUT2, '>./manual_list');

while(<FH>){
        chomp $_;
        $line = $_;
        @atemp = split(/\s+/, $_);
        if($atemp[4] eq 'auto'){
                print OUT1 "$_\n";
        }else{
                print OUT2 "$_\n";
        }

        $name = $atemp[0];
        $stat_data = "$web_dir".'/Stat_dir/'."$name".'_stat';
        open(IN, "$stat_data");

        while(<IN>){
                chomp $_;
                @ctemp = split(/\s+/, $_);
                if($ctemp[0] eq 'p47/p1060'){
                        push(@hardness, $ctemp[2]);
                        %{data.$ctemp[2]} = (data =>["$line"]);
                }
        }
        close(IN);
}
close(FH);
close(OUT1);
close(OUT2);

open(FH, "$house_keeping/rad_zone_list");
@rad_zone_list = ();

while(<FH>){
	chomp $_;
	push(@rad_zone_list, $_);
}
close(FH);

@ordered  = sort{$a<=>$b} @hardness;
@reversed = reverse @ordered;

open(OUT3, '>./hardness_ordered');

foreach $ent (@reversed){
        print OUT3 "${data.$ent}{data}[0]\n";
}
close(OUT3);

#
#--- today's date
#

($hsec, $hmin, $hhour, $hmday, $hmon, $hyear, $hwday, $hyday, $hisdst)= localtime(time);

if($hyear < 1900) {
        $hyear = 1900 + $hyear;
}

$hmonth    = $hmon + 1;

$print_chk = 'yes';

#
#--- create time ordered html pages
#

$which     = 'time_order';
$in_file   = $date_list;
$out_file  = "$web_dir".'/time_order.html';

print_sub_html();

$print_chk = 'no';

#
#--- create auto interrupt html pages
#

$which    = 'auto';
$in_file  = 'auto_list';
$out_file = "$web_dir".'/auto_shut.html';

print_sub_html();

#
#--- create manual interrupt html pages
#

$which    = 'manual';
$in_file  = 'manual_list';
$out_file = "$web_dir".'/manu_shut.html';

print_sub_html();

#
#--- create hardness ordered html pages
#

$which    = 'hardness';
$in_file  = 'hardness_ordered';
$out_file = "$web_dir".'/hard_order.html';

print_sub_html();

system("rm ./auto_list ./manual_list ./hardness_ordered");

#######################################################################################
### print_sub_html:  create sub html pages                                          ###
#######################################################################################

sub print_sub_html{
	open(FH, "$in_file");
	@name     = ();
	@start    = ();
	@end      = ();
	@interval = ();
	@method   = ();
	$total    = 0;

	while(<FH>){
        	chomp $_;
        	@atemp = split(/\s+/, $_);
        	push(@name,     $atemp[0]);
        	push(@start,    $atemp[1]);
        	push(@end,      $atemp[2]);
		push(@interval, $atemp[3]);
        	push(@method,   $atemp[4]);
        	$total++;

        	@btemp  = split(/:/, $atemp[1]);
        	$uyear  = $btemp[0];
        	$umonth = $btemp[1];
        	$uday   = $btemp[2];

        	to_dom();

        	$begin  = $dom + $btemp[3]/24 + $btemp[4]/1440;
	
        	@btemp  = split(/:/, $atemp[2]);
        	$uyear  = $btemp[0];
        	$umonth = $btemp[1];
        	$uday   = $btemp[2];

        	to_dom();

        	$end    = $dom + $btemp[3]/24 + $btemp[4]/1440;

		OUTER:
		foreach $ent (@rad_zone_list){
			if($ent =~ /$atemp[0]/){
				@atemp = split(/\s+/, $ent);
				@rad_entry = split(/:/, $atemp[1]);
				$ent_cnt = 0;
				foreach (@rad_entry){
					$ent_cnt++;
				}
			}
		}
		
		$rad_time = 0.0;
		foreach $ent (@rad_entry){
			@dtmp = split(/\(/, $ent);
			@etmp = split(/\)/, $dtmp[1]);
			@ftmp = split(/\,/, $etmp[0]);

			if($ftmp[0] >= $begin && $ftmp[1] <= $end){

				$rad_time += ($ftmp[1] - $ftmp[0]);

			}elsif($ftmp[0] < $begin && $ftmp[1] >= $begin && $ftmp[1] <= $end){

				$rad_time += ($ftmp[1] - $begin);

			}elsif($fmp[0] >= $begin && $fmp[0] <= $end &&  $ftmp[1] > $end){

				$rad_time += ($end - $ftmp[0]);

			}
		}

        	$diff = 86.400 * ($end - $begin - $rad_time);
	}
	close(FH);
	
	open(OUT, ">$out_file");
	
	print OUT '<HTML><BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="#00CCFF" ',"\n";
	print OUT 'VLINK="#B6FFFF" ALINK="#FF0000", background ="./stars.jpg">',"\n";
	
	print OUT '<title> ACE Data Plots for Periods Which Interrupted Science Runs </title>',"\n";
	
	print OUT '<CENTER><H1>ACE Data Plots for Periods  Which Interrupted Science Runs',"\n";
	print OUT '</H1></CENTER>',"\n";
	
	print OUT '<CENTER><H1>Last Updated ';
	print OUT "$hyear-$hmonth-$hmday  ";
	print OUT "\n";
	print OUT '</CENTER></H1>',"\n";
	
	print OUT '<h3>',"\n";
	print OUT 'ACE radiation data are plotted around periods when science runs ';
	print OUT 'were interrupted.',"\n";
	print OUT 'Plots start exactly 2 days before the interruption started.',"\n";
	print OUT 'The top panel shows differential fluxes of electrons 38-53 and 175-315',"\n";
	print OUT '(particles/cm2-s-ster-MeV), the middle panel shows differential fluxes of',"\n";
	print OUT 'protons 47-65, 112-187, and 310-580 (particles/cm2-s-ster-MeV), and the',"\n";
	print OUT 'bottom panel shows anisotropy ratio.',"\n";
	print OUT 'The original data are prepared by the U.S. Dept. of Commerce, NOAA, Space ',"\n";
	print OUT 'Environment Center.',"\n";
	print OUT "\<a href=\'http://asc.harvard.edu/mta/ace.html\'\>";
	print OUT "Real time ACE Observation\</a\> ","\n";
	print OUT 'is also available.',"\n";
	print OUT '</h3>',"\n";
	print OUT "\n";
	print OUT "\n";
	print OUT '<h2> Click a plot to enlarge</h2>',"\n";
	print OUT '<p>',"\n";
	print OUT 'Note: Data points in 2000 Data are one hour average. All others are ',"\n";
	print OUT '5 min average.',"\n";
	print OUT '</p>',"\n";
	
	print OUT '<font size=+1>',"\n";
	print OUT '<b>',"\n";
	if($which eq 'auto'){
		print OUT '<a href="time_order.html">Time Ordered List</a>',"\n";
		print OUT ' : ',"\n";
		print OUT '<font color=yellow>Auto Shutdown List</font>',"\n";
		print OUT ' : ',"\n";
		print OUT '<a href="manu_shut.html">Manually Shutdown List</a>',"\n";
		print OUT ' : ',"\n";
		print OUT '<a href="hard_order.html">Hardness Ordered List</a>',"\n";
		print OUT '<br>',"\n";
	}elsif($which eq 'manual'){
		print OUT '<a href="time_order.html">Time Ordered List</a>',"\n";
		print OUT ' : ',"\n";
		print OUT '<a href="auto_shut.html">Auto Shutdown List</a>',"\n";
		print OUT ' : ',"\n";
		print OUT '<font color=yellow>Manually Shutdown List</font>',"\n";
		print OUT ' : ',"\n";
		print OUT '<a href="hard_order.html">Hardness Ordered List</a>',"\n";
		print OUT '<br>',"\n";
	}elsif($which eq 'hardness'){
		print OUT '<a href="time_order.html">Time Ordered List</a>',"\n";
		print OUT ' : ',"\n";
		print OUT '<a href="auto_shut.html">Auto Shutdown List</a>',"\n";
		print OUT ' : ',"\n";
		print OUT '<a href="manu_shut.html">Manually Shutdown List</a>',"\n";
		print OUT ' : ',"\n";
		print OUT '<font color=yellow>Hardness Ordered List</font>',"\n";
		print OUT '<br><br>',"\n";
		print OUT 'Hardness here is defined by the maximum ratio of P47/P1060',"\n";
		print OUT '<br>',"\n";
	}elsif($which eq 'time_order'){
		print OUT '<font color=yellow>Time Ordered List</font>',"\n";
		print OUT ' : ',"\n";
		print OUT '<a href="auto_shut.html">Auto Shutdown List</a>',"\n";
		print OUT ' : ',"\n";
		print OUT '<a href="manu_shut.html">Manually Shutdown List</a>',"\n";
		print OUT ' : ',"\n";
		print OUT '<a href="hard_order.html">Hardness Ordered List</a>',"\n";
		print OUT '<br>',"\n";

	}
	print OUT '</font>',"\n";
	print OUT '</b>',"\n";


	print OUT '<ul>',"\n";
	
	for($k = 0; $k < $total; $k++){
        	$sname           = $name[$k];
        	$time            = $start[$k];
		@ttemp           = split(/:/, $time);
		$tyear           = $ttemp[0];
		$tmonth          = $ttemp[1];
 		$tday            = $ttemp[2];
 
 		to_yday();
 
		$time            = "$tyear:$tyday:$ttemp[3]:$ttemp[4]";
        	$time2           = $end[$k];
		@ttemp           = split(/:/, $time2);
		$tyear           = $ttemp[0];
		$tmonth          = $ttemp[1];
		$tday            = $ttemp[2];

		to_yday();

		$time2           = "$tyear:$tyday:$ttemp[3]:$ttemp[4]";
        	$interrupt_time  = $interval[$k];
        	$int_method      = $method[$k];
		$data_file_name  = "$sname".'_dat.txt';
		$data_file_name2 = "$sname".'_eph.txt';
		$note_file_name  = "$sname".'.txt';
	
		$html_name       = "$sname".'.html';
		$stat_name       = "$sname".'_stat';
		$gif_name        = "$sname".'.gif';
		$ephin_gif       = "$sname".'_eph.gif';
		$tiny_name       = "$sname".'_tiny.html';
		$tiny_gif        = "$sname".'_tiny.gif';
	
		print  OUT '<li>',"\n";
		print  OUT '<b>', "Science Run Stop: $time\tStart: $time2\t";
		print  OUT "Interruption: ";
		printf OUT  "%4.1f",$interrupt_time;
		print  OUT "ks\t$int_method",'</b>',"\n";
	
		print  OUT "\<a href=\'./Html_dir/$html_name\'\>";
		print  OUT "\<img src = \'./Tiny_plot/$tiny_gif\'";
		print  OUT "width=\'100%\' height=\'20%\'\>\</a\>\n";
	
		print  OUT "\<a href=\'./Data_dir/$data_file_name\'\>ACE RTSW EPAM Data\</a\>,\n";
		print  OUT "\<a href=\'./Data_dir/$data_file_name2\'\>Ephin Data\</a\>,\n";
		print  OUT "\<a href=\'./Note_dir/$note_file_name\'\>Note\</a\>,\n";
		print  OUT '<br>',"\n";
		print  OUT '<spacer type=vertical size=10>',"\n";
	
		if($print_chk eq  'yes'){
			print_ind_html();
		}
	}
	print OUT  '</ul>',"\n";
	print OUT '</body>',"\n";
	print OUT '</html>',"\n";
	close(OUT);
}

##############################################################
### print_ind_html: create indivisual html pages           ###
##############################################################

sub print_ind_html{
#
#--------printint sub html page
#
	open(OUT2, ">$web_dir/Html_dir/$html_name");
	print  OUT2 '<HTML><BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="#00CCFF" ',"\n";
	print  OUT2 'VLINK="#B6FFFF" ALINK="#FF0000", background ="./stars.jpg">',"\n";

	print  OUT2 '<title>',"$sname",'</title>',"\n ";
	print  OUT2 '<center><h1>',"$time ",'Science Run Interruption</h1></center>';
	print  OUT2 "\n";
	print  OUT2 '<b>', "Science Run Stop:  $time\n";
	print  OUT2 '<br>',"\n";
	print  OUT2        "Science Run Start: $time2\n";
	print  OUT2 '<br>',"\n";
	print  OUT2 "Interruption:";
	printf OUT2 "%4.1f",$interrupt_time;
	print  OUT2 "ks\n";
	print  OUT2 '<br>';
	print  OUT2 "Triggered by: $int_method",'</b>',"\n";

	print  OUT2 '<br>',"\n";
	print  OUT2 '<pre>',"\n";

	open(IN, "$web_dir/Stat_dir/$stat_name");
	while(<IN>){
		print OUT2 "$_";
	}
	close(IN);
	print  OUT2 '</pre>',"\n";
	print  OUT2 '<br>',"\n";
	print  OUT2 '<font size=+1><b>',"\n";
	print  OUT2 "\<a href=\'../Note_dir/$note_file_name\'\>Note\</a\>,\n";
	print  OUT2 '</font></b>';
	print  OUT2 '<br>',"\n";
	print  OUT2 '<br>',"\n";
	print  OUT2 'Red horizontal lines indicate  SCS 107 limits<br>';
	print  OUT2 'Purple hatched areas indicate that the satellite is in the radiation belt<br>';
	print  OUT2 '<br><br>';
	print  OUT2 "\<img src = \'../Main_plot/$gif_name\'  width=\'100%\'\>\n";
	print  OUT2 '<br>',"\n";
	print  OUT2 "\<img src = \'../Ephin_plot/$ephin_gif\' width=\'100%\'\>\n";
	
	print  OUT2 '<br>',"\n";
	print  OUT2 "\<a href=\'../rad_interrupt.html\'\>Back to Main Page</a>\n";

	print  OUT2 '</body>',"\n";
	print  OUT2 '</html>',"\n";

	close(OUT2);
}

##############################################################
### to_dom: change date format to DOM                      ###
##############################################################

sub to_dom{
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
	if($uyear == 2000 || $uyear == 2004 || $uyear == 2008 || $uyear ==2012){
		if($umonth > 2){
			$add++;
		}
	}

        $uyday = $uday + $add;

        if ($uyear == 1999) {
                $dom = $uyday - 202;
        }elsif($uyear >= 2000){
                $dom = $uyday + 163 + 365*($uyear - 2000);
                if($uyear > 2000) {
                        $dom++;
                }
                if($uyear > 2004) {
                        $dom++;
                }
                if($uyear > 2008) {
                        $dom++;
                }
                if($uyear > 2012) {
                        $dom++;
                }
        }
}


##############################################################
### to_yday: change date format to y-date                  ###
##############################################################

sub to_yday{
        if($tmonth == 1){
                $add = 0;
        }elsif($tmonth == 2){
                $add = 31;
        }elsif($tmonth == 3){
                $add = 59;
        }elsif($tmonth == 4){
                $add = 90;
        }elsif($tmonth == 5){
                $add = 120;
        }elsif($tmonth == 6){
                $add = 151;
        }elsif($tmonth == 7){
                $add = 181;
        }elsif($tmonth == 8){
                $add = 212;
        }elsif($tmonth == 9){
                $add = 243;
        }elsif($tmonth == 10){
                $add = 273;
        }elsif($tmonth == 11){
                $add = 304;
        }elsif($tmonth == 12){
                $add = 334;
        }

        $tyday = $tday + $add;

        if($tyear == 2000 && $tmonth > 2) {
                $tyday++;
        }
        if($tyear == 2004 && $tmonth > 2) {
                $tyday++;
        }
        if($tyear == 2008 && $tmonth > 2) {
                $tyday++;
        }
        if($tyear == 2012 && $tmonth > 2) {
                $tyday++;
        }
        if($tyear == 2016 && $tmonth > 2) {
                $tyday++;
        }
        if($tyear == 2020 && $tmonth > 2) {
                $tyday++;
        }
}


