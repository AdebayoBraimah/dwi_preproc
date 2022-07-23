"""Reads, and writes BIDS releated metadata to file or into a python dictionary.

Key valued BIDS data may also be written to the CLI (command line interface).
"""
import os

from ast import literal_eval
from typing import Any, Dict, List, Optional, Union

from dwi_preproc.utils.util import update_json, read_json


class BIDSNameError(Exception):
    pass


def write_bids_val(
    bids_label: Union[str, List[str]],
    bids_param: List[Any],
    out_json: str,
    json_file: Optional[str] = None,
) -> str:
    """Writes/appends BIDS values associated with some BIDS key to a JSON file.

    NOTE:
        Existing BIDS labels/parameters are overwritten if they exist.

    Args:
        bids_label: BIDS label.
        bids_param: Corresponding BIDS parameter.
        out_json: Output JSON file.
        json_file: Input JSON file to append information to.

    Raises:
        IndexError: Exception that is raised if a different number of ``bids_label``s and ``bids_param``s are provided.
        BIDSNameError: Exception that is raised if the input ``bids_label`` or (labels) are not in pascal case.

    Returns:
        Output JSON file.
    """
    if not isinstance(bids_label, list):
        bids_label: List[str] = [bids_label]

    if not isinstance(bids_param, list):
        bids_param: List[Any] = [bids_param]

    # Check if arrays/lists are of same length
    if len(bids_label) != len(bids_param):
        raise IndexError(
            "Inputs for 'bids_label' and 'bids_param' are of different lengths."
        )

    # Check if input labels are BIDS compliant
    for label in bids_label:
        if not is_camel_case(s=label, pascal_case=True):
            raise BIDSNameError(
                f"Input metadata field {label} is not BIDS compliant"
            )

    # Construct dictionary/hashmap of key-value terms
    json_dict: Dict[str, Any] = {}

    for label, param in zip(bids_label, bids_param):
        try:
            param: Union[int, float] = literal_eval(param)
        except ValueError:
            pass
        tmp_dict: Dict[str, Any] = {label: param}
        json_dict.update(tmp_dict)

    # Append to input JSON file if provided
    if json_file is not None:
        json_file: str = os.path.abspath(json_file)
        json_data: Dict[str, Any] = read_json(json_file=json_file)
        json_data.update(json_dict)
        json_dict: Dict[str, Any] = json_data

    # Write/update JSON file
    return update_json(json_file=out_json, dictionary=json_dict)


def print_bids_val(bids_label: str, json_file: str) -> None:
    """Prints BIDS related value to the command line.

    Args:
        bids_label: BIDS label (e.g. dictionary key).
        json_file: Path to JSON file.

    Raises:
        BIDSNameError: Exception that is raised if the ``bids_label`` is not in pascal case.
    """
    # Check if input labels are BIDS compliant
    if is_camel_case(s=bids_label, pascal_case=True):
        pass
    else:
        raise BIDSNameError(
            f"Input metadata field {bids_label} is not BIDS compliant"
        )

    # Construct dictionary/hashmap of key-value terms
    json_dict: Dict[str, Any] = read_json(json_file=os.path.abspath(json_file))

    # Print desired BIDS parameter to the command line
    print(json_dict.get(bids_label))

    return None


def is_camel_case(s: str, pascal_case: bool = True) -> bool:
    """Tests if some input string is camel case (camelCase).

    NOTE: 
        This function is configured for BIDS use cases, in which metadata must 
        be in pascal case (PascalCase), with the first letter being uppercase.
        To use for non-BIDS cases (e.g. camelCase), set the ``pascal_case``
        argument to ``False``.

    Usage example:
        >>> is_camel_case("CamelCase", pascal_case=True)
        True
        >>> is_camel_case("camelcase", pascal_case=True)
        False
        >>> is_camel_case("camelCase", pascal_case=True)
        False
        >>> is_camel_case("camelCase", pascal_case=False)
        True
        
    Args:
        s: Input string to test.
        pascal_case: Test for pascal case. Defaults to False.

    Returns:
        Boolean.
    """
    if pascal_case:
        return (
            s != s.lower()
            and s != s.upper()
            and s[0].isupper()
            and "_" not in s
        )
    else:
        return s != s.lower() and s != s.upper() and "_" not in s