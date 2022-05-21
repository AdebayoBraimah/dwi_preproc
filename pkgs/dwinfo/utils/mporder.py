"""Computes the optimal mporder for ``FSL``'s ``eddy``.
"""
import os
import numpy as np


def optimal_mporder(sliceorder: str, factor_divide: int = None) -> int:
    """Computes optimal ``mporder`` for ``FSL``'s ``eddy``.

    The number of discrete cosine (DCT) basis sets used to model the 
    intra-slice movement within a volume (used by FSL's eddy). This value 
    is defined as N - 1 number of rows in the file referenced by ``sliceorder``,
    in which N is the number of slice excitations.

    For reference, this value should not exceed the number of excitations per 
    volume (e.g. given a MB factor of 3, with 45 acquired slices, the mporder 
    should not exceed 15).

    NOTE:
        An ``mporder`` of N - 1 is high and is not generally recommended. 
        Usually dividing by the mporder by a factor of 2 (N/2) or 4 (N/4) is 
        recommended by FMRIB.

        Link: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddy/UsersGuide#A--mporder

    Args:
        sliceorder: Slice acquisition order text file.
        factor_divide: Factor to divide the mporder by.

    Returns:
        Optimal mporder as an ``int``.
    """
    # Set mporder to N - 1, or the smallest value (integer) | N = number
    #   of slice excitations (e.g. the number of rows in the sliceorder
    #   file/matrix).
    sliceorder: str = os.path.abspath(sliceorder)
    N: int = np.loadtxt(sliceorder).shape[0]
    mporder: int = N - 1

    if factor_divide is not None:
        mporder: int = int(N / factor_divide)

    return mporder
