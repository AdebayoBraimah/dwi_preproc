"""Enumerators of the ``dwinfo`` module.
"""
from enum import Enum, unique


@unique
class SliceAcqOrder(Enum):
    """Slice acquisistion order method."""

    interleaved: str = "interleaved"
    default: str = "default"
    single_shot: str = "single-shot"


@unique
class NiiHeaderField(Enum):
    """NIFTI file header field options."""

    descrip: str = "descrip"
    intent_name: str = "intent_name"
