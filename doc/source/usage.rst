Usage
=========

Pipeline usage help menu. This help menu is found in ``dwi_preproc.sh`` and
can be accessed by typing:

.. code-block:: bash

    ./dwi_preproc.sh --help


.. note:: 

    Stage 5 of the preprocessing pipeline (single-shell CSD tractography) is performed
    via a separate python module documented `here <https://github.com/AdebayoBraimah/xfm_tck>`_.

.. code-block:: text

    Usage: 
        
        dwi_preproc.sh <--options> [--options]
    
    Performs similar preprocessing steps to that of the dHCP dMRI preprocessing pipeline.
    These preprocessing steps include:

        1. Topup (distortion estimation)
        2. Eddy (eddy current, motion, distortion, and slice-to-volume motion correction)
        3. QC
        4. DTI model fitting
        5. Tractography (Single-Shell CSD)

    Options marked as REPEATABLE may be specified more than once, however all such options
    must be specified the same number of times.

    Lastly, input data is assumed to be named in the BIDS v1.4.1+ convention, with '*_acq-' containing
    the shells (bvalues) of the acquisition. Other attributes in the filename should include:

        * subject ID (sub-<sub_id>_...)
        * run ID (..._run-<run_id>_...)

    Required arguments
        -d, --dwi                       Input 4D dMR/DW image file.
        -b, --bval                      Corresponding bval file.
        -e, --bvec                      Corresponding bvec file.
        -b0, --b0, --sbref              Reverse phase encoded b0 (single-band reference)
        --slspec                        Slice order specification file.
        --acqp                          Acquisition parameter file.
        --data-dir                      Output parent data directory.
        --template                      REPEATABLE: Standard whole-head template for registration and tractography.
        --template-brain                REPEATABLE: Standard brain template for registration and tractography.
        --labels                        REPEATABLE: Corrsponding template labels for tractography.
        --out-tract                     REPEATABLE: Corrsponding output directory basenames for tractography.
    
    Optional arguments
        --dwi-json                      Corresponding dMR/DW image JSON sidecar.
        --b0-json, --sbref-json         Corresponding b0/sbref JSON sidecar.
        --echo-spacing                  Echo-spacing parameter for the parameter acquisition file [default: 0.05].
        -mb, --multiband-factor         Multiband acceleration factor. NOTE: If this parameter is provided then 
                                        '--slspec' does not need to be specified. Additionally, this parameter can 
                                        also be specified via a JSON (sidecar) file.
        --idx                           Slice phase encoding index file.
        --mporder                       Number of discrete cosine functions used to model slice-to-volume motion.
                                        Set this parameter to 0 to disable slice-to-volume motion correction and 
                                        distortion correction. Otherwise, this parameter is automatically computed.
                                        [default: automatically computed].
        --factor                        Factor to divide the mporder by (if necessary). A factor division of 4 
                                        is recommended. [default: 0].
        -h, -help, --help               Prints the help menu, then exits.

