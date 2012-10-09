#!/usr/local/bin/python2.6

#################################################################################################################
#                                                                                                               #
#       get_goes_from_noao.py: copy goes data from NOAO to a local directory                                    #
#                                                                                                               #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                                           #
#                                                                                                               #
#           last update Oct 08, 2012                                                                            #
#                                                                                                               #
#################################################################################################################

import math
import re
import sys
import os
import string
import getpass


#
#--- reading directory list
#

path = '/data/mta/Script/Interrupt/house_keeping/dir_list'
f    = open(path, 'r')
data = [line.strip() for line in f.readlines()]
f.close()

for ent in data:
    atemp = re.split(':', ent)
    var  = atemp[1].strip()
    line = atemp[0].strip()
    exec "%s = %s" %(var, line)

#
#--- append path to a privte folder
#
    sys.path.append(bin_dir)
#
#--- converTimeFormat contains MTA time conversion routines
#
import convertTimeFormat as tcnv

#
#--- Science Run Interrupt related funcions shared
#

import interruptFunctions as itrf

#
#--- setting temp directory
#

user = getpass.getuser()
user = user.strip()

if user == 'mta':
    temp_dir = '/tmp/mta/'
elif user == 'cus':
    temp_dir = '/tmp/cus/'
else:
    temp_dir = './'


#-------------------------------------------------------------------------------------------------------------
#--- get_goes_from_noao: copy goes data from NOAO                                                         ----
#-------------------------------------------------------------------------------------------------------------

def get_goes_from_noao():

    """
    copy goes data from NOAO site
    """
#
#--- read the list of the data which we already copied
#
    goes_list = house_keeping + '/NOAO_data/past_goes_list'
    f         = open(goes_list, 'r')
    past_list = [line.strip() for line in f.readlines()]
    f.close()
#
#--- find the current listing at NOAO site
#
    temp_save = temp_dir + 'temp_svave'
    cmd = 'lynx -source http://www.swpc.noaa.gov/ftpdir/lists/pchan/ >' + temp_save
    os.system(cmd)
    
    f   = open(temp_save, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()
    cmd = 'rm ' + temp_save
    os.system(cmd)

    glist = []
    for ent in data:
        m = re.search('_Gp_pchan_5m.txt', ent)
        if m is not None:
            atemp = re.split('href="', ent)
            btemp = re.split('">', atemp[1])
            glist.append(btemp[0])
#
#--- compare two and find which one is new
#
    new_data = list(set(glist).difference(set(past_list)))

#
#--- copy the new data to the local directory
#
    if len(new_data) > 0:
        f2 = open(temp_save, 'w')
        f2.write('The following GOES data were copied from NOAO site \n\n')

        f  = open(goes_list, 'a')
        for ent in new_data:
            out = house_keeping + '/NOAO_data/' + ent
    
            cmd = 'lynx -source http://www.swpc.noaa.gov/ftpdir/lists/pchan/' + ent + '>' + out
            os.system(cmd)
    
            f.write(ent)
            f.write('\n')
    
            f2.write(ent)
            f2.write('\n')
    
        f2.write('\n\n If you like to check, please go to /data/mta/Script/Interrupt/house_keeping/NOAO_data.\n')
        f.close()
        f2.close()

#
#--- notify admim the fact that the data were copied
#

        cmd = 'cat ' + temp_save + ' | mailx -s"Subject: NOAO Data Copied" isobe@head.cfa.harvard.edu'
        os.system(cmd)

    else:
#
#---- if there is no new data, something not quite right. notify the fact so that admin can check what is going on
#
        f2 = open(temp_save, 'w')
        f2.write('No data was copied from NOAO this week. Please check whether this is correct or not:  \n\n')
        f2.write('Local directory: /data/mta/Script/Interrupt/house_keeping/NOAO_data\n\n')
        f2.write('NOAO Site:  http://www.swpc.noaa.gov/ftpdir/lists/pchan/ \n\n')
        f2.close()

        cmd = 'cat ' + temp_save + ' | mailx -s"Subject:  No NOAO Data Copied" isobe@head.cfa.harvard.edu'
        os.system(cmd)

    cmd = 'rm ' + temp_save
    os.system(cmd)



#--------------------------------------------------------------------------------------------------------------

if __name__ == "__main__":

    get_goes_from_noao()

