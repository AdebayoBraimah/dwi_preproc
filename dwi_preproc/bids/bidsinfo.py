"""Parse and store relevant information from BIDS input files."""
import os
import fnmatch
from warnings import warn_explicit

from typing import Dict, Union, Set

from commandio.fileio import File, file

from dwi_preproc.utils.util import read_json
from dwi_preproc.utils.niio import NiiFile, image

class BIDSInfo():
    """Class for parsing BIDS filenames and storing the relevant information."""
    # Attributes

    # BIDS subject and acquistion related information
    sub: Union[int,str] = None
    ses: Union[int,str] = None
    acq: Union[int,str] = None
    dir: str = None
    run: Union[int,str] = None
    seq: str = None
    bids: Dict[str,str] = None

    # BIDS file related information
    img: str = None
    bval: str = None
    bvec: str = None
    json: str = None

    def __init__(self, img: Union[file, str], exist: bool = False) -> None:
        """Class for parsing BIDS filenames and storing the relevant information.

        Args:
            img: Input BIDS image file.
            exist: Check if input file exists. Defaults to False.
        """
        img: image = os.path.abspath(img)
        
        with NiiFile(src=img, assert_exists=True, validate_nifti=True) as f:
            _, basename, _ = f.file_parts()
            
            self.seq: str = basename.split(sep="_")[-1]

            self.img: image = f.abspath()
            self.json: file = f.rm_ext() + ".json"

            file_set: Set = {self.img, self.json}

            if self.seq.lower() == 'dwi':
                self.bval: str = f.rm_ext() + ".bval"
                self.bvec: str = f.rm_ext() + ".bvec"

                file_set.add(self.bval)
                file_set.add(self.bvec)

        for f in file_set:
            if not os.path.exists(f):
                warn_explicit(message=f"WARNING: {f} does not exist.",
                category=Warning)

            if exist:
                with File(src=f,assert_exists=True) as _:
                    pass
        
        # Relevant BIDS information
        self.sub: Union[int,str] = _bids_str_match(basename, match_str='sub-*', sep="_")
        self.ses: Union[int,str] = _bids_str_match(basename, match_str='ses-*', sep="_")
        self.acq: Union[int,str] = _bids_str_match(basename, match_str='acq-*', sep="_")
        self.dir: str = _bids_str_match(basename, match_str='dir-*', sep="_")
        self.run: Union[int,str] = _bids_str_match(basename, match_str='run-*', sep="_")
        self.bids: Dict[str,str] = read_json(json_file=self.json)


def _bids_str_match(s: str, /, match_str: str, sep: str ="_") -> str:
    """BIDS sub-string matching helper function.

    NOTE:
        Wildcards ``*`` may also be included in the ``match_str`` argument.

    Args:
        s: Input string.
        match_str: Sub-string of characters to match in input string.
        sep: Separator. Defaults to "_".

    Returns:
        BIDS related information from the sub-string.
    """
    try:
        match_str: str = match_str.replace('-','')
        return fnmatch.filter(s.split(sep=sep), match_str)[0][len(match_str):]
    except IndexError:
        return None
