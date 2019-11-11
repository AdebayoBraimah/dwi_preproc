#!/usr/bin/env python3
# 
# -*- coding: utf-8 -*-
# title				: calc_readOut_time.py
# description		: calculates (effective) echo spacing and readout times for distortion correction
# author			: Adebayo Braimah
# e-mail			: adebayo.braimah@cchmc.org
# date				: 24 July 2019 10:49 AM
# version			: 0.1.0
# usage				: python3 calc_readOut_time.py
# notes				: Requires a more arguments due to class structure of the script
# python_version	: 3.7.3
#==============================================================================

# Import Packages/Modules
import os
import sys
import argparse

# Define read_time class

class read_time:
    '''
    Calculates (Effective) Echo Spacing (ms) and Readout Times (ms)
    for 4D EPIs and DWIs. 
    This is done in one of two ways:
        - Regular: This uses the TR, the number of phase encoding steps,
            the echo train length, and the acceleration factor (if used,
            set to 1 as default).
        - Philips: This uses the water fat shift (per pixel), the echo
            train length (referred to as the EPI factor in Philips
            software manuals), and the acceleration factor (set to 1 
            as default).
        NOTE: These methods give fairly different results/values.
            Care should be used when utilizing either method and 
            should be implemented for the correct vendor.
    '''
    
    # Initializer / Instance Attribute(s)
    def __init__(self,etl):
        self.etl = etl
 
    # def read_time_regular(tr,z_slices, etl, acceleration = 1):
    def read_time_regular(z_slices, etl, acceleration = 1):
        '''
        Calculates the echo spacing (ms) and readout time (ms)
        for use in FSL's topup and eddy.
        Required Arguments:
            - z_slices (int): Number of phase encoding stepts - which corresponds to 
                the number of slices in the z-direction.
            - etl (int): Echo-train length (EPI factor on Philips scanners).
            - acceleration (int): Acceleration factor used 
                (usually found from the protocol exam card for the study) [default: 1].
        Returns:
            - es (int): Echo Spacing (ms)
            - t_read(int): Readout time (ms)
        '''
        # - tr (float): TR (repetition time, sec.) [deprecated]
        
        # Calculate Echo Spacing
        es = ((etl/z_slices)/acceleration) # Regular Calc Method
        # old code
        # es = 1000*(tr/(z_slices*etl)/acceleration)

        # Calculate Readout Time
        t_read = 0.001*es*etl

        return(es, t_read)

    def read_time_philips(wfs, etl, acceleration = 1):
        '''
        Calculates the echo spacing (ms) and readout time (ms)
        for use in FSL's topup and eddy.
        Required Arguments:
            - wfs (float): Water Fat Shift (per pixel)
            - etl (int): Echo-train length (EPI factor on Philips scanners).
            - acceleration (float): Acceleration (SENSE) factor used 
                (usually found from the protocol exam card for the study) [default: 1].
        Returns:
            - es (int): Echo Spacing (ms)
            - t_read(int): Readout time (ms)
        '''

        # Calculate Echo Spacing
        es = (((1000*wfs)/(434.215*(etl+1)))/acceleration) # Philips Calc Method

        # Calculate Readout Time
        t_read = 0.001*es*etl

        return(es, t_read)

if __name__ == "__main__":

    # Argument Parser
    parser = argparse.ArgumentParser(description='Calculates (effective) echo spacing (ms) and readout times (ms) for Philips or any other MR Scanner\n NOTE: The methods used differ slightly. Appropriate care should be used when\n utilizing either method and should be implemented for the correct vendor.')

    # Parse Arguments
    # Required Argument(s)
    reqoptions = parser.add_argument_group('Required arguments')
    reqoptions.add_argument('-ETL','--ETL',type=int,dest="etl",metavar="Echo-train Length",required=True,help="Echo-train length (EPI factor on Philips scanners)")
    reqoptions.add_argument('-m','-method','--method',type=str,dest="calc",metavar="<method>",required=True,help="Calculation method used to calculate the Echo Spacing and Readout Times. Acceptable arguments: 'Philips' or 'Regular'.")

    # Philips MR Scanners
    philoptions = parser.add_argument_group('Philips MR Scanners arguments')
    # philoptions.add_argument('-P','-Philips','--Philips',dest="calc",action='store_true',required=False,help="Calculation method used to calculate the Echo Spacing and Readout Times for Philips MR Scanners")
    philoptions.add_argument('-WFS','--WFS',type=float,dest="wfs",metavar="water-fat-shift",required=False,help="water-fat-shift (Hz/pixel)")

    # (Siemens/GE and other) Non-Philips MR Scanners
    regoptions = parser.add_argument_group('Non-Philips MR Scanner arguments')
    # regoptions.add_argument('-R','-Regular','--Regular',dest="calc",action='store_true',required=False,help="Calculation method used to calculate the Echo Spacing and Readout Times for Siemens/GE and other non-Philips MR Scanners")
    regoptions.add_argument("-PE","--PE",type=int,dest="z_slices",metavar="<number of z-direction slices>",required=False,help="Number of Phase Encoding (PE) steps.")

    # Optional Arguments
    optoptions = parser.add_argument_group('Optional arguments')
    optoptions.add_argument("-acc","-acceleration","--acceleration",type=float,dest="acceleration",metavar="<acceleration factor>",required=False,default=1,help="Acceleration factor used (SENSE on Philips). [default: 1]")

    args = parser.parse_args()

    # Print help message in the case
    # of no arguments
    try:
        args = parser.parse_args()
    except SystemExit as err: 
        if err.code == 2: 
            parser.print_help()

    if args.calc == 'Philips':
        # print("philips")
        info = read_time.read_time_philips(args.wfs, args.etl, args.acceleration)
        print("%.4f" % info[0])
        print("%.4f" % info[1])
        # print("%.4f\t%.4f" % read_time.read_time_philips(args.wfs, args.etl, args.acceleration))
    elif args.calc == 'Regular':
        # print("Siemens or GE")
        info = read_time.read_time_regular(args.z_slices, args.etl, args.acceleration)
        print("%.4f" % info[0])
        print("%.4f" % info[1])
        # print("%.4f\t%.4f" % read_time.read_time_regular(args.z_slices, args.etl, args.acceleration))
    else:
        print("Option not recognized.\n\n Please use the \'-P,-Philips,--Philips\' or \'-R,-Regular,--Regular\' options as specified.") 

    # print("%.4f" % read_time(args.tr,args.z_slices,args.etl))
