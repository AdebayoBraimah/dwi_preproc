#!/usr/bin/env python3
"""Read, write, and compute relevant information for diffusion and functional MR neuroimage preprocessing.
"""
import os
import sys
import argparse

from typing import Any, Dict, Tuple

from utils.sliceorder import write_slice_order
from utils.mporder import optimal_mporder
from utils.bidsval import write_bids_val, print_bids_val
from utils.util import remove_ext


def main():
    dwinfo()
    return None


def dwinfo() -> None:
    """_summary_

    _extended_summary_

    Returns:
        _description_
    """
    args, parser = arg_parser()

    # Print help message in the case of no arguments
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    else:
        args: Dict[str, Any] = vars(args)

    # Check this method first as NIFTI/JSON files are
    #   not required.
    if args.get('method') == 'mporder':
        print(
            optimal_mporder(
                sliceorder=args.get('slice_order'),
                factor_divide=args.get('fact_div'),
            )
        )
        return None

    if args.get('bids_nifti') and args.get('bids_json'):
        image: str = os.path.abspath(args.get('bids_nifti'))
        json_file: str = os.path.abspath(args.get('bids_json'))
    elif args.get('bids_nifti'):
        image: str = os.path.abspath(args.get('bids_nifti'))
        json_file: str = f"{remove_ext(image)}.json"
    else:
        print(
            "\nREQUIRED: '--bids-nifti' and/or '--bids-json' if the corresponding JSON file share the same filename. See '--help' menu for details.\n"
        )
        parser.print_help()
        sys.exit(1)

    if not args.get('out_json'):
        out_json: str = json_file
    else:
        out_json: str = args.get('out_json')

    if (
        args.get('mode_default')
        and args.get('mode_interleaved')
        and args.get('mode_ss')
    ):
        mode: str = "interleaved"
        print(
            "\nAll three methods for slice order acquisition were specified. Using 'interleaved'."
        )
    elif args.get('mode_ss'):
        mode: str = "single-shot"
    elif args.get('mode_default'):
        mode: str = "default"
    else:
        mode: str = "interleaved"

    if args.get('method') == 'sliceorder':
        _: str = write_slice_order(
            image,
            mb_factor=args.get('mb_factor'),
            mode=mode,
            out_file=args.get('sls_output'),
        )
    elif args.get('method') == 'read-bids':
        print_bids_val(bids_label=args.get('rbids_label'), json_file=json_file)
    elif args.get('method') == 'write-bids':
        _: str = write_bids_val(
            bids_label=args.get('wbids_label'),
            bids_param=args.get('bids_param'),
            out_json=out_json,
        )

    return None


def arg_parser() -> Tuple[
    argparse.ArgumentParser.parse_args, argparse.ArgumentParser
]:
    # Init parser
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=lambda prog: argparse.HelpFormatter(
            prog, max_help_position=55, width=100
        ),
    )

    # Parse Arguments

    mainargparser = parser.add_subparsers(
        title="subcommands",
        description="dwinfo subcommands",
        help="Type the 'subcommand' name followed by '-h' or '--help' for more information.",
    )

    reqoptions = parser.add_argument_group('Required Arguments')

    reqoptions.add_argument(
        '-n',
        '-nifti',
        '--bids-nifti',
        dest="bids_nifti",
        type=str,
        metavar="<FILE>",
        default=None,
        help="REQUIRED: Input (BIDS) NIFTI file.",
    )

    reqoptions.add_argument(
        '-j',
        '-json',
        '--bids-json',
        dest="bids_json",
        type=str,
        metavar="<FILE>",
        default=None,
        help="REQUIRED: Corresponding input (BIDS) JSON (sidecar) file. NOTE: Not needed IF input NIFTI file is BIDS compliant.",
    )

    # SLICE ORDER ARGS
    slsoptions = mainargparser.add_parser(
        'sliceorder',
        parents=[reqoptions],
        formatter_class=lambda prog: argparse.HelpFormatter(
            prog, max_help_position=55, width=100
        ),
        add_help=False,
        help="Slice order specification file creation tool for FSL's eddy. NOTE: '--default', '--interleaved', and '--single-shot' are mutually exclusive options.",
    )

    slsoptions.add_argument(
        '-mb',
        '--mb-factor',
        type=int,
        metavar="<INT>",
        dest="mb_factor",
        default=None,
        help="REQUIRED: Multiband factor.",
    )

    slsoptions.add_argument(
        '-o',
        '-out',
        '--output',
        type=str,
        metavar="<FILE>",
        dest="sls_output",
        default=None,
        help="REQUIRED: File name for output slice specification file.",
    )

    slsoptions.add_argument(
        '--default',
        dest="mode_default",
        action="store_true",
        default=None,
        help="Default acquisition order in which slices are acquired with an ascending slice order [Default: disabled].",
    )

    slsoptions.add_argument(
        '--interleaved',
        dest="mode_interleaved",
        action="store_true",
        default=True,
        help="Optimal slice acquisition technique in which non-adjacent slices are acquired (best for diffusion, and structural MR images) [Default: enabled].",
    )

    slsoptions.add_argument(
        '--single-shot',
        dest="mode_ss",
        action="store_true",
        default=None,
        help="Slice acquisition technique in which slices are acquired sequentially with an ascending slice order (best for functional MR images) [Default: disabled].",
    )

    slsoptions.set_defaults(method='sliceorder')

    # MPORDER ARGS
    mpoptions = mainargparser.add_parser(
        'mporder',
        parents=[reqoptions],
        formatter_class=lambda prog: argparse.HelpFormatter(
            prog, max_help_position=55, width=100
        ),
        add_help=False,
        help="MPorder determination tool.",
    )

    mpoptions.add_argument(
        '-s',
        '--slice-order',
        type=str,
        metavar="<FILE>",
        dest="slice_order",
        default=None,
        help="REQUIRED: File name for input slice specification file (see the 'sliceorder' subcommand option if this file does not exist).",
    )

    mpoptions.add_argument(
        '--factor-divide',
        type=int,
        metavar="<INT>",
        dest="fact_div",
        default=None,
        help="OPTIONAL: Factor to divide the mporder by (recommended: 4) [Default: None].",
    )

    mpoptions.set_defaults(method='mporder')

    # READ BIDS ARGS
    rbidsoptions = mainargparser.add_parser(
        'read-bids',
        parents=[reqoptions],
        formatter_class=lambda prog: argparse.HelpFormatter(
            prog, max_help_position=55, width=100
        ),
        add_help=False,
        help="Read from BIDS JSON (sidecar) file, and prints the keyed value to the command line.",
    )

    rbidsoptions.add_argument(
        '--bids-label',
        type=str,
        metavar="<STR>",
        dest="rbids_label",
        default=None,
        help="REQUIRED: BIDS label (e.g. dictionary key).",
    )

    rbidsoptions.set_defaults(method='read-bids')

    # READ BIDS ARGS
    wbidsoptions = mainargparser.add_parser(
        'write-bids',
        parents=[reqoptions],
        formatter_class=lambda prog: argparse.HelpFormatter(
            prog, max_help_position=55, width=100
        ),
        add_help=False,
        help="Write to BIDS JSON (sidecar) file.",
    )

    wbidsoptions.add_argument(
        '--bids-label',
        type=str,
        metavar="<STR>",
        dest="wbids_label",
        action='append',
        default=None,
        help="REQUIRED: BIDS label (e.g. dictionary key). NOTE: Repeatable.",
    )

    wbidsoptions.add_argument(
        '--bids-param',
        type=str,
        metavar="<STR>",
        dest="bids_param",
        action='append',
        default=None,
        help="REQUIRED: Corresponding BIDS parameter. NOTE: Repeatable.",
    )

    wbidsoptions.add_argument(
        '--out-json',
        type=str,
        metavar="<FILE>",
        dest="out_json",
        default=None,
        help="REQUIRED: Output JSON file. NOTE: If not specified, then the input JSON file is written/appended to.",
    )

    wbidsoptions.set_defaults(method='write-bids')

    args: argparse.ArgumentParser.parse_args = parser.parse_args()
    return args, parser


if __name__ == '__main__':
    main()
