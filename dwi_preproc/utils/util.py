"""Utility module and functions for the ``dwi_preproc`` package.
"""
import os
import json

from typing import Any, Dict, Union

from commandio.fileio import file

def read_json(json_file: Union[str,file]) -> Dict[str, Any]:
    """Reads JavaScript Object Notation (JSON) file into a dictionary.
    
    Args:
        json_file: Input file.
        
    Returns: 
        Dictionary of key mapped items from JSON file.
    """
    # Get absolute path to file
    if json_file.endswith('.json') and os.path.exists(json_file):
        pass
    else:
        json_file: str = ""

    # Read JSON file
    try:
        if json_file:
            json_file: str = os.path.abspath(json_file)
            with open(json_file) as file:
                return json.load(file)
        else:
            return dict()
    except json.JSONDecodeError:
        return dict()


def update_json(json_file: Union[str,file], dictionary: Dict[str, Any]) -> str:
    """Updates JavaScript Object Notation (JSON) file. 
    
    If the file does not exist, it is created once this function is called.
    
    Args:
        json_file: Input file.
        dictionary: Dictionary of key mapped items to write to JSON file.
        
    Returns: 
        Updated JSON file.
    """
    # Read JSON file
    data_orig: Dict[str, Any] = read_json(json_file)

    # Update original data from JSON file
    data_orig.update(dictionary)

    # Write updated JSON file
    with open(json_file, "w") as file:
        json.dump(data_orig, file, indent=4)

    # Get absolute path to file
    json_file: str = os.path.abspath(json_file)

    return json_file
