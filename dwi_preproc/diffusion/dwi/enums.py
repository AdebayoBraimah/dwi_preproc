"""Enumerators of ``dwinfo`` module.
"""
from enum import Enum, unique


@unique
class SliceAcqOrder(Enum):
    """Slice acquisistion order method."""

    interleaved: str = "interleaved"
    default: str = "default"
    single_shot: str = "single-shot"
