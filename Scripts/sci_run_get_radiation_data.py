#!/usr/local/bin/python2.6

#########################################################################################
#                                                                                       #
#       sci_run_get_radiation_data.py: get NOAA data for radiaiton plots                #
#                                                                                       #
#               this script must be run on rhodes to access noaa data                   #
#                                                                                       #
#                                                                                       #
#               author: t. isobe (tisobe@cfa.harvard.edu)                               #
#                                                                                       #
#               last update: May 02, 2012                                               #
#                                                                                       #
#########################################################################################

import os
import sys
import re
import string

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
#--- append a path to a privte folder to python directory
#

sys.path.append(bin_dir)

#
#--- converTimeFormat contains MTA time conversion routines
#

import convertTimeFormat as tcnv


#-----------------------------------------------------------------------------------------------
#--- sci_run_get_radiation_data: extract radiation data                                      ---
#-----------------------------------------------------------------------------------------------

def sci_run_get_radiation_data():

    'extract needed radiation data from /data/mta4/www/DAILY/mta_rad/ACE/, and put in rada_data<YYYYY>, where YYYY is the year'

#
#--- find out today's date in Local time frame
#

    today = tcnv.currentTime('local')
    year  = today[0]
    month = today[1]
    day   = today[2]

    if month ==1 and day == 1:
#
#--- this is a new year... complete the last year
#
        year -= 1

#
#--- extract data form ACE data files
#

    line = '/data/mta4/www/DAILY/mta_rad/ACE/' + str(year) + '*_ace_epam_5m.txt'
    cmd  = 'cat ' + line + ' > /tmp/mta/ztemp'
    cmd  = 'cat ' + line + ' > ./ztemp'
    os.system(cmd)

#>    f = open('/tmp/mta/ztemp', 'r')
    f = open('./ztemp', 'r');
    data  = [line.strip() for line in f.readlines()]
    f.close()

#>    system('rm /tmp/mta/ztemp')
    os.system('rm ./ztemp')

#
#--- move the old file to "~" to prepare for the new data
#

    name    = 'rad_data' + str(year)

    oldFile = house_keeping + name + '~'
    crtFile = house_keeping + name 

    cmd     = 'chmod 775 ' + crtFile + ' ' +  oldFile
    os.system(cmd)

    cmd     = 'mv ' + crtFile + ' ' + oldFile
    os.system(cmd)

    cmd     = 'chmod 644 ' +  oldFile
    os.system(cmd)

    f = open(crtFile, 'w')   

    for ent in data:

#
#--- remove comments and headers
#

        m = re.search('^#', str(ent))
        n = re.search('^:', str(ent))
        if (m is  None) and (n is  None):
            line = ent + '\n'
            f.write(line)

    f.close()
            
#--------------------------------------------------------------------

if __name__ == '__main__':
    sci_run_get_radiation_data()


