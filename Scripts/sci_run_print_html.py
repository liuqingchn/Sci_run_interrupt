#!/usr/local/bin/python2.6

#################################################################################
#                                                                               #
#       sci_run_print_html.py: print out html pagess                            #
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

#---------------------------------------------------------------------------------------------------------------------
#---  printEachHtmlControl: html page printing control                                                             ---
#---------------------------------------------------------------------------------------------------------------------

def printEachHtmlControl(file = 'NA'):

    'html page printing control function. '

    if file != 'NA':
        f = open(file, 'r')
        data = [line.strip() for line in f.readlines()]
        f.close()
#
#--- first pint indivisula html pages
#
        for ent in data:
                atemp = re.split('\s+', ent)
        
                event = atemp[0]
                start = atemp[1]
                stop  = atemp[2]
                gap   = atemp[3]
                type  = atemp[4]
        
                printEachHtml(event, start, stop, gap, type)
    else:
#
#--- print top pages, auto, manual, hardness, and time ordered
#
        printSubHtml()

#
#---- change permission/owner group of pages
#
    cmd = 'chmod 775 ' + web_dir + '/*'
    os.system(cmd)
    cmd = 'chgrp mtagroup  ' + web_dir + '/*'
    os.system(cmd)

    cmd = 'chmod 775 ' + html_dir + '/*'
    os.system(cmd)
    cmd = 'chgrp mtagroup  ' + html_dir + '/*'
    os.system(cmd)

#---------------------------------------------------------------------------------------------------------------------
#--- printEachHtml: print out indivisual html page                                                                 ---
#---------------------------------------------------------------------------------------------------------------------

def printEachHtml(event, start, stop, gap, stopType):

    'create indivisual event html page. input event name, interruption start/stop time, gap, and type (auto/manual): example: 20031202        2003:12:02:17:31        2003:12:04:14:27        139.8   auto'

#
#--- modify date formats
#   
    begin = start + ':00'
    (year1, month1, date1, hours1, minutes1, seconds1, ydate1, dom1, sectime1) = tcnv.dateFormatConAll(begin)
    end   = stop  + ':00'
    (year2, month2, date2, hours2, minutes2, seconds2, ydate2, dom2, sectime2) = tcnv.dateFormatConAll(end)

#
#--- find plotting range
#

    (pYearStart, periodStart, pYearStop, periodStop, plotYearStart, plotStart, plotYearStop, plotStop, pannelNum) \
                 = itrf.findCollectingPeriod(year1, ydate1, year2, ydate2)

#
#--- check whether we need multiple pannels
#
    pannelNum  = int((plotStop - plotStart) / 5)

#
#--- choose a template
#
    atemp = re.split(':', start)
    year  = int(atemp[0])
    if year < 2011:
        file = house_keeping + 'sub_html_template'
    else:
        file = house_keeping + 'sub_html_template_2011'

#
#--- read the template and start substituting 
#

    data = open(file).read()

    data = re.sub('#header_title#',  event, data)
    data = re.sub('#main_title#',    event,  data)
    data = re.sub('#sci_run_stop#',  start,  data)
    data = re.sub('#sci_run_start#', stop,   data)
    data = re.sub('#interruption#',  gap,    data)
    data = re.sub('#trigger#',       stopType, data)

    noteN = event + '.txt'
    data = re.sub('#note_name#',     noteN,  data)

#
#--- ACA (NOAA) radiation data
#

    aceData = event + '_dat.txt'
    data = re.sub('#ace_data#',     aceData, data)

    file = stat_dir + event + '_ace_stat'
    stat = open(file).read()
    data = re.sub('#ace_table#',    stat,    data)

    line =  event + '.png"'
    for i in range(2, pannelNum+1):
        padd = ' width=100%>\n<br />\n<img src = "../Main_plot/' + event + '_pt' + str(i) + '.png" '
	line = line + padd

    data = re.sub('#ace_plot#', line , data)

#
#---EPHIN data
#

    ephData = event + '_eph.txt'
    data = re.sub('#eph_data#', ephData, data)

    file = stat_dir + event + '_ephin_stat'
    stat = open(file).read()
    data = re.sub('#eph_table#',    stat,    data)

    line =  event + '_eph.png"'
    for i in range(2, pannelNum+1):
        padd = ' width=100%>\n<br />\n<img src = "../Ephin_plot/' + event + '_eph_pt' + str(i) + '.png" '
	line = line + padd

    data = re.sub('#eph_plot#', line , data)

#
#---GOES data
#

    goesData = event + '_goes.txt'
    data = re.sub('#goes_data#', goesData, data)

    file = stat_dir + event + '_goes_stat'
    stat = open(file).read()
    data = re.sub('#goes_table#',    stat,    data)

    line =  event + '_goes.png"'
    for i in range(2, pannelNum+1):
        padd = ' width=100%> \n<br />\n<img src = "../GOES_plot/' + event + '_goes_pt' + str(i) + '.png" '
	line = line + padd

    data = re.sub('#goes_plot#', line , data)

    if year1 >= 2011:
        data = re.sub('GOES-11', 'GOES-15', data)


    file = web_dir + 'Html_dir/' + event + '.html'
    f    = open(file, 'w')
    f.write(data)
    f.close()


#----------------------------------------------------------------------------------------------------
#--- printEachPannel: create each event pannel for the top html pages                             ---
#----------------------------------------------------------------------------------------------------

def printEachPannel(event, start, stop, gap, stopType, out):

    'create each event pannel for the top html pages. input: event, start, stop, gap, stopType, out, where out is output hander'

    out.write('<li style="text-align:left;font-weight:bold;padding-bottom:20px">\n')
    out.write('<table border=0 cellpadding=3 cellspacing=3><tr>\n')
    line = '<td>Science Run Stop: </td><td> ' + start + '</td><td>Start:  </td><td>' + stop + '</td>'
    out.write(line)
    line = '<td>Interruption: </td><td> %4.1f ks</td><td>%s</td>\n' %(float(gap), stopType)
    out.write(line)
    out.write('</tr></table>\n')
    address = html_dir.replace('/data/mta_www/', '/mta_days/')
    line = '<a href="' + address + event + '.html"><img src="./Intro_plot/' + event + '_intro.png" width=100% height=20%></a>\n'
    out.write(line)

    address = data_dir.replace('/data/mta_www/', '/mta_days/')
    line = '<a href="' + address + event + '_dat.txt">ACE RTSW EPAM Data</a>\n'
    out.write(line)

    line = '<a href="' + address + event + '_eph.txt">Ephin Data</a>\n'
    out.write(line)

    line = '<a href="' + address + event + '_goes.txt">GOES Data</a>\n'
    out.write(line)

    address = note_dir.replace('/data/mta_www/', '/mta_days/')
    line = '<a href="' + address + event + '.txt">Note</a>\n'
    out.write(line)

    out.write('<br />\n')
    out.write('<spacer type=vertical size=10>\n')
    out.write('<li>\n')


#----------------------------------------------------------------------------------------------------
#--- printSubHtml: create auto/manual/hardness/time ordered html pages                            ---
#----------------------------------------------------------------------------------------------------

def printSubHtml():

    'create auto/manual/hardness/time ordered html page. data are read from house_keeping and stat_dir '

#
#--- read the list of the interruptions
#

    file        = house_keeping+ 'all_data'
    fin         = open(file, 'r')
    timeOrdered = [line.strip() for line in fin.readlines()]
    fin.close()

    auto_list      = []
    manual_list    = []
    hardness_list  = []
#
#--- create list of auto, manual, and hardness ordered list. time ordered list is the same as the original one
#
    createOrderList(timeOrdered, auto_list, manual_list, hardness_list)

#
#--- print out each html page
#
    for type in ('auto_shut', 'manual_shut', 'hardness_order', 'time_order'):

        fout = web_dir + type +'.html'
        out  = open(fout, 'w')
#
#--- read the template for the top part of the html page
#
        line = house_keeping + 'main_html_page_header_template'
        data = open(line).read()
#
#---- find today's date so that we can put "updated time in the web page
#
        [dyear, dmon, dday, dhours, dmin, dsec, dweekday, dyday, dst] = tcnv.currentTime('UTC')
        today = str(dyear) + '-' + str(dmon) + '-' + str(dday)
        data  = re.sub("#DATE#", today, data)
        out.write(data)

        out.write('<table border=0 cellpadding=3 cellspacing=3>\n')
        out.write('<tr><td>\n')


        if type == 'auto_shut':
            autoHtml(out)
            inList = auto_list
        elif type == 'manual_shut':
            manualHtml(out)
            inList = manual_list
        elif type == 'hardness_order':
            hardnessHtml(out)
            inList = hardness_list
        else:
            timeOrderHtml(out)
            inList = timeOrdered

        out.write('</table>\n')

#
#--- now create each event pannel
#
        for ent in inList:
            atemp = re.split('\s+|\t+', ent)
            event = atemp[0]
            start = atemp[1]
            stop  = atemp[2]
            gap   = atemp[3]
            stopType = atemp[4]

            printEachPannel(event, start, stop, gap, stopType, out)

        out.write('</body>')
        out.write('</html>')

        out.close()

#---------------------------------------------------------------------------------------------------
#--- autoHtml: print a header line for auto shutdown case                                        ---
#---------------------------------------------------------------------------------------------------

def autoHtml(out):

    out.write('<a href="time_order.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Time Ordered List</a>\n')
    out.write('</td><td>\n')
    out.write('<em class="lime" style="font-weight:bold;font-size:120%">\n')
#    out.write('<a href="auto_shut.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Auto Shutdown List</em>\n')
    out.write('</td><td>\n')
    out.write('<a href="manual_shut.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Manually Shutdown List</a>\n')
    out.write('</td><td>\n')
    out.write('<a href="hardness_order.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Hardness Ordered List</a.\n')
    out.write('</td><td>\n')

#---------------------------------------------------------------------------------------------------
#--- manualHtml: print a header line for manual shotdown case                                    ---
#---------------------------------------------------------------------------------------------------

def manualHtml(out):

    out.write('<a href="time_order.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Time Ordered List</a>\n')
    out.write('</td><td>\n')
    out.write('<a href="auto_shut.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Auto Shutdown List</em>\n')
    out.write('</td><td>\n')
    out.write('<em class="lime" style="font-weight:bold;font-size:120%">\n')
#    out.write('<a href="manual_shut.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Manually Shutdown List</a>\n')
    out.write('</td><td>\n')
    out.write('<a href="hardness_order.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Hardness Ordered List</a.\n')
    out.write('</td><td>\n')

#---------------------------------------------------------------------------------------------------
#--- hardnessHtml: print a header line for hardness ordered case                                 ---
#---------------------------------------------------------------------------------------------------

def hardnessHtml(out):

    out.write('<a href="time_order.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Time Ordered List</a>\n')
    out.write('</td><td>\n')
    out.write('<a href="auto_shut.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Auto Shutdown List</em>\n')
    out.write('</td><td>\n')
    out.write('<a href="manual_shut.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Manually Shutdown List</a>\n')
    out.write('</td><td>\n')
    out.write('<em class="lime" style="font-weight:bold;font-size:120%">\n')
#    out.write('<a href="hardness_order.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Hardness Ordered List</a.\n')
    out.write('</td><td>\n')

#---------------------------------------------------------------------------------------------------
#--- timeOrderHtml: print a header line for time ordered case                                    ---
#---------------------------------------------------------------------------------------------------

def timeOrderHtml(out):

    out.write('<em class="lime" style="font-weight:bold;font-size:120%">\n')
#    out.write('<a href="time_order.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Time Ordered List</a>\n')
    out.write('</td><td>\n')
    out.write('<a href="auto_shut.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Auto Shutdown List</em>\n')
    out.write('</td><td>\n')
    out.write('<a href="manual_shut.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Manually Shutdown List</a>\n')
    out.write('</td><td>\n')
    out.write('<a href="hardness_order.html" style="font-weight:bold;font-size:120%">\n')
    out.write('Hardness Ordered List</a.\n')
    out.write('</td><td>\n')



#---------------------------------------------------------------------------------------------------
#--- createOrderList: create lists of auto/manual shut down and harness ordered list             ---
#---------------------------------------------------------------------------------------------------

def createOrderList(data, auto_list, manual_list, hardness_list):

    'create lists of auto, manual, and hardness ordered events. input is data with each line contains, e.g.: 20031202        2003:12:02:17:31        2003:12:04:14:27        139.8   auto'

    hardList = []

    for ent in data:
#
#--- extract auto and manual entries
#
        m = re.search('auto', ent)
        n = re.search('manual', ent)
        if m is not None:
            auto_list.append(ent)
        elif n is not None:
            manual_list.append(ent)
#
#--- hardness list bit more effort. find p47/p1060 value from stat file
#

        atemp    = re.split('\s+|\t+', ent)
        statData = stat_dir + atemp[0] + '_ace_stat'
        sin      = open(statData, 'r')
        input    = [line.strip() for line in sin.readlines()]

        for line in input:
            m = re.search('p47/p1060', line)
            if m is not None:
                btemp = re.split('\s+|\t+', line)
                hardList.append(btemp[2])

#
#--- zip the hardness list and the original list so that we can sort them by hardness
#
    tempList = zip(hardList, data)
    tempList.sort()

#
#--- extract original data sorted by the hardness
#
    for ent in tempList:
        hardness_list.append(ent[1])


#---------------------------------------------------------------------------------------------------------------------
#--- start script                                                                                                  ---
#---------------------------------------------------------------------------------------------------------------------


if __name__ == '__main__':

#
#---- plotting the data and create html pages
#

    file = raw_input('Please put the intrrupt timing list (if "NA", print all top level html pages: ')

    printEachHtmlControl(file)

