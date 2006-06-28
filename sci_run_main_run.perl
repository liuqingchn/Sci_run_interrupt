#!/usr/bin/perl

#################################################################################################
#												#
#	sci_run_main_run.perl: this script runs all science run interrupt scripts		#
#												#
#		this script must be run on rhodes						#
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

$bin_dir       = '/data/mta4/MTA/bin/';
$data_dir      = '/data/mta4/MTA/data/';
$web_dir       = '/data/mta/www/mta_interrupt/';
$house_keeping = '/data/mta/www/mta_interrupt/house_keeping/';

$web_dir       = '/data/mta/www/mta_interrupt_test/';
$house_keeping = '/data/mta/www/mta_interrupt_test/house_keeping/';
#################################################################

#
#--- create a directory file so that all other script can read it
#

open(OUT, '>./dir_list');
print OUT "$bin_dir\n";
print OUT "$data_dir\n";
print OUT "$web_dir\n";
print OUT "$house_keeping\n";
close(OUT);

#
#--- this is the file containing a new science run interruption information
#--- name            start                   stop                    Int     method
#--- ==============================================================================
#--- 20021126        2002:11:26:19:02        2002:11:27:22:30        90.5    manual
#

$file = $ARGV[0];
chomp $file;

open(FH, "$file");
@line_list = ();
while(<FH>){
	chomp $_;
	push(@line_list, $_);
}
close(FH);

#
#--- if there are multiple entries, the script handles them separately
#

foreach $ent (@line_list){

#
#--- find out which rad_data<yyyy> we should use
#

	@line_cont = split(/\s+/, $ent);
	@date      = split(//, $line_cont[0]);
	$year      = "$date[0]$date[1]$date[2]$date[3]";
	$rad_data  = 'rad_data'."$year";

	$note_file = "$web_dir".'Note_dir/'."$line_cont[0]".'.txt';

	open(OUT, ">$note_file");
	print OUT "this is a note file for science run interruption occured on $line_cont[0]\n";
	close(OUT);
#
#--- crate input file for each script
#

	$input_file = "file_$line_cont[0]";

	open(OUT, ">$input_file");
	print OUT "$ent\n";
	close(OUT);

	system("perl $bin_dir/sci_run_add_to_rad_zone_list.perl $input_file");

	system("perl $bin_dir/sci_run_compute_gap.perl $input_file");

	system("perl $bin_dir/sci_run_rad_plot.perl $rad_data $file");

	system("perl $bin_dir/sci_run_ephin_plot_main.perl $input_file");

	system("perl $bin_dir/sci_run_find_hardness.perl $input_file");

	system("perl $bin_dir/sci_run_print_html.perl $input_file");

	system("perl $bin_dir/sci_run_print_top_html.perl all_data");
}

######## system("rm ./dir_list $input_file");








