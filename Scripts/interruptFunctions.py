#!/usr/local/bin/python2.6

#################################################################################################################
#                                                                                                               #
#       interruptFunctions.py: collections of python scripts for science run interruption computation           #
#                                                                                                               #
#               author: t. isobe (tisobe@cfa.harvard.edu)                                                       #
#                                                                                                               #
#               last update: May. 18, 2012                                                                      #
#                                                                                                               #
#################################################################################################################

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



#---------------------------------------------------------------------------------------------------------
#--- findCollectingPeriod: find start and ending time of data collecting/plotting period               ---
#---------------------------------------------------------------------------------------------------------

def findCollectingPeriod(startYear, startYday, stopYear, stopYday):

    'for given, starting year/ydate, stopping year/ydate of the interruption, set data collecting/plotting period. output are: data collecting starting year, yday, stopping year, yday, plotting starting year, yday, plotting stopping year, yday, and numbers of pannel needed to complete the plot.'

#   
#--- set up extract time period; starting 2 days before the interruption starts
#--- and end 5 days after the interruption ends.
#

#
#--- check beginning
#
    pYearStart  = startYear
    periodStart = startYday - 2
#   
#--- for the case the period starts from the year before
#
    if periodStart < 1:
        pYearStart -= 1

        chk = 4.0 * int(0.25 * pYearStart)
        if chk == pYearStart:
            base = 366
        else:
            base = 365

        periodStart += base

#
#--- check ending. If the interruption does not finish in a 5 day period, extend
#--- the period at 5 day step wise until it covers the entier interruption period.
#

    chk = 4.0 * int(0.25 * pYearStart)
    if chk == pYearStart:
        base = 366
    else:
        base = 365

    if stopYear == pYearStart:
        pYearStop  = pYearStart
        period     = int((stopYday - periodStart) / 5) + 1
        periodStop = periodStart + 5 * period

        if periodStop > base:
            periodStop -= base
            pYearStop  += 1
    else:
#   
#--- for the case stopYear > pYearStop
#
        pYearStop  = stopYear
        period     = int((stoyYday + base - periodStart) /5 ) + 1
        periodStop = periodStart + 5 * period - base

#
#--- setting plotting time span
#
    plotYearStart = pYearStart
    plotStart     = periodStart
    plotYearStop  = pYearStop
    plotStop      = periodStop

    if plotYearStop > plotYearStart:
        chk = 4.0 * int(0.25 * plotYearStart)

        if chk == plotYearStart:
            base = 366
        else:
            base = 365

        plotYearStop = plotYearStart
        periodStop  += base

#    pannelNum    = int((plotStop - plotStart) / 5)      	#---- the number of panels needed
    pannelNum    = period      	                                #---- the number of panels needed


    return (pYearStart, periodStart, pYearStop, periodStop, plotYearStart, plotStart, plotYearStop, plotStop, pannelNum)

#----------------------------------------------------------------------------------------------------------
#--- useArcrgl: extrat data using arc4gl                                                                ---
#----------------------------------------------------------------------------------------------------------

def useArc4gl(operation, dataset, detector, level, filetype, startYear = 0, startYdate = 0, stopYear = 0 , stopYdate = 0,  deposit='./', filename='NA'):

    "extract data using arc4gl. input: start, stop (year and ydate), operation (e.g., retrive), dataset (e.g. flight), detector (e.g. hrc), level (eg 0, 1, 2), filetype (e.g, evt1), and output file: deposit. return the list of the file name."


#
#--- read a couple of information needed for arc4gl
#

    line   = bindata_dir + '.dare'
    f      = open(line, 'r')
    dare   = f.readline().strip()
    f.close()
    
    line   = bindata_dir + '.hakama'
    f      = open(line, 'r')
    hakama = f.readline().strip()
    f.close()
    
#
#--- use arc4gl to extract ephin data
#
    (year1, month1, day1, hours1, minute1, second1, ydate1) = tcnv.dateFormatCon(startYear, startYdate)
    
    (year2, month2, day2, hours2, minute2, second2, ydate2) = tcnv.dateFormatCon(stopYear, stopYdate)

    stringYear1 = str(year1)
    stringYear2 = str(year2)
    arc_start = str(month1) + '/' + str(day1) + '/' + stringYear1[2] + stringYear1[3] + ',' + str(hours1) + ':'+ str(minute1) + ':00'
    arc_stop  = str(month2) + '/' + str(day2) + '/' + stringYear2[2] + stringYear2[3] + ',' + str(hours2) + ':'+ str(minute2) + ':00'

    f = open('./arc_file', 'w')
    line = 'operation=' + operation + '\n'
    f.write(line)
    line = 'dataset=' + dataset + '\n'
    f.write(line)
    line = 'detector=' + detector + '\n'
    f.write(line)
    line = 'level=' + str(level) + '\n'
    f.write(line)
    line = 'filetype=' + filetype + '\n'
    f.write(line)

    if filename != 'NA':
	line = 'filename=' + filename
	f.write(line)
    else:
    	f.write('tstart=')
    	f.write(arc_start)
    	f.write('\n')
    	f.write('tstop=')
    	f.write(arc_stop)
    	f.write('\n')

    f.write('go\n')
    f.close()

#
#--- for the command is to retrieve: extract data and return the list of the files extreacted
#
    if operation == 'retrieve':
    	cmd = 'echo ' + hakama + ' |arc4gl -U' + dare + ' -Sarcocc -i arc_file'
    	os.system(cmd)
    	cmd = 'mv *ephinf*.gz ' + deposit
    	os.system(cmd)
    	cmd = 'gzip -d ' + deposit + '/*gz'
    	os.system(cmd)
    	os.system('ls ./Working_dir/ephinf*.fits > ./zlist')

    	f = open('./zlist', 'r')
    	data = [line.strip() for line in f.readlines()]
    	f.close()
    	os.system('rm ./arc_file ./zlist')
	
    	return data                             #--- list of the file names
#
#--- for the command is to browse: return the list of fits file names
#
    else:
    	cmd = 'echo ' + hakama + ' |arc4gl -U' + dare + ' -Sarcocc -i arc_file > file_list'
	os.system(cmd)
	f = open('./file_list', 'r')
	data = [line.strip() for line in f.readlines()]
	f.close()
	os.system('rm /arc_file ./file_list')
	
	return data



#-----------------------------------------------------------------------------------------------------------------------
#--- useDataSeeker: extract data using dataseeker.pl                                                                 ---
#-----------------------------------------------------------------------------------------------------------------------

def useDataSeeker(startYear, startYdate, stopYear, stopYdate, extract, colList):

    "extract data using dataseeker. Input:  start, stop (e.g., 2012:03:13:22:41), the list name (e.g., mtahrc..hrcveto_avg), colnames: 'time,shevart_avg'"

#
#--- set dataseeker input file
#

    (year1, month1, day1, hours1, minute1, second1, ydate1, dom1, sectime1) = tcnv.dateFormatConAll(startYear, startYdate)

    (year2, month2, day2, hours2, minute2, second2, ydate2, dom2, sectime2) = tcnv.dateFormatConAll(stopYear, stopYdate)

    f = open('./ds_file', 'w')
    line = 'columns=' + extract + '\n'
    f.write(line)
    line = 'timestart=' + str(sectime1) + '\n'
    f.write(line)
    line = 'timestop='  + str(sectime2) + '\n'
    f.write(line)
    f.close()

    cmd = 'punlearn dataseeker; dataseeker.pl infile=ds_file print=yes outfile=./ztemp.fits'
    os.system(cmd)
    cmd = 'dmlist "./ztemp.fits[cols '+ colList + '] " opt=data > ./zout_file'
    os.system(cmd)

    f = open('./zout_file', 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    os.system('rm ./ds_file  ./ztemp.fits ./zout_file')

    return data


#------------------------------------------------------------------------------------------------------------------
#--- sci_run_add_to_rad_zone_list: adding radiation zone list to rad_zone_list                                  ---
#------------------------------------------------------------------------------------------------------------------

def sci_run_add_to_rad_zone_list(file='NA'):

    'adding radiation zone list to rad_zone_list. input: file name containing: e.g. 20120313        2012:03:13:22:41        2012:03:14:13:57         53.3   auto'
    
#
#--- check whether the list alread exists; if it does, read which ones are already in the list
#
    cmd = 'ls ' + house_keeping + '* > ./ztemp'
    os.system(cmd)
#    f    = open('./ztemp', 'r')
#    test = f.readlines()
#    f.close()
    test = open('./ztemp').read()
 
    m1   = re.search('rad_zone_list',  test)
    m2   = re.search('rad_zone_list~', test)

    eventList = []
    echk      = 0
    if m1 is not None:
        line = house_keeping + 'rad_zone_list'
        f    = open(line, 'r')
        data = [line.strip() for line in f.readlines()]
        f.close()

        for ent in data:
            atemp = re.split('\s+|\t+', ent)
            eventList.append(atemp[0])
            echk = 1


#
#--- if file is not given (if it is NA), ask the file input
#

    if file == 'NA':
        file = raw_input('Please put the intrrupt timing list: ')

    f    = open(file, 'r')
    data  = [line.strip() for line in f.readlines()]
    f.close()

#
#--- put the list in the reverse order
#
    data.reverse()

    for ent in data:
        if not ent:
            break

#
#--- a starting date of the interruption in yyyy:mm:dd:hh:mm (e.g., 2006:03:20:10:30)
#--- there could be multiple lines of date; in that is the case, the scripts add the rad zone list
#--- to each date
#

        etemp = re.split('\s+', ent)
        echk = 0
        for comp in eventList:
           if comp == etemp[0]:
               echk = 1
               break

        if echk == 0:
    
            atemp = re.split(':', etemp[1])
            year  = atemp[0]
            month = atemp[1]
            date  = atemp[2]
            hour  = atemp[3]
            mins  = atemp[4]

#
#--- convert to dom/sec1998
#
            ydate = tcnv.findYearDate(int(year), int(month), int(date))
            dom   = tcnv.findDOM(int(year), int(ydate))
            line  = year + ':' + str(int(ydate)) + ':' + hour + ':' + mins + ':00'
            csec  = tcnv.axTimeMTA(line)

#
#--- end date
#

            atemp  = re.split(':', etemp[2])
            eyear  = atemp[0]
            emonth = atemp[1]
            edate  = atemp[2]
            ehour  = atemp[3]
            emins  = atemp[4]
     
            ydate = tcnv.findYearDate(int(eyear), int(emonth), int(edate))
            line  = eyear + ':' + str(int(ydate)) + ':' + ehour + ':' + emins + ':00'
            csec2 = tcnv.axTimeMTA(line)

#
#--- date stamp for the list
#
            list_date = str(year) + str(month) + str(date)

#
#--- check radiation zones for 3 days before to 5 days after from the interruptiondate
#--- if the interruption lasted longer than 5 days, extend the range 7 more days
#

            begin = dom - 3
            end   = dom + 5

            diff = csec2 - csec
            if diff > 432000:
                end += 7

#
#--- read radiation zone infornation
#

            infile = house_keeping + '/rad_zone_info'
            f      = open(infile, 'r')
            rdata  = [line.strip() for line in f.readlines()]
            f.close()
        
            status = []
            rdate  = []
            chk    = 0
            last_st= ''
            cnt    = 0
        
            for line in rdata:
                atemp = re.split('\s+', line)
        
                dtime = float(atemp[1])                 #--- dom of the entry or exit
        
                if chk  == 0 and atemp[0] == 'ENTRY' and dtime >= begin:
                    status.append(atemp[0])
                    rdate.append(dtime)
                    chk += 1
                    last_st = atemp[0]
                    cnt += 1
                elif chk > 0 and dtime >= begin and dtime <= end:
                    status.append(atemp[0])
                    rdate.append(dtime)
                    last_st = atemp[0]
                    cnt += 1
                elif atemp[1] > end and last_st == 'EXIT':
                    break
                elif atemp[1] > end and last_st == 'ENTRY':
                    status.append(atemp[0])
                    rdate.append(dtime)
                    cnt += 1
                    break
            
            f = open('./temp_zone', 'w')

#
#--- a format of the output is, e.g.: '20120313    (4614.2141112963,4614.67081268519):...'
#

            line = list_date + '\t'
            f.write(line)
        
            upper = cnt -1
            i = 0;
            while i < cnt:
                line = '(' + str(rdate[i]) + ','
                f.write(line)
                i += 1
                if i < upper:
                    line = str(rdate[i]) + '):'
                    f.write(line)
                else:
                    line = str(rdate[i]) + ')\n'
                    f.write(line)
                i += 1
        
            f.close()

#
#--- append the past rad zone list 
#

            oldFile = house_keeping + '/rad_zone_list~'
            crtFile = house_keeping + '/rad_zone_list'
    
            if m1 is not None:
                cmd = 'cat '+ './temp_zone ' + crtFile +  ' > ./temp_comb'
                os.system(cmd)
    
            else:
                os.system('mv .temp_zone ./temp_comb')

            os.system('rm ./temp_zone')

#
#--- save the old file and move the update file to rad_zone_list
#

            if m2 is not None:
                cmd     = 'chmod 775 ' + crtFile + ' ' +  oldFile
                os.system(cmd)
        
            if m1 is not None:
                cmd     = 'mv ' + crtFile + ' ' + oldFile
                os.system(cmd)
        
                cmd     = 'chmod 644 ' +  oldFile
                os.system(cmd)
        
            cmd     = 'mv  ' + './temp_comb ' + crtFile
            os.system(cmd)





#--------------------------------------------------------------------------------------------------------------------
#--- sci_run_compute_gap: for given data, recompute the science run lost time excluding rad zones                 ---
#--------------------------------------------------------------------------------------------------------------------

def sci_run_compute_gap(file = 'NA'):

    'for a given file name which contains a list like: "20120313        2012:03:13:22:41        2012:03:14:13:57         53.3   auto", recompute the lost science time (excluding radiation zone) '

#
#--- if file is not given (if it is NA), ask the file input
#

    if file == 'NA':
        file = raw_input('Please put the intrrupt timing list: ')

    f = open(file, 'r')
    data  = [line.strip() for line in f.readlines()]
    f.close()

#
#--- a starting date of the interruption in yyyy:mm:dd:hh:mm (e.g., 2006:03:20:10:30)
#--- there could be multiple lines of date; in that is the case, the scripts add the rad zone list
#--- to each date
#

    update = []

    for ent in data:

        if not ent:                         #--- if it is a blank line end the operation
            break

        etemp = re.split('\s+', ent)
        atemp = re.split(':', etemp[1])
        year  = atemp[0]
        month = atemp[1]
        date  = atemp[2]
        hour  = atemp[3]
        mins  = atemp[4]

#
#--- convert to dom/sec1998
#
        ydate = tcnv.findYearDate(int(year), int(month), int(date))              #--- a function from convertTimeFormat
        dom   = tcnv.findDOM(int(year), int(ydate), int(hour), int(mins), 0)     #--- a function from convertTimeFormat
        line  = year + ':' + str(ydate) + ':' + hour + ':' + mins + ':00'
        csec  = tcnv.axTimeMTA(line)                                             #--- a function from convertTimeFormat

#
#--- end date
#

        atemp  = re.split(':', etemp[2])
        eyear  = atemp[0]
        emonth = atemp[1]
        edate  = atemp[2]
        ehour  = atemp[3]
        emins  = atemp[4]

        ydate = tcnv.findYearDate(int(eyear), int(emonth), int(edate))
        dom2  = tcnv.findDOM(int(eyear), int(ydate), int(ehour), int(emins), 0)
        line  = eyear + ':' + str(ydate) + ':' + ehour + ':' + emins + ':00'
        csec2 = tcnv.axTimeMTA(line)
    
#
#--- date stamp for the list
#
        list_date = str(year) + str(month) + str(date)

#
#--- read radiation zone information from "rad_zone_list" and add up the time overlap with 
#--- radiatio zones with the interruption time period
#

        line  = house_keeping + '/rad_zone_list'
        f     = open(line, 'r')
        rlist = [line.strip() for line in f.readlines()]
        f.close()

        sum = 0
        for record in rlist:
            atemp = re.split('\s+', record)
            if list_date == atemp[0]:
                btemp = re.split(':', atemp[1])

                for period in btemp:

                    t1 = re.split('\(', period)
                    t2 = re.split('\)', t1[1])
                    t3 = re.split('\,', t2[0])
                    pstart = float(t3[0])
                    pend   = float(t3[1])

                    if pstart >= dom and  pstart < dom2:
                        if pend <= dom2:
                            diff = pend - pstart
                            sum += diff
                        else:
                            diff = dom2 - pstart
                            sum += diff
                    elif pstart < dom2 and pend > dom:
                        if pend <= dom2:
                            diff = pend - dom
                            sum += diff
                        else:
                            diff = dom2 - dom
                            sum += diff

                break
                
        sum *= 86400                            #--- change unit from day to sec

        sciLost = (csec2 - csec - sum) / 1000   #--- total science time lost excluding radiation zone passes

        line = etemp[0] + '\t' + etemp[1] + '\t' + etemp[2] + '\t' + "%.1f" %  sciLost  + '\t' + etemp[4]

        update.append(line)
#
#--- update the file 
#

    os.system('mv file file~')
    f = open(file, 'w')
    for ent in update:
        f.write(ent)
        f.write('\n')

    f.close()


         
#-----------------------------------------------------------------------------------------
#---removeNoneData: remove data which is missing and replaced as a very small value     --
#-----------------------------------------------------------------------------------------

def removeNoneData(x, y, xnew, ynew, lower, upper=1e99):

    'remove data which is missing and replaced as a very small value.'


    for i in range(0, len(y)):
       if y[i] > lower and y[i] < upper:
          xnew.append(x[i])
          ynew.append(y[i])


