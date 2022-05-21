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
. ${scripts_dir}/src/lib.sh

#######################################
# Prints usage to the command line interface.
# Args:
#   None
#######################################
Usage(){
  cat << USAGE
  Usage: 
      
      $(basename ${0}) <--options> [--options]
  
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

USAGE
  exit 1
}


#######################################
# Uses shell's built-in hash function to check dependency.
# Globals:
#   log
#   err
# Args:
#   Dependency to check, e.g. shell command.
# Returns
#   0 if no errors, non-zero on error.
#######################################
dependency_check(){
  if ! hash ${1} 2>/dev/null; then
    exit_error "Dependency ${1} is not installed or added to the system path. Please check. Exiting..."
  fi
}


# SCRIPT BODY

# Set defaults
mporder=""
mb=""
echo_spacing=0.05
factor=0

# Parse arguments
[[ ${#} -eq 0 ]] && Usage;
while [[ ${#} -gt 0 ]]; do
  case "${1}" in
    -d|--dwi) shift; dwi=${1} ;;
    -b|--bval) shift; bval=${1} ;;
    -e|--bvec) shift; bvec=${1} ;;
    -b0|--b0|--sbref) shift; sbref=${1} ;;
    --slspec) shift; slspec=${1} ;;
    -mb|--multiband-factor) shift; mb=${1} ;;
    --idx) shift; idx=${1} ;;
    --acqp) shift; acqp=${1} ;;
    --dwi-json) shift; dwi_json=${1} ;;
    --b0-json|--sbref-json) shift; b0_json=${1} ;;
    --data-dir) shift; data_dir=${1} ;;
    --template) shift; templates+=( ${1} ) ;;
    --template-brain) shift; template_brains+=( ${1} ) ;;
    --labels) shift; labels+=( ${1} ) ;;
    --out-tract) shift; out_tracts+=( ${1} ) ;;
    --mporder) shift; mporder=${1} ;;
    --echo-spacing) shift; echo_spacing=${1} ;;
    --factor) shift; factor=${1} ;;
    -h|-help|--help) shift; Usage; ;;
    -*) echo_red "$(basename ${0}): Unrecognized option ${1}" >&2; Usage; ;;
    *) break ;;
  esac
  shift
done

# Check args
if [[ ${#templates[@]} -eq ${#template_brains[@]} ]] && [[ ${#template_brains[@]} -eq ${#labels[@]} ]] && [[ ${#labels[@]} -eq ${#out_tracts[@]} ]]; then
  echo ""
else
  echo_red "Unequal number of mulit-input options."
  Usage;
fi

# Check dependencies
deps=( topup eddy mrconvert dwiextract ss3t_csd_beta1 )

for dep in ${deps[@]}; do
  dependency_check ${dep}
done

# variable info
sub_id=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $1}' | sed "s@sub-@@g")
run_id=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $4}' | sed "s@run-@@g")
bshell=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $2}' | sed "s@acq-@@g")

outdir=${data_dir}/sub-${sub_id}/${bshell}/run-${run_id}
topup_dir=${outdir}/topup
eddy_dir=${outdir}/eddy
preproc_dir=${outdir}/preprocessed_data

log_dir=${outdir}/logs
log=${log_dir}/dwi.log
err=${log_dir}/dwi.err

mkdir -p ${log_dir}

# Preprocess data
${scripts_dir}/src/import.sh \
--b0 ${sbref} \
--dwi ${dwi} \
--bval ${bval} \
--bvec ${bvec} \
--data-dir ${data_dir} \
--acqp ${acqp} \
--slspec ${slspec} \
--dwi-json ${dwi_json} \
--b0-json ${sbref_json} \
--multiband-factor ${mb} \
--echo-spacing ${echo_spacing}

${scripts_dir}/src/run_topup.sh \
--phase ${outdir}/import/phase \
--acqp ${outdir}/import/dwi.params.acqp \
--out-dir ${outdir}

${scripts_dir}/src/run_eddy.sh \
--dwi ${dwi} \
--bval ${bval} \
--bvec ${bvec} \
--outdir ${outdir} \
--acqp ${outdir}/import/dwi.params.acqp \
--slspec ${outdir}/import/dwi.slice_order \
--topup-dir ${topup_dir} \
--mporder ${mporder} \
--factor ${factor}

${scripts_dir}/src/postproc.sh \
--dwi ${eddy_dir}/eddy_corrected.nii.gz \
--bval ${bval} \
--bvec ${eddy_dir}/eddy_corrected.eddy_rotated_bvecs \
--dwi-json ${dwi_json} \
--outdir ${outdir} \
--eddy-dir ${eddy_dir} \
--slspec ${outdir}/import/dwi.slice_order \
--idx ${outdir}/import/dwi.idx \
--acqp ${outdir}/import/dwi.params.acqp \
--topup-dir ${topup_dir}

for (( i=0; i < ${#templates[@]}; i++)); do
  xfm_tck \
  --dwi=${preproc_dir}/dwi.nii.gz \
  --bval=${preproc_dir}/dwi.bval \
  --bvec=${preproc_dir}/dwi.bvec \
  --json=${preproc_dir}/dwi.json \
  --log=${log_dir}/tract.log \
  --template=${templates[$i]} \
  --template-brain=${template_brains[$i]} \
  --labels=${labels[$i]} \
  --out-dir=${outdir}/tractography/${out_tracts[$i]} \
  --frac-int=0.25 \
  --QIT \
  --symmetric \
  --zero-diagonal \
  --FA --MD --AD --RD # --no-cleanup
done

log "END: dMRI Preprocessing"

