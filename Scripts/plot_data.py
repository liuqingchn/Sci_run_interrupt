#!/usr/bin/env /proj/sot/ska/bin/python

#################################################################################
#                                                                               #
#       plot_data.py: plot all science run interruption related data            #
#                                                                               #
#               author: t. isobe (tisobe@cfa.harvard.edu)                       #
#                                                                               #
#               last update: Apr 30, 2013                                       #
#                                                                               #
#################################################################################

import math
import re
import sys
import os
import string
import numpy as np

#
#--- pylab plotting routine related modules
#
import matplotlib as mpl

if __name__ == '__main__':

    mpl.use('Agg')

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
#--- Science Run Interrupt plot  related funcions shared
#

import interruptPlotFunctions as ptrf

#
#--- Ephin ploting routines
#

import plot_ephin as ephin

#
#---- GOES ploting routiens
#

import plot_goes as goes

#
#---- NOAA plotting routines
#

import plot_noaa_rad as noaa

#
#---- html page pringing
#

import sci_run_print_html as html


#---------------------------------------------------------------------------------------------------------------------
#--- plot_data: plot all data related to the science run interruption (NOAA/EPHIN/GOES)                           ----
#---------------------------------------------------------------------------------------------------------------------

def plot_data():
    
    'plot all data related to the science run interruption (NOAA/EPHIN/GOES)'

    file = raw_input('Please put the intrrupt timing list: ')

    if file == 'test':
#
#--- if this is a test case, prepare for the test
#
        comp_test = 'test'
        file = test_web_dir +'test_date'
    else:
        comp_test = 'NA'

    f     = open(file, 'r')
    data  = [line.strip() for line in f.readlines()]
    f.close()

    for ent in data:
        atemp = re.split('\s+|\t+', ent)
        event = atemp[0]
        start = atemp[1]
        stop  = atemp[2]
        gap   = atemp[3]
        type  = atemp[4]

#
#--- plot Ephin data
#

        ephin.plotEphinMain(event, start, stop, comp_test)

#
#---- plot GOES data
#
        goes.plotGOESMain(event, start, stop, comp_test)

#
#---- plot other radiation data (from NOAA)
#

        noaa.startACEPlot(event, start, stop, comp_test)
        
#
#---- create html pages
#

    if comp_test != 'test':
        html.printEachHtmlControl(file)



#---------------------------------------------------------------------------------------------------------------------
#--- start script                                                                                                  ---
#---------------------------------------------------------------------------------------------------------------------


from pylab import *
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import matplotlib.lines as lines

#
#---- plotting the data and create html pages
#

if __name__ == '__main__':

    plot_data()

