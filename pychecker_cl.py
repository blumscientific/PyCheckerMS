#!/usr/bin/env python

"""
Analysis of GC-MS runs with OPCW Testmixture and blanks
with internal standard for conformity with requirements
according to WI/GCMS9
"""

# pychecker_cl.py 0.02
#
# Author: Marc-Michael Blum (marc.blum@opcw.org)
#         OPCW Laboratory
# Released under the XXX license


#--------------- module imports ----------------------------------------------

import sys
import os
import re
from colorama import init, Fore, Back, Style

endl = os.linesep

#---------- compounds and standards ------------------------------------------

compounds = ['Octane',
             'Trimethyl phosphate',
             'Decane',
             '2,6-Dimethylphenol',
             'Dodecane',
             '5-Chloro-2-methylaniline',
             'Tetradecane',
             'Hexadecane',
             'Tributyl phosphate',
             'Dibenzothiophene',
             'Octadecane',
             'Malathion',
             'Eicosane',
             'Methyl stearate',
             'Docosane'
             'Tetracosane']

standards = ['Hexachlorobenzene']

#---------- boundary values for checker---------------------------------------

boundaries = {'dri'      : 10,
              'drt'      : 0.5,
              'net'      : 85,
              'width'    : 4.0,
              'mintail'  : 0.5,
              'maxtail'  : 5.0,
              'sn'       : 300,
              'isos_min' : 5.1,
              '?sos_max' : 5.7,
              'isocl_min': 30.0,
              '?socl_max': 34.0}

#--------------- function declarations ---------------------------------------

def assign_args(key, default):
    """Checks if argument was passed on command line.
       If not then a default value is assigned."""
    if not key in args:
        args[key] = default
    return

#--------------- init colorama -----------------------------------------------

init()

#--------------- startup -----------------------------------------------------

failure = False
tailfail = False

# if called without any arguments display help text and exit
if len(sys.argv)==1:
    print "Here goes the help text with arguments"
    sys.exit()
else:
    print ""
    print "PyChecker Command Line Version 0.02"

# read arguments from command line, find -name value pairs and put in dictionary args
args = {}
if len(sys.argv) > 2:
    while sys.argv:
        if sys.argv[0][0] == '-':
            args[sys.argv[0][1:]] = sys.argv[1]
            sys.argv = sys.argv[2:]
        else:
            sys.argv = sys.argv[1:]
    #convert some string to numericals
    if 'sn' in args:
        try:
            args['sn'] = int(args['sn'])
        except ValueError:
            print "Error: Argument -sn is not an integer."
            sys.exit()

# Check if config file exists and if yes parse and add to dictionary args
# If no value in config file and not on command line use default for optional arguments

#mandatory arguments
assign_args('filename', False)

# optional arguments, setting default values if required
assign_args('sn', boundaries['sn'])
assign_args('v', 'yes')
assign_args('out', 'stdout')

# Set -v to 'yes' if it is not 'no'
if args['v'] != 'no':
    args['v'] = 'yes'

# Check if mandatory arguments present. If not exit.
for key in args:
    if args[key] == False:
        print "Error: Mandatory argument (filename) missing."
        sys.exit()

# Print settings to stdout
print ""
print "Using the following arguments for PyChecker:"
print ""
print "-filename   >>> ", args['filename']
print "-sn         >>> ", args['sn']
print "-out        >>> ", args['out']
print "-verbose    >>> ", args['v']
print ""

#--------------- load and initial analysis of data ---------------------------
# open filename
# First lets check if filename is present
if not os.path.isfile(args['filename']):
    print "Error: Filename %s does not exists" % (args['filename'])
    sys.exit()

# Check if file content appears to be a proper FIN file
# At the same time check if this is calibration or target run
print "Inputfile exists. Lets see if we can work with it..."
usable = False
runtype = 'target'
inputfile = open(args['filename'])
for line in inputfile:
    line = line.strip()
    parts = line.split(' ')
    if len(parts) > 2:
        if parts[1] == 'Identified' and parts[2] == 'Compounds':
            print "Looks good..."
            usable = True
    if len(parts) > 4:
        if parts[0] == 'Identified' and parts[2] == 'of' and parts[5] == 'Standards':
            if int(parts[3]) == 16 or int(parts[3]) == 17:
                runtype = 'calibration'
inputfile.close()

if usable == False:
    print "Error: Inputfile seems not to be a proper .FIN file"
    sys.exit()

print ""
print "."
print "."
print "."
print "."
print ""
print "Processed file  " + args['filename']
if runtype == 'calibration':
    print "Data type - calibration and performance check"
else:
    print "Data type - target run"
print ""

# For calibration runs determine median S/N ratios for background column bleed
# also check solvent tailing

tailtime100 = 'before run'
tailtime50 = 'before run'

if runtype == 'calibration':
    inputfile = open(args['filename'])
    for line in inputfile:
        line = line.strip()
        parts = line.split(' ')
        if len(parts) > 0:
            if parts[0] == 'Background':
                helpstring = inputfile.next()
                result = re.findall(r'[0-9]+', helpstring)
                backgr_sn = map(float, result)
                sn_ratio = float(backgr_sn[1]/backgr_sn[0])
                if backgr_sn[0] == 0:
                    print (Fore.GREEN + Style.BRIGHT + "Median low RT S/N of background is zero")
                elif sn_ratio <= 10:
                    print (Fore.GREEN + Style.BRIGHT + "Ratio of median S/N at high RT to median S/N at low RT for background = %.1f" % sn_ratio)
                else:
                    print (Fore.RED + Style.BRIGHT + "Ratio of median S/N at high RT to median S/N at low RT for background = %.1f" % sn_ratio)
                    failure = True
        if len(parts) > 1:
            if parts[0] == 'Column' and parts[1] == 'Bleed':
                helpstring = inputfile.next()
                result = re.findall(r'[0-9]+', helpstring)
                clbleed_sn = map(float, result)
                sn_ratio = float(clbleed_sn[1]/clbleed_sn[0])
                if clbleed_sn[0] == 0:
                    print (Fore.GREEN + Style.BRIGHT + "Median S/N at low RT equals zero for column bleed (m/z=207)")
                elif sn_ratio <= 10:
                    print (Fore.GREEN + Style.BRIGHT + "Ratio of median S/N at high RT to median S/N at low RT for column bleed (m/z=207) = %.1f" % sn_ratio)
                else:
                    print (Fore.RED + Style.BRIGHT + "Ratio of median S/N at high RT to median S/N at low RT for column bleed (m/z=207) = %.1f" % sn_ratio)
                    failure = True
        if len(parts) > 1:
            if parts[0] == 'Solvent' and parts[1] == 'Tailing':
                helpstring = inputfile.next()
                entries = helpstring.split(' ')
                sn_entry = entries[2].split('=')
                while sn_entry[0] == 'S/N' and int(sn_entry[1]) > 50:
                    if int(sn_entry[1]) == 100:
                        if entries[4] == 'run':
                            tailtime100 = 'before run'
                        else:
                            if float(entries[3]) > 3.5:
                                tailfail = True
                                tailtime100 = str(entries[3]) + " min"
                            else:
                                tailtime100 = str(entries[3]) + " min"
                    elif int(sn_entry[1]) == 50:
                        if entries[4] == 'run':
                            tailtime50 = 'before run'
                        else:
                            if float(entries[3]) > 6.0:
                                tailfail = True
                                tailtime50 = str(entries[3]) + " min"
                            else:
                                tailtime50 = str(entries[3]) + " min"
                    helpstring = inputfile.next()
                    entries = helpstring.split(' ')
                    sn_entry = entries[2].split('=')
    inputfile.close()

# We checked for solvent tailing earlier but only write the results after background and column bleed

    print ""
    if tailfail == False:
      print (Fore.GREEN + Style.BRIGHT + "Solvent Tailing (m/z=84): S/N=100 " + tailtime100 + ", S/N=50 " + tailtime50)
    else:
        print (Fore.RED + Style.BRIGHT + "Solvent Tailing (m/z=84): S/N=100 " + tailtime100 + ", S/N=50 " + tailtime50)
        failure = True
    print (Fore.RESET + Back.RESET + Style.RESET_ALL)

# And now its time to look for the identified chemicals
# then we extract data from the FIN file

chemicals_data = []
isotop_s = False
isotop_cl = False
tmp = False
tbp = False
mst = False
val_141 = 0
val_143 = 0
val_184 = 0
val_186 = 0
rtdiff_tmp = 0.0
rtdiff_tbt = 0.0
rtdiff_mst = 0.0

inputfile = open(args['filename'])
for line in inputfile:
    line = line.strip()
    if line == '************************':
        results=[]
        helpstring = inputfile.next()
        entries = helpstring.split('|')
        for x, item in enumerate(entries):
            result = re.findall(r'[0-9\.0-9]+', entries[x])
            if result:
                results.append(result[0])

        helpstring = inputfile.next()
        helpstrings = helpstring.split('|NA')
        result = helpstrings[1].strip()
        if result == 'Dibenzothiophene':
            isotop_s = True
        elif result == '5-Chloro-2-methylaniline':
            isotop_cl = True
        elif result == 'Trimethyl phosphate':
            tmp = True
        elif result == 'Tributyl phosphate':
            tbp = True
        elif result == 'Methyl stearate':
            mst = True
        results.append(result)

        helpstring = inputfile.next()

        if tmp == True:
            tmpERT = helpstring.split('|ET')[1]
            tmpERT = float(tmpERT.split('|')[0])
            print tmpERT
            tmp = False

        entries = helpstring.split('|')
        for x, item in enumerate(entries):
            result = re.findall(r'[0-9\.0-9]+', entries[x])
            if result:
                results.append(result[0])

        chemicals_data.append(results)

# Check if chemical is 5-Chloro-2-methylaniline or Dibenzothiophene
# if yes then extract data to calculate isotopic ratio

        if isotop_cl == True:
            endofspectra = False
            numpeaks = 0
            while numpeaks < 2:
                helpstring = inputfile.next()
                result = re.findall(r'NUM PEAKS', helpstring)
                if result:
                    numpeaks = numpeaks + 1
            while endofspectra == False:
                helpstring = inputfile.next()
                if helpstring.strip() == '':
                    endofspectra = True
                result = re.findall(r'[0-9]+', helpstring)
                result = [int(value) for value in result]
                for i, value in enumerate(result):
                    if value == 141:
                        val_141 = result[i+1]
                    elif value == 143:
                        val_143 = result[i+1]
            isotop_cl = False

        if isotop_s == True:
            endofspectra = False
            numpeaks = 0
            while numpeaks < 2:
                helpstring = inputfile.next()
                result = re.findall(r'NUM PEAKS', helpstring)
                if result:
                    numpeaks = numpeaks + 1
            while endofspectra == False:
                helpstring = inputfile.next()
                if helpstring.strip() == '':
                    endofspectra = True
                result = re.findall(r'[0-9]+', helpstring)
                result = [int(value) for value in result]
                for i, value in enumerate(result):
                    if value == 184:
                        val_184 = result[i+1]
                    elif value == 186:
                        val_186 = result[i+1]
            isotop_s = False

# Check if chemical is TMT, TBT or MST
# if yes then extract retention time data and calculate RT diff



inputfile.close()

# claculate isotopic ratios of present
if (val_141 != 0) and (val_143 != 0):
    isoratio_cl = round(float(val_143) / float(val_141) * 100, 2)
if (val_184 != 0) and (val_186 != 0):
    isoratio_s = round(float(val_186) / float(val_184) * 100, 2)

# calculate number of identified chemicals
identifiedchemicals = len(chemicals_data)

# prepare output
print '{0:25}|{1:8}|{2:8}|{3:8}|{4:8}|{5:8}'.format('Name','RI diff','Net MF','Width','Tailing','S/N')
print '----------------------------------------------------------------------'
print '{0:25}|{0:8}|{0:8}|{0:8}|{0:8}|{0:8}'.format('')

#iterate through chemicals data, check against boundaries and print
for chemset in chemicals_data:
    print '{0:25}|{1:8}|{2:8}|{3:8}|{4:8}|{5:8}'.format(chemset[22],chemset[20],chemset[24],chemset[13],chemset[14],chemset[12])

print ""
print "Number of calibration/test compounds identified = %d" % identifiedchemicals
print ""
print "Isotopic Ratios: "
print ""
print "5-Chloro-2-methylaniline (m/z143 / m/z141) = %2.2f %%" % isoratio_cl
print "Bibenzothiophene (m/z186 / m/z184) = %2.2f %%" % isoratio_s

print ""
print "RT diff :"
print ""
print "{0:20}= {1:6}".format("Trimethylphosphate", rtdiff_tmp)
print "{0:20}= {1:6}".format("Tributylphosphate", rtdiff_tbt)
print "{0:20}= {1:6}".format("Methyl stearate", rtdiff_mst)
# print (Fore.GREEN + Style.BRIGHT + "Error: some message")

#
