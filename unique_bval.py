#!/usr/bin/env python

'''Indentifies unique non-zero b-values (bvals) from some input bval file for diffusoin weighted image (DWI) data.
'''

# Import packages/modules
import os
import sys
import numpy as np
from typing import Union, Type

# Import command line parser
import argparse

# Define functions

def main():
    '''main function
    - Parses arguments
    '''

    # Argument parser
    parser = argparse.ArgumentParser(
        description="Indentifies unique non-zero b-values (bvals) from some input bval file for diffusoin weighted image (DWI) data.")

    # Parse Arguments
    # Required Arguments
    reqoptions = parser.add_argument_group('Required arguments')
    reqoptions.add_argument('-b', '--bval',
                            type=file,
                            dest="bval_file",
                            metavar="FILE.bval",
                            required=True,
                            help="Input bval file for some DWI data.")

    args = parser.parse_args()

    # Print help message in the case
    # of no arguments
    try:
        args = parser.parse_args()
    except SystemExit as err:
        if err.code == 2:
            parser.print_help()
            sys.exit(1)

    # Run
    bvals = get_unique_bval(bval_file=args.bval_file)
    # print(bvals)
    print(" ".join(str(val) for val in bvals))

def file(file:str) -> str:
    '''Ensures file exists
    
    Args:
        file: Input file.
        
    Returns:
        file: File name.
    
    Raises:
        FileNotFoundError: An error occured in which the file was not found.
    '''
    if os.path.exists(file):
        return file
    else:
        raise FileNotFoundError(f"Could not locate the file: {file}")

def get_unique_bval(bval_file: Union[file,str]) -> Union[list,int]:
    '''Finds unique b-values from a bvals file.
    
    Creates a list of unique bvalues (as integers) from some
    input file (bval file).
    
    Args:
        bval_file: Input bval file.
    
    Returns:
        List of integers that corresponds to unique b-values.
    '''
    bval_file = os.path.abspath(bval_file)
    bval_array = np.loadtxt(bval_file)
    bval_set = set([ int(val) for val in bval_array ])
    return list(bval_set.difference({0}))

if __name__ == "__main__":
    main()
