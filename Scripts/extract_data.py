#!/usr/local/bin/python2.6

#################################################################################
#                                                                               #
#       extract_data.py: extract data needed for sci. run interruption plots    #
#                                                                               #
#               author: t. isobe (tisobe@cfa.harvard.edu)                       #
#                                                                               #
#               last update: May 02, 2012                                       #
#                                                                               #
#################################################################################

import math
import re
import sys
import os
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

#
#--- Science Run Interrupt related funcions shared
#

import interruptFunctions as itrf

#
#---- EPHIN data extraction
#

import extract_ephin as ephin

#
#---- GOES data extraction
#

import extract_goes as goes

#
#---- ACE (NOAA) data extraction
#

import extract_noaa as noaa

#
#---- ACE (NOAA) statistics

import compute_ace_stat as astat

#---------------------------------------------------------------------------------------------------------------------
#--- extract_data: extract ephin and GOES data. this is a control and call a few related scripts                   ---
#---------------------------------------------------------------------------------------------------------------------

def extract_data():
    
    'extract ephin and GOES data. this is a control and call a few related scripts '

    
    file = raw_input('Please put the intrrupt timing list: ')
#
#--- update radiation zone list (rad_zone_list) for given period(s)
#

    itrf.sci_run_add_to_rad_zone_list(file)

#
#--- correct science run interruption time excluding radiation zones
#

    itrf.sci_run_compute_gap(file)

    f    = open(file, 'r')
    data  = [line.strip() for line in f.readlines()]
    f.close()

    for ent in data:
        if not ent:
            break

        atemp = re.split('\s+|\t+', ent)
        event = atemp[0]
        start = atemp[1]
        stop  = atemp[2]
        gap   = atemp[3]
        type  = atemp[4]
#
#--- extract ephin data
#
        ephin.ephinDataExtract(event, start, stop)

#
#--- compute ephin statistics
#
        ephin.computeEphinStat(event, start)

#
#---- extract GOES data
#

        goes.extractGOESData(event, start, stop)

#
#---- compute GOES statistics
#
        goes.computeGOESStat(event, start)

#
#---- extract ACE (NOAA) data
#
        noaa.startACEExtract(event, start, stop)

#
#---- compute ACE statistics
#
	astat.computeACEStat(event, start, stop)



#---------------------------------------------------------------------------------------------------------------------
#--- start script                                                                                                  ---
#---------------------------------------------------------------------------------------------------------------------


if __name__ == '__main__':

    extract_data()
