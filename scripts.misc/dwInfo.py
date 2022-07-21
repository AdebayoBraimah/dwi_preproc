#!/usr/bin/env python3
# 
# -*- coding: utf-8 -*-
'''
Handy tool for calculating/extracting DW & fMR image related information and parameters.
All commands used have varying number and types of arguments.
'''
# 
# title           : dwInfo.py
# description     : [description]
# author          : Adebayo B. Braimah
# e-mail          : adebayo.braimah@cchmc.org
# date            : 2019 09 09 12:13:17
# version         : 0.0.2
# usage           : dwInfo.py [-h,--help]
# notes           : [notes]
# python_version  : 3.7.3
# ==============================================================================

# CHANGE_LOG
#
# v0.0.2
#
# Added options to parse BIDS filename and wrtie to a text file.
#
# v0.0.1
#
# Added options to perform a series of handy calculations and to
# write those outputs to file.

# Import Modules & Packages
import pandas as pd
import json
import subprocess
import re
import csv
import os
import argparse


# Define Functions

# Get B0 Information
def readBval(file):
    '''Reads b-value file.'''
    val = []
    with open(file) as f:
        for line in f:
            for num in line.split():
                n = int(num)
                val.append(n)
    return (val)


def getNumB0s(bvalFile):
    '''
    Counts the number of B0s at the beginning of
    a DWI using its bvalue file.
    '''
    bval = readBval(bvalFile)
    df = pd.DataFrame.from_dict(bval)
    df = df.rename(columns={0: "bvals"})
    df_0 = df.loc[df['bvals'] == 0]
    return (len(df_0))


# Index (.idx) File Information
def getNumFrames(niiFile):
    '''Gets the number of frames for a DW or fMR image series.'''
    numFrames = subprocess.check_output(["fslval", niiFile, "dim4"])
    numFrames = str(numFrames)
    numFrames = int(re.sub('[^0-9]', '', numFrames))  # Strip non-numeric information
    return (numFrames)


def writeIDX(niiFile, filename='slice_PE_dirs.idx'):
    '''
    Writes idx (index) file based on:
        - The number of frames in the DWI
        - Assuming the PE (Phase Encoding) direction is the same for each frame.
        '''
    numFrames = getNumFrames(niiFile)
    idx = []
    for n in range(0, numFrames, 1):
        m = 1
        idx.append(m)
    with open(filename, 'w') as f:
        writer = csv.writer(f)
        writer.writerows(zip(idx))


# acqp (ACQuired Parameters) File Information
def writeACQP(readOutTime=0.05, filename='dwi_params'):
    '''
    Writes the acqp (ACQuired Parameters) file for use with
    distortion correction FSL's Topup.
    NOTE: Assumes PE direction distortion is in the AP (-y) direction.
    '''
    d = {'PE_x': [0, 0], 'PE_y': [1, -1], 'PE_z': [0, 0]}
    df = pd.DataFrame(data=d)
    df['ReadOutTime'] = readOutTime
    # outFile = filename + ".acqp"
    outFile = filename
    df.to_csv(outFile, index=False, header=False, sep=' ')


# JSON File Information (from BIDS JSON sidecar)
def getParams(jsonFile, filename='params.txt'):
    '''
    Extracts DWI parameters from BIDS JSON side car
    in addition to non-standard fields which include:
     - WaterFatShift
     - EchoTrainLength
     - AccelaerationFactor
     - MultiBandFactor
     - SourceDataFormat
    '''
    with open(jsonFile, "r") as read_file:
        data = json.load(read_file)

    # Standard & Custom keys in the BIDS JSON sidecar
    keys = ['EchoTime', 'RepetitionTime', 'ReconMatrixPE', 'WaterFatShift', 'EchoTrainLength',
            'AccelerationFactor', 'MultiBandFactor', 'bvalue', 'SourceDataFormat']

    data2 = {x: data[x] for x in keys if x in data}

    with open(filename, 'w') as f:
        for key, value in data2.items():
            f.write('%s: %s\n' % (key, value))


# Parses BIDS filename
def parseBIDSfilename(dwiFile, output="BIDS_info.txt", verbose=False):
    '''
    Parses BIDS filename from a given nifti file (or
    a JSON sidecar), and writes a file that contains
    the content information of the file name.
    NOTE: All file extensions must be removed from the
    filename.
    '''

    # Read filename
    dwi = os.path.basename(dwiFile)

    # Splite filename by underscores ('_') consistent with BIDS
    dwiList = dwi.split(('_'))

    # Write List to file
    with open(output, "w+") as file:
        for element in range(0, len(dwiList) - 1, 1):
            names = dwiList[element].split(('-'))
            if verbose in [True]:
                print(names[0], ":", names[1])
            file.write(names[0] + ":\t" + names[1] + "\n")


# Define main function
if __name__ == "__main__":
    # Argument Parser
    parser = argparse.ArgumentParser(
        description='Handy tool for calculating/extracting DW & fMR image related information and parameters.')

    # Parse Arguments
    # Required Arguments
    reqoptions = parser.add_argument_group('Required Argument(s)')
    reqoptions.add_argument('--info',
                            type=str,
                            dest="info",
                            metavar="info_type",
                            required=True,
                            help="'Information' type to be computed/extracted. Valid arguments are: B0, idx, acqp, parse, BIDS")

    # B0 Info Arguments
    boptions = parser.add_argument_group('B0 Information Arguments')
    boptions.add_argument('-b', '--bvalue',
                          type=str,
                          dest="bval",
                          metavar="bvalue_file",
                          required=False,
                          help="b-value file that corresponds to the DW image of interest. The number of B0s is printed to the command line.")

    # idx (index) Info Arguments
    idxoptions = parser.add_argument_group('Index (.idx) File Information Arguments')
    idxoptions.add_argument('-d', '--dwi',
                            type=str,
                            dest="niiFile",
                            metavar="DWI.nii.gz",
                            required=False,
                            help="DWI nifti file")
    idxoptions.add_argument('-i', '--idx',
                            type=str,
                            dest="idx",
                            metavar="index.idx",
                            default='slice_PE_dirs.idx',
                            required=False,
                            help="Output file name prefix for the .idx file [Default: slice_PE_dirs(.idx)]")

    # acqp (ACQuired Parameters) Info Arguments
    acqpoptions = parser.add_argument_group('ACQuired Parameters (.acqp) File Information Arguments')
    acqpoptions.add_argument('-r', '--read',
                             type=float,
                             dest="readTime",
                             metavar="ReadOutTime",
                             default=0.05,
                             required=False,
                             help="EPI Readout time (ms) [Default: 0.05]")
    acqpoptions.add_argument('-a', '--acqp',
                             type=str,
                             dest="acqp",
                             metavar="acq_params.acqp",
                             default='acq_params',
                             required=False,
                             help="Output file name prefix for the .acqp file [Default: acq_params(.acqp)]")

    # Parse BIDS filename
    parseoptions = parser.add_argument_group('Parse BIDS filename')
    parseoptions.add_argument('-s', '--parse',
                              type=str,
                              dest="dwiFile",
                              metavar="<DWI_file>",
                              required=False,
                              help="Parses BIDS filename and writes the output to a file. NOTE: The filename should be stripped of its file extension.")
    parseoptions.add_argument('-o', '--output',
                              type=str,
                              dest="output",
                              metavar="BIDS_info.txt",
                              default='BIDS_info.txt',
                              required=False,
                              help="Output name for the parsed BIDS filename [Default: BIDS_info(.txt)]")
    parseoptions.add_argument("-v", "--verbose",
                              dest="verbose",
                              required=False,
                              action="store_true",
                              help="Prints parsed BIDS filename information to the command line.")

    # Extract (custom) BIDS Info Arguments
    bidsoptions = parser.add_argument_group('Extract (custom) BIDS JSON sidecar File Information Arguments')
    bidsoptions.add_argument('-B', '--BIDS',
                             type=str,
                             dest="jsonFile",
                             metavar="BIDS.json",
                             required=False,
                             help="(Custom) BIDS JSON sidecar that contains standard BIDS information, in addition to: Water Fat Shift, Echo Train Length, Accelaeration Factor, Multi-Band Factor")
    bidsoptions.add_argument('-p', '--param',
                             type=str,
                             dest="param",
                             metavar="params.txt",
                             default='BIDS_params.txt',
                             required=False,
                             help="Output name for parameter file [Default: BIDS_params(.txt)]")

    args = parser.parse_args()

    # Print help message in the case of no arguments
    try:
        args = parser.parse_args()
    except SystemExit as err:
        if err.code == 2:
            parser.print_help()

    # Compute/Extract DW and/or fMR image info
    if args.info == 'B0':
        numB0s = getNumB0s(args.bval)
        print(numB0s)
    elif args.info == 'idx':
        writeIDX(args.niiFile, args.idx)
    elif args.info == 'acqp':
        writeACQP(args.readTime, args.acqp)
    elif args.info == 'parse':
        parseBIDSfilename(args.dwiFile, args.output, args.verbose)
    elif args.info == 'BIDS':
        getParams(args.jsonFile, args.param)
    else:
        print("Option not recognized. Please use the \'--info\' option with: B0, idx, acqp, or BIDS.")
