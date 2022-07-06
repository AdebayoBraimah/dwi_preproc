EDDY (Stage 2)
~~~~~~~~~~~~~~~~~~

Perform stage 2 of the preprocessing which includes `FSL's EDDY <https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddy>`_.

.. code-block:: bash

  #!/usr/bin/env bash
  # -*- coding: utf-8 -*-
  # 
  # DESCRIPTION:
  # 
  # 
  # NOTE:
  #   Google shell style guide is used here for consistency. See the 
  #   style guide here: https://google.github.io/styleguide/shellguide.html
  # 

  # SET SCRIPT GLOBALS
  scripts_dir=$(echo $(dirname $(realpath ${0})))

  # SOURCE LOGGING FUNCTIONS
  . ${scripts_dir}/lib.sh
  dwinfo=$(realpath ${scripts_dir}/../pkgs/dwinfo/dwinfo.py)

  #######################################
  # Prints usage to the command line interface.
  # Arguments:
  #   None
  #######################################
  Usage(){
    cat << USAGE
    Usage: 
        
        $(basename ${0}) <--options> [--options]
    
    Performs eddy current correction, in addition to motion and distortion correction.
    Additionally, slice-to-volume motion correction is also performed.

    Required arguments
      -d, --dwi                       Input DWI file.
      -b, --bval                      Corresponding bval file.
      -e, --bvec                      Corresponding bvec file.
      --data-dir                      Output parent data directory.
      --slspec                        Slice order specification file.
      --acqp                          Acquisition parameter file.
      --idx                           Slice phase encoding index file.
      --outdir                        Parent output directory.
      --topup-dir                     TOPUP output directory.
    
    Optional arguments
      --mporder                       Number of discrete cosine functions used to model slice-to-volume motion.
                                      Set this parameter to 0 to disable slice-to-volume motion correction and 
                                      distortion correction. Otherwise, this parameter is automatically computed.
                                      [default: automatically computed].
      --factor                        Factor to divide the mporder by (if necessary). A factor division of 4 
                                      is recommended. [default: 0].
      -h, -help, --help               Prints the help menu, then exits.

  USAGE
    exit 1
  }


  # SCRIPT MAIN BODY

  # Set defaults
  mporder=""
  factor=0

  # Parse arguments
  [[ ${#} -eq 0 ]] && Usage;
  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      -d|--dwi) shift; dwi=${1} ;;
      -b|--bval) shift; bval=${1} ;;
      -e|--bvec) shift; bvec=${1} ;;
      --slspec) shift; slspec=${1} ;;
      --factor) shift; factor=${1} ;;
      --idx) shift; idx=${1} ;;
      --acqp) shift; acqp=${1} ;;
      --outdir) shift; outdir=${1} ;;
      --topup-dir) shift; topup_dir=${1} ;;
      --mporder) shift; mporder=${1} ;;
      -h|-help|--help) shift; Usage; ;;
      -*) echo_red "$(basename ${0}): Unrecognized option ${1}" >&2; Usage; ;;
      *) break ;;
    esac
    shift
  done

  # Log variabes
  log_dir=${outdir}/logs
  log=${log_dir}/dwi.log
  err=${log_dir}/dwi.err

  # Eddy output dir
  cwd=${PWD}
  eddy_dir=${outdir}/eddy

  # bsub -q gpu-v100 -gpu "num=1" -M 1000 -W 500 -n 1 -J "bash" -R "span[hosts=1]" -Is bash

  # Compute mporder
  if [[ -z ${mporder} ]]; then
    mporder=$(${dwinfo} mporder --bids-nifti ${dwi} --slice-order=${slspec} --factor-divide=${factor})
  fi

  if [[ ! -d ${eddy_dir} ]]; then
    run mkdir -p ${eddy_dir}

    log "START: EDDY"

    # Run eddy
    run eddy_cuda \
    --imain=${dwi} \
    --mask=${topup_dir}/nodif_brain_mask.nii.gz \
    --index=${outdir}/import/dwi.idx \
    --bvals=${bval} \
    --bvecs=${bvec} \
    --acqp=${acqp} \
    --out=${eddy_dir}/eddy_corrected \
    --very_verbose \
    --niter=5 \
    --fwhm=10,5,0,0,0 \
    --nvoxhp=5000 \
    --repol \
    --ol_type=both  \
    --ol_nstd=3 \
    --data_is_shelled \
    --cnr_maps \
    --residuals \
    --dont_mask_output \
    --slspec=${slspec} \
    --s2v_niter=10 \
    --mporder=${mporder} \
    --s2v_interp=trilinear \
    --s2v_lambda=1 \
    --topup=${topup_dir}/topup_results \
    --estimate_move_by_susceptibility \
    --mbs_niter=20 \
    --mbs_ksp=10 \
    --mbs_lambda=10

    dwi=${eddy_dir}/eddy_corrected.nii.gz
    bvec=${eddy_dir}/eddy_corrected.eddy_rotated_bvecs

    # Run BET on eddy output
    run extract_b0 --dwi ${dwi} --bval ${bval} --bvec ${bvec} --out ${eddy_dir}/hifib0.nii.gz
    run bet ${eddy_dir}/hifib0 ${eddy_dir}/nodif_brain -m -f 0.25 -R

    log "END: EDDY"
  else
    log "EDDY already completed."
  fi
