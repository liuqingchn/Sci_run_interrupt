#/usr/bin/perl 

#########################################################################################
#                                                                                       #
#       clean_up_xmm_data.perl: remove all unwanted special character etc               #
#                               from xmm data                                           #
#                                                                                       #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                   #
#                                                                                       #
#           last update: May 27, 2015                                                   #
#                                                                                       #
#########################################################################################

open(FH, '/data/mta4/space_weather/XMM/xmm.archive');
$i = 0;
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    $cnt = 0;
    foreach(@atemp){
        $cnt++;
    }
    if($cnt > 7){
        printf "%d\t", $atemp[0];
        printf "%2.3f\t",  $atemp[1];
        printf "%2.3f\t",  $atemp[2];
        printf "%2.3f\t",  $atemp[3];
        printf "%2.3f\t",  $atemp[4];
        printf "%2.3f\t",  $atemp[5];
        printf "%2.3f\t",  $atemp[6];
        printf "%2.3f\t",  $atemp[7];
        printf "%2.3f\n",  $atemp[8];
    }
}
close(FH);
