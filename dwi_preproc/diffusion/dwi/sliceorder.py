"""Generates slice order of dynamic sequence acquisition for diffusion/functional MR images.
"""
import os
import numpy as np
import nibabel as nib

from typing import List, Optional, Union

from commandio.fileio import file

from dwi_preproc.utils.enums import SliceAcqOrder
from dwi_preproc.utils.niio import image


def write_slice_order(
    s: Union[int, str, image],
    /,
    mb_factor: int,
    mode: str = 'interleaved',
    out_file: Union[file, str] = 'file.slice.order',
    return_mat: Optional[bool] = False,
) -> Union[str, np.array]:
    """Generates the slice acquisition order file for use with ``eddy's`` slice-to-volume motion correction method.

    The file generated consists of an (N/m) x m matrix | N = number of slices 
    in the acquisition direction (assumed to be the z-direction), and 
    m = multi-band factor.

    NOTE:
        * Links for details:
            * Documentation: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddy/UsersGuide#A--slspec
            * Implementation: https://git.fmrib.ox.ac.uk/seanf/dhcp-neonatal-fmri-pipeline/-/blob/master/dhcp/resources/default_func.slorder
            * Implementation: https://git.fmrib.ox.ac.uk/matteob/dHCP_neo_dMRI_pipeline_release/-/blob/master/slorder.txt
        * It is **RECOMMENDED** that 'interleaved' be used with dMR images and that 'single-shot' be used functional MR images **IF** the slice acquisition order is not accurately known.
        * This wrapper function was written with help from Gregory Lee, PhD.
    
    WARNING:
        This has only been tested with Philips MR images. Use with supreme caution.
    
    Usage example:
        >>> sls_order = write_slice_order(44,
        ...                               mb_factor=6,
        ...                               mode='single-shot',
        ...                               out_file='file.slice.order',
        ...                               return_mat=False)
        ...

    Args:
        s: Position only argument for input NIFTI file OR the number of slices in the acquisition direction.
        mb_factor: Multi-band factor.
        mode: Acquisition algorithm/method/scheme used to acquire the data (Defaults to 'interleaved'). Valid options include:
            * ``interleaved``: Optimal slice acquisition technique in which non-adjacent slices are acquired (best for diffusion, and structural MR images).
            * ``single-shot``: Slice acquisition technique in which slices are acquired sequentially with an ascending slice order (best for functional MR images).
            * ``default``: Default acquisition order in which slices are acquired with an ascending slice order.
        out_file: Output file name. Defaults to 'file.slice.order'.
        return_mat: Return a numpy 2-dimensional array (matrix) rather than a file. Defaults to False.

    Returns:
        File name as ``str`` or numpy 2-dimensional array.
    """
    # Check input types
    try:
        slices: int = int(s)
    except ValueError:
        slices: int = _num_slices(image=s)

    mb_factor: int = int(mb_factor)
    mode: str = SliceAcqOrder(mode.lower()).name

    # Locations (in the slices) divided by Multi-Band Factor
    locs: int = slices // mb_factor

    if mode == 'interleaved':
        step: int = int(np.round(np.sqrt(locs)))
    elif mode == 'default':
        step: int = 2
    elif mode == 'single_shot':
        step: int = 1

    # Iterate through each MB acquisition to get slice ordering
    n: List[int] = []

    for s in range(step):
        for k in range(s, locs, step):
            if mb_factor != 1:
                a: List[int] = [k + locs * j for j in range(mb_factor)]
                n.append(a)
            else:
                a: int = k
                n.append(a)

    if return_mat:
        return np.array(n)

    slice_order: np.arrary = np.array(n)
    np.savetxt(out_file, slice_order, fmt="%i")
    out_file: str = os.path.abspath(out_file)

    return out_file


def _num_slices(image: Union[image, str]) -> int:
    """Finds the number of slices in the z-direction.

    Helper function used to load NIFTI image file data.
    
    Args:
        image: Input NIFTI-1 (neuro-) image.

    Returns:
        Integer that corresponds to the number of slices (in the z-direction)
    """
    return nib.load(filename=image).header.get('dim', '')[3]
