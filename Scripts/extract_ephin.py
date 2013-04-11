#!/usr/bin/env /proj/sot/ska/bin/python

#################################################################################
#                                                                               #
#       extract_ephin.py: extract Ephin data and plot the results               #
#                                                                               #
#               author: t. isobe (tisobe@cfa.harvard.edu)                       #
#                                                                               #
#               last update: apr 11, 2013                                       #
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

#---------------------------------------------------------------------------------------------------------------------
#--- ephinDataExtract: extract EPHIN data and create a data table                                                  ---
#---------------------------------------------------------------------------------------------------------------------

def ephinDataExtract(event, start, stop, comp_test ='NA'):

    "extract EPIN related quantities and creates a data table for given event, start and stop time (format: 2012:03:13:22:41)"
    begin = start + ':00'               #---- to use dateFormatCon correctly, need to add "sec" part
    end   = stop  + ':00'

#
#--- convert time format
#
    (year1, month1, day1, hours1, minutes1, seconds1, ydate1) = tcnv.dateFormatCon(begin)
    (year2, month2, day2, hours2, minutes2, seconds2, ydate2) = tcnv.dateFormatCon(end)

#
#--- change time format and find data collecting period (starts 2 days before the interruption and ends at least 5 days after the stating)
#

    (pYearStart, periodStart, pYearStop, periodStop, plotYearStart, plotStart, plotYearStop, plotStop, pannelNum)   \
            = itrf.findCollectingPeriod(year1, ydate1, year2, ydate2)

#
#--- read ephin data using arc4gl
#
    ephinList = itrf.useArc4gl('retrieve', 'flight', 'ephin', 1, 'ephrates', pYearStart, periodStart, pYearStop, periodStop, deposit='./Working_dir',) 

#
#--- extract needed data
#
    xdate = []
    p4    = []
    p41   = []
    e150  = []
    e1300 = []
    ecnt  = 0

    for fits in ephinList:
#
#--- use dmlist
#
        if pYearStart < 2011:
            line = fits + '[cols TIME, SCP4, SCP41, SCE1300]'
        else:    
            line = fits + '[cols TIME, SCE150, SCE1300]'

        cmd = 'dmlist "' + line + '" opt="data" > ./zout'
        os.system(cmd)

        f = open('./zout', 'r')
        input = [line.strip() for line in f.readlines()]
        f.close()
        os.system('rm ./zout')

        for ent in input:
            ent.lstrip()
            atemp = re.split('\s+|\t+', ent)
            if atemp[0].isdigit():
                line = tcnv.convertCtimeToYdate(float(atemp[1]))
                (year, month, day, hours, minute, second, ydate, dom, sectime) = tcnv.dateFormatConAll(line)
#
#--- checking the case the year change
#
                if ecnt > 0 and year != startYear:
                        ydate += base
                elif ecnt == 0:
                        startYear = year
                        chk = 4.0 * int(0.25 * year)
                        if chk == year:
                            base = 366
                        else:
                            base = 365

                xdate.append(ydate)

                if pYearStart < 2011:
   
                    if float(atemp[3]) == 0:
                        atemp[3] = 1.0e-4
                    if float(atemp[4]) == 0:
                        atemp[4] = 1.0e-4

                    p4.append(atemp[2])
                    p41.append(atemp[3])
                    e1300.append(atemp[4])
                else:
                    if float(atemp[2]) == 0:
                        atemp[2] = 1.0e-4
                    if float(atemp[3]) == 0:
                        atemp[3] = 1.0e-4

                    e150.append(atemp[2])
                    e1300.append(atemp[3])

                ecnt += 1

    os.system('rm ./Working_dir/*fits')

#
#--- using DataSeeker, extread HRC sheild rate (only if year > 2011)
#
    if pYearStart >= 2011:

        hrcData = itrf.useDataSeeker(pYearStart, periodStart, pYearStop, periodStop, 'mtahrc..hrcveto_avg', 'time,shevart_avg')

        time = []
        veto = []
        hcnt = 0

#
#--- there are slightly different input line format; so we need to different ways to read the line
#
        for ent in hrcData:
            m1 = re.search('----', ent)
            m2 = re.search('ROW',  ent)
            m3 = re.search('DATASEEK', ent)
    
            if ent and m1 == None and m2 == None and m3 == None:
    
                atemp = re.split('\s+|\t+', ent)
    
                if len(atemp) == 4:
                    ttime = tcnv.convertCtimeToYdate(float(atemp[2]))
                    temp  = re.split(':', ttime)
                    year  = int(temp[0])
                    dofy  = float(temp[1]) + float(temp[2]) / 24 + float(temp[3]) / 1440 + float(temp[4]) / 86400
#
#--- checking the case the year changes
#
                    if hcnt > 0 and year != startYear:
                        dofy += base
                    elif hcnt == 0:
                        startYear = year
                        chk = 4.0 * int(0.25 * year)
                        if chk == year:
                            base = 366
                        else:
                            base = 365
             
                    time.append(dofy)
                    veto.append(atemp[3])
                    hcnt += 1
     
                else:     
                    ttime = tcnv.convertCtimeToYdate(float(atemp[1]))
                    temp  = re.split(':', ttime)
                    year  = int(temp[0])
                    dofy  = float(temp[1]) + float(temp[2]) / 24 + float(temp[3]) / 1440 + float(temp[4]) / 86400
                    if hcnt > 0 and year != startYear:
                        dofy += base
                    elif hcnt == 0:
                        startYear = year
                        chk = 4.0 * int(0.25 * year)
                        if chk == year:
                            base = 366
                        else:
                            base = 365
             
                    time.append(dofy)
                    veto.append(atemp[2])
                    hcnt += 1

#
#--- matching timing between electron data and hrc data
#
        hrc = len(e150) * [0]
        j   = 0
        k   = 0

#
#--- find the begining
#
        if time[0] < xdate[0]:
            while time[j] < xdate[0]:
                j += 1
                if j >= hcnt:
                    print "Time span does not overlap. Abort the process."
                    exit(1)
    
        elif  time[0] > xdate[0]:
            while time[0] > xdate[k]:
                k += 1
                if k >= ecnt:
                    print "Time span does not overlap. Abort the process."
                    exit(1)
    
        hrc[k] = veto[j]
        
        tspace = 1.38888888888e-3 / base            #--- setting timing bin size: base is given in hrc loop
    
        for i in range(k+1, ecnt):
            tbeg = xdate[i] - tspace
            tend = xdate[i] + tspace
    
            if j > hcnt - 2:
                hrc[i] = veto[hcnt -1]              #---- if the hrc data runs out, just repeat the last data point value
    
            elif time[j] >= tbeg and time[j] <= tend:
                hrc[i] = veto[j]
    
            elif time[j] < tbeg:
                while time[j] < tbeg:
                    j += 1
                hrc[i] = veto[j]
    
            elif time[j] > tend:
                while time[j] > tend:
                    j -= 1
                hrc[i] = veto[j]

#
#--- print out data
#

    if comp_test == 'test':
        file = test_data_dir + event + '_eph.txt'
    else:
        file = data_dir + event + '_eph.txt'

    f    = open(file, 'w')
    line = 'Science Run Interruption: ' + start + '\n\n'
    f.write(line)

    if pYearStart < 2011:
        f.write('dofy\t\tp4\t\t\tp41\t\t\te1300\n')
        f.write('-------------------------------------------------------------------\n')
    
        for m in range(0, ecnt):
            line = '%4.3f\t\t%4.3e\t%4.3e\t%4.3e\n' % (float(xdate[m]), float(p4[m]), float(p41[m]),  float(e1300[m]))
            f.write(line)

    else:
        f.write('dofy\t\thrc\t\te150\t\te1300\n')
        f.write('-------------------------------------------------------------------\n')
    
        for m in range(0, ecnt):
            line = '%4.3f\t\t%4.3e\t%4.3e\t%4.3e\n' % (float(xdate[m]), float(hrc[m]), float(e150[m]),  float(e1300[m]))
            f.write(line)

    f.close()





#--------------------------------------------------------------------
#--- computeEphinStat: computing Ephin statitics                  ---
#--------------------------------------------------------------------

def computeEphinStat(event, startTime, comp_test = 'NA'):

    'for give event name and interruption stating time, read the data from ephin data, and compute statistics'

    begin = startTime + ':00'           #---- modify the format to work with dateFormatCon

    (year, month, day, hours, minutes, seconds, interruptTime) = tcnv.dateFormatCon(begin)

    if comp_test == 'test':
        file = test_data_dir + event + '_eph.txt'
    else:
        file = data_dir + event + '_eph.txt'

    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    hrcAvg       = 0
    hrcAvg2      = 0
    hrcMax       = -1e5
    hrcMin       =  1e8
    hrcMaxTime   = 0
    hrcMinTime   = 0
    hrcIntValue  = 0

    e150Avg      = 0
    e150Avg2     = 0
    e150Max      = -1e5
    e150Min      =  1e8
    e150MaxTime  = 0
    e150MinTime  = 0
    e150IntValue = 0

    e1300Avg     = 0
    e1300Avg2    = 0
    e1300Max     = -1e5
    e1300Min     =  1e8
    e1300MaxTime = 0
    e1300MinTime = 0
    e1300IntValue= 0

    hcnt         = 0
    e1cnt        = 0
    e2cnt        = 0
    ind          = 0                                    #---- indicator whther the loop passed the interruption time

    dataset      = 0

    for ent in data:
        m1 = re.search('Interruption', ent)
        m2 = re.search('dofy', ent)
        m3 = re.search('----', ent)
        m4 = re.search('hrc',  ent)
#
#--- checking new (hrc, e150, e1300) or old (p4 , p41, e1300) dataset
#
        if m4 is not None:
           dataset = 1

        if ent and m1 == None and m2 == None and m3 == None:

            atemp = re.split('\s+|\t+', ent)
            val0  = float(atemp[0])
            val1  = float(atemp[1])
            val2  = float(atemp[2])
            val3  = float(atemp[3])
            

            if val1 > 0:                                #--- 0 could mean that there is no data; so we ignore it
                hrcAvg    += val1
                hrcAvg2   += val1 * val1
    
                if val1 > hrcMax:
                    hrcMax     = val1
                    hrcMaxTime = val0
                elif val1 < hrcMin:
                    hrcMin     = val1
                    hrcMinTime = val0
                hcnt += 1

            if val2 > 0:
                e150Avg   += val2
                e150Avg2  += val2 * val2

                if val2 > e150Max:
                    e150Max     = val2
                    e150MaxTime = val0
                elif val2 < e150Min:
                    e150Min     = val2
                    e150MinTime = val0
                e1cnt += 1


            if val3 > 0:
                e1300Avg  += val3
                e1300Avg2 += val3 * val3
    
                if val3 > e1300Max:
                    e1300Max     = val3
                    e1300MaxTime = val0
                elif val3 < e1300Min:
                    e1300Min     = val3
                    e1300MinTime = val0
                e2cnt += 1
#
#--- finding the value at the interruption
#
            if interruptTime <= val0 and ind == 0:
                hrcIntValue   = val1
                e150IntValue  = val2
                e1300IntValue = val3
                ind = 1

#
#--- compute averages
#
    hrcAvg   /= hcnt
    e150Avg  /= e1cnt
    e1300Avg /= e2cnt
#
#--- compute stndard deviation
#

    hrcSig    = math.sqrt(hrcAvg2/hcnt    - hrcAvg   * hrcAvg)
    e150Sig   = math.sqrt(e150Avg2/e1cnt  - e150Avg  * e150Avg)
    e1300Sig  = math.sqrt(e1300Avg2/e2cnt - e1300Avg * e1300Avg)

#    file = web_dir + 'Ephin_plot/' + event + '_txt'

    if comp_test == 'test':
        file = test_stat_dir + event + '_ephin_stat'
    else:
        file = stat_dir + event + '_ephin_stat'

    f    = open(file, 'w')
    f.write('\t\tAvg\t\t\tMax\t\tTime\t\tMin\t\tTime\t\tValue at Interruption Started\n')
    f.write('--------------------------------------------------------------------------------------------------------------------------\n')

    if dataset == 1:
        f.write('hrc\t')
    else:
        f.write('p4\t')

    if hrcIntValue > 0:

        line = '%2.3e +/- %2.3e\t\t%2.3e\t%4.3f\t\t%2.3e\t%4.3f\t\t%2.3e\n' % (hrcAvg, hrcSig, hrcMax, hrcMaxTime, hrcMin, hrcMinTime, hrcIntValue)
    else:
        line = 'hrc\t%2.3e +/- %2.3e\t\t%2.3e\t%4.3f\t\t%2.3e\t%4.3f\t\tNA\n' % (hrcAvg, hrcSig, hrcMax, hrcMaxTime, hrcMin, hrcMinTime)

    f.write(line)

    if dataset == 1:
        f.write('e150\t')
    else:
        f.write('p41\t')

    line = '%2.3e +/- %2.3e\t\t%2.3e\t%4.3f\t\t%2.3e\t%4.3f\t\t%2.3e\n' % (e150Avg, e150Sig, e150Max, e150MaxTime, e150Min, e150MinTime, e150IntValue)
    f.write(line)

    line = 'e1300\t%2.3e +/- %2.3e\t\t%2.3e\t%4.3f\t\t%2.3e\t%4.3f\t\t%2.3e\n' % (e1300Avg, e1300Sig, e1300Max, e1300MaxTime, e1300Min, e1300MinTime, e1300IntValue)
    f.write(line)

    f.close()
    
