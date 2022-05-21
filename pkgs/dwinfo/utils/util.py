"""Utily functions module.
"""
import os


def remove_ext(s: str, /) -> str:
    """Removes file extension from a file.

    Args:
        s: Position only argument for file path.

    Returns:
        File path and file without file extension
    """
    if s.endswith('.gz'):
        return s[:-7]
    else:
        return os.path.splitext(s)[0]
