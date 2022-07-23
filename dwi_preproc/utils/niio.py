"""NIFTI file read/write module."""
import os
import nibabel as nib

from typing import NewType, Union
from warnings import warn

from commandio.fileio import File

from dwi_preproc.utils.enums import NiiHeaderField

# Globally define type(s)
image = NewType('image',str)


class InvalidNiftiFileError(Exception):
    """Exception intended for invalid NIFTI files."""
    pass


class NiiFile(File):
    """NIFTI file class specific for NIFTI files which inherits class methods from the ``File`` base class.

    Attributes:
        src: Input NIFTI file path.
        ext: File extension of input file.
    
    Usage example:
        >>> # Using class object as context manager
        >>> with NiiFile("file.nii") as nii:
        ...     print(nii.file_parts())
        ...
        ("path/to/file", "file", ".nii")
        >>> 
        >>> # or
        >>> 
        >>> nii = NiiFile("file.nii")
        >>> nii
        "file.nii"
        >>> nii.abspath()
        "abspath/to/file.nii"
        >>> 
        >>> nii.rm_ext()
        "file"
        >>>
        >>> nii.file_parts()
        ("path/to/file", "file", ".nii")
    
    Arguments:
        src: Path to NIFTI file.
        
    Raises:
        InvalidNiftiFileError: Exception that is raised in the case **IF** the specified NIFTI file exists, but is an invalid NIFTI file.
    """

    def __init__(self, src: Union[image,str], assert_exists: bool = False, validate_nifti: bool = False) -> None:
        """Initialization method for the NiiFile class.
        
        Usage example:
            >>> # Using class object as context manager
            >>> with NiiFile("file.nii") as nii:
            ...     print(nii.abspath())
            ...     print(nii.src)
            ...     print(nii.file_parts())
            ...
            "abspath/to/file.nii"
            "file"
            ("path/to/file", "file", ".nii")
            >>> 
            >>> # or
            >>> 
            >>> nii = NiiFile("file.nii")
            >>> nii
            "file.nii"
            >>> nii.abspath()
            "abspath/to/file.nii"
            >>> 
            >>> nii.rm_ext()
            "file"
            >>>
            >>> nii.file_parts()
            ("path/to/file", "file", ".nii")
        
        Arguments:
            file: Path to NIFTI file.
            assert_exists: Asserts that the specified input file must exist. 
            validate_nifti: Validates the input NIFTI file if it exists.
        
        Raises:
            InvalidNiftiFileError: Exception that is raised in the case **IF** the specified NIFTI file exists, but is an invalid NIFTI file.
        """
        self.src: str = src
        super(NiiFile, self).__init__(src)

        if self.src.endswith(".nii.gz"):
            self.ext: str = ".nii.gz"
        elif self.src.endswith(".nii"):
            self.ext: str = ".nii"
        else:
            self.ext: str = ".nii.gz"
            self.src: str = self.src + self.ext

        if assert_exists:
            assert os.path.exists(
                self.src
            ), f"Input NIFTI file {self.src} does not exist."

        if validate_nifti and os.path.exists(self.src):
            try:
                _: nib.Nifti1Image = nib.load(filename=self.src)
            except Exception as error:
                raise InvalidNiftiFileError(
                    f"The NIFTI file {self.src} is not a valid NIFTI file and raised the following error {error}."
                )

    # Overwrite several File base class methods
    def touch(self) -> None:
        """This class method is not implemented and will simply return None, and is not relevant/needed for NIFTI files.
        """
        return None

    def write(self, txt: str = "", header_field: str = "intent_name") -> None:
        """This class method writes relevant information to the NIFTI file header.
        
        This is done by writing text to either the ``descrip`` or ``intent_name``
        field of the NIFTI header.

        NOTE:
            * The ``descrip`` NIFTI header field has a limitation of 24 bytes - meaning that only a string of 24 characters can be written without truncation.
            * The ``intent_name`` NIFTI header field has a limitation of 16 bytes - meaning that only a string of 16 characters can be written without truncation.
        
        Usage example:
            >>> # Using class object as context manager
            >>> with NiiFile("file.nii") as nii:
            ...     nii.write(txt='Source NIFTI',
            ...               header_field='intent_name')
            ...
            >>> # or
            >>> 
            >>> nii = NiiFile("file.nii")
            >>> nii.write(txt='Source NIFTI',
            ...           header_field='intent_name')

        Arguments:
            txt: Input text to be added to the NIFTI file header.
            header_field: Header field to have text added to.
        """
        img: nib.Nifti1Image = nib.load(self.src)
        header_field: str = NiiHeaderField(header_field).name

        if header_field == "descrip":
            if len(txt) >= 24:
                warn(
                    f"WARNING: The input string is longer than the allowed limit of 24 bytes/characters for the '{header_field}' header field."
                )
            img.header["descrip"] = txt
        elif header_field == "intent_name":
            if len(txt) >= 16:
                warn(
                    f"WARNING: The input string is longer than the allowed limit of 16 bytes/characters for the '{header_field}' header field."
                )
            img.header["intent_name"] = txt
        return None
