#!/usr/bin/env python3
# 
# -*- coding: utf-8 -*-
# title				: mb_slice_order.py
# description		: Prints MB slice acquisition order
# author			: Adebayo Braimah
# e-mail			: adebayo.braimah@cchmc.org
# date				: 23 July 2019 12:14 PM
# version			: 0.0.1
# usage				: python3 mb_slice_order.py
# notes				: Requires number of Z-direction slices and MB factor; 
# 						written with help from Gregory Lee, PhD (Gregory.Lee@cchmc.org).
# python_version	: 3.7.3
#==============================================================================

import numpy as np 
import argparse
import sys 
import os

def mb_slice(slices, MB_factor, mode = 'interleaved', output = 'sliceOrder.txt', verbose = False):
    
    '''
    Prints out Multi-band slice order acquisition for the Philips MR Scanners at
    CCHMC.
    Required Arguments:
        - slices(int): The number of slices in the acquisition direction (e.g. the Z ( or sup-inf) direction at CCHMC)
        - MB_factor(int): Multi-band factor used for the acquisition (varies by protocol at CCHMC).
    Optional Arguments:
        - mode(str): Multi-band Acquisition mode ('interleaved',or 'default'). [default: 'interleaved']
        - output(str): Output file name and directory. [default: <current_working_directory>/sliceOrder.txt]
        - verbose: Prints out additional information to screen.
    Returns:
        - None
        - Prints out a text file with the MB slice order acquisition.
    -------------------------------------------------------------------
    Function written with help from Gregory Lee, PhD (Gregory.Lee@cchmc.org).
    '''
    
    if verbose in [True]:
        print('Number of Slices: ',slices)
        print('Multi-Band Factor: ',MB_factor)
        print('Philips Slice Acquisition Mode: ',mode)
    #------------------------------------------------  
    # Locations (in the slices) divided by Multi-Band Factor
    locs = slices//MB_factor
    
    # Check for Mode Used 
    if mode == 'interleaved':
        step = int(np.round(np.sqrt(locs)))
    elif mode == 'default':
        step = 2
    
    # Iterate through each MB acquisition to get slice ordering
    with open(output,"w+") as file:
        for s in range(step):
            for k in range(s, locs, step):
                if MB_factor != 1:
                    if verbose in [True]:
                        print([k + locs*n for n in range(MB_factor)])
                    a = [k + locs*n for n in range(MB_factor)]
                    file.write('\t'.join(str(x) for x in a) + "\n")
                else:
                    if verbose in [True]:
                        print(k)
                    a = k
                    file.write(str(a) + '\n')
        return(None)

if __name__ == "__main__":

    # Argument Parser
    parser = argparse.ArgumentParser(description='Script to print Multi-Band slice acquisition order to a file for Multi-Band sequence acquisitions')

    ## Parse Arguments
    parser.add_argument("-s","-slices","--slices", 
        type=int, 
        dest="slices", 
        metavar="<number_of_slices>", 
        required=True, 
        help="Number of slices in acquisition direction.")
    parser.add_argument("-mb","--mb", 
        type=int, 
        dest="MB_factor", 
        metavar="<MB_factor>", 
        required=True, 
        help="Multi-Band facor for the acquisition sequence.")
    parser.add_argument("-m","-mode","--mode", 
        type=str, 
        dest="mode", 
        metavar="interleaved", 
        required=False, 
        default="interleaved", 
        help="Multi-Band slice acquisition mode ('interleaved' or 'default'). [default option: interleaved]")
    parser.add_argument("-o","-out","--out", 
        type=str, 
        dest="output", 
        metavar='output', 
        required=False, 
        default="sliceOrder.txt", 
        help="Output file name and directory. [default: <current_working_directory>/sliceOrder.txt]")
    parser.add_argument("-v","--verbose", 
        dest="verbose", 
        required=False, 
        action="store_true", 
        help="Print information to the command line.")

    args = parser.parse_args()

    # Print help message in the case
    # of no arguments
    try:
        args = parser.parse_args()
    except SystemExit as err: 
        if err.code == 2: 
            parser.print_help()

    if args.verbose:
    	args.verbose = True

    mb_slice(args.slices, args.MB_factor, args.mode, args.output, args.verbose)