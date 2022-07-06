Post-process (Stage 3)
~~~~~~~~~~~~~~~~~~~~~~~~

Perform stage 3 of the preprocessing which includes:

  * Computing DTI (diffusion tensor imaging) metrics (e.g. FA, MD, RD, etc.)
  * QC (quality control, via `EDDY QUAD <https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddyqc>`_)

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

  #######################################
  # Prints usage to the command line interface.
  # Arguments:
  #   None
  #######################################
  Usage(){
    cat << USAGE
    Usage: 
        
        $(basename ${0}) <--options> [--options]
    
    Performs post-processing, which includes dMR image quality control, and the diffusion model tensor fit.

    Required arguments
      -d, --dwi                       Input DWI file.
      -b, --bval                      Corresponding bval file.
      -e, --bvec                      Corresponding bvec file.
      --dwi-json                      Corresponding dMRI JSON sidecar.
      --outdir                        Output parent data directory.
      --slspec                        Slice order specification file.
      --acqp                          Acquisition parameter file.
      --idx                           Slice phase encoding index file.
      --topup-dir                     TOPUP output directory.
      --eddy-dir                      EDDY output directory.
    
    Optional arguments
      -h, -help, --help               Prints the help menu, then exits.

  USAGE
    exit 1
  }


  # SCRIPT MAIN BODY

  # Parse arguments
  [[ ${#} -eq 0 ]] && Usage;
  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      -d|--dwi) shift; dwi=${1} ;;
      -b|--bval) shift; bval=${1} ;;
      -e|--bvec) shift; bvec=${1} ;;
      --dwi-json) shift; dwi_json=${1} ;;
      --outdir) shift; outdir=${1} ;;
      --eddy-dir) shift; eddy_dir=${1} ;;
      --slspec) shift; slspec=${1} ;;
      --idx) shift; idx=${1} ;;
      --acqp) shift; acqp=${1} ;;
      --topup-dir) shift; topup_dir=${1} ;;
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

  # Post-process output dir
  cwd=${PWD}
  preproc_dir=${outdir}/preprocessed_data
  qc_dir=${outdir}/eddy.qc

  log "START: POST-PROCESS"

  if [[ ! -d ${preproc_dir} ]]; then
    run mkdir -p ${preproc_dir}

    run cd ${preproc_dir}

    # Remove negative intensity values (caused by spline interpolation 
    # during preprocessing).
    run fslmaths ${dwi} -thr 0 dwi
    run cp ${bval} dwi.bval
    run cp ${bvec} dwi.bvec
    
    [[ -f ${dwi_json} ]] && run cp ${dwi_json} dwi.json

    # Create brain mask
    tmp_dir=${preproc_dir}/tmp_${RANDOM}
    run mkdir -p ${tmp_dir}
    run extract_b0 --dwi ${preproc_dir}/dwi.nii.gz --bval ${preproc_dir}/dwi.bval --bvec ${preproc_dir}/dwi.bvec --out ${tmp_dir}/b0.nii.gz
    run bet ${tmp_dir}/b0.nii.gz ${preproc_dir}/nodif_brain -m -f 0.25 -R
    rm -rf ${tmp_dir}

    # DTIFIT
    [[ ! -d ${preproc_dir}/dtifit ]] && run mkdir -p ${preproc_dir}/dtifit
    run dtifit \
    -k dwi \
    -o ${preproc_dir}/dtifit/data \
    -m ${preproc_dir}/nodif_brain_mask \
    -r dwi.bvec \
    -b dwi.bval \
    --save_tensor
  fi

  if [[ ! -d ${qc_dir} ]]; then
    run cd ${preproc_dir}
    run eddy_quad ${eddy_dir}/eddy_corrected \
    -idx ${idx} \
    -par ${acqp} \
    -m ${preproc_dir}/nodif_brain \
    -b ${preproc_dir}/dwi.bval \
    -g ${preproc_dir}/dwi.bvec \
    -o ${qc_dir} \
    -f ${topup_dir}/fieldmap \
    -s ${slspec} \
    -v
  fi
  log "END: POST-PROCESS"
