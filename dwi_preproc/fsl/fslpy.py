"""Module that contains wrapper functions for FSL binaries."""

# topup
# fslmaths
# bet
# eddy
# dtifit
# eddy_quad

from typing import Optional, Tuple,Union

from commandio.fileio import File, file
from commandio.logutil import LogFile
from commandio.command import Command
from commandio.workdir import WorkDir

from dwi_preproc.utils.niio import NiiFile, image

def topup(img: Union[image, str],outdir: str,acqp: Union[file, str], fout: bool = False, iout: bool = False, verbose: bool = False, config: Optional[Union[file,str]] = None, log: Optional[LogFile] = None) -> Tuple[image,Union[image,None],Union[image,None]]:
    """Performs image distortion correction for some input NIFTI image.

    Wrapper function for ``FSL``'s ``topup``.

    Args:
        img: Input image file.
        outdir: Output directory.
        acqp: Acquisition parameter files.
        fout: Output fieldmap. Defaults to False.
        iout: Output corrected 4D image. Defaults to False.
        verbose: Enable verbose output. Defaults to False.
        config: Configuration for ``FSL``'s ``topup``. Defaults to None.
        log: ``LogFile`` object for logging purposes. Defaults to None.

    Returns:
        * Corrected image.
        * Corrected 4D image.
        * Fieldmap.
    """
    with NiiFile(src=img, assert_exists=True, validate_nifti=True) as n:
        with WorkDir(src=outdir) as _:
            img: image = n.abspath()
    
    out_img: image = f"{outdir}/topup_results.nii.gz"

    cmd_str: str = f"topup --imain={img} --datain={acqp} --out={out_img}"

    if fout:
        fout_img: image = f"{outdir}/fieldmap.nii.gz"
        cmd_str: str = f"{cmd_str} --fout={fout_img}"
    else:
        fout_img: file = None

    if iout:
        iout_img: image = f"{outdir}/topup_b0s.nii.gz"
        cmd_str: str = f"{cmd_str} --iout={iout_img}"
    else:
        iout_img: file = None

    if verbose:
        cmd_str: str = f"{cmd_str} -v"

    if config:
        with File(src=config, assert_exists=True) as f:
            config: str = f.abspath()
        cmd_str: str = f"{cmd_str} --config={config}"
    
    cmd: Command = Command(cmd_str)
    cmd.check_dependency()
    cmd.run(log=log)

    return out_img, fout_img, iout_img

def bet():
    pass

def eddy():
    pass

def dtifit():
    pass

def eddy_quad():
    pass

def fslmerge():
    pass


class fslmaths():

    def __init__(self) -> None:
        pass