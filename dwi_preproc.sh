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

#######################################
# Prints usage to the command line interface.
# Arguments:
#   None
#######################################
Usage(){
  cat << USAGE
  Usage: 
      
      $(basename ${0}) <--options> [--options]

  Required arguments
    -ARGS
  
  Optional arguments
    -h, -help, --help               Prints the help menu, then exits.

USAGE
  exit 1
}


#######################################
# Prints message to the command line interface
#   in some arbitrary color.
# Arguments:
#   msg
#######################################
echo_color(){
  msg='\033[0;'"${@}"'\033[0m'
  echo -e ${msg} 
}


#######################################
# Prints message to the command line interface
#   in red.
# Arguments:
#   msg
#######################################
echo_red(){
  echo_color '31m'"${@}"
}


#######################################
# Prints message to the command line interface
#   in green.
# Arguments:
#   msg
#######################################
echo_green(){
  echo_color '32m'"${@}"
}


#######################################
# Prints message to the command line interface
#   in blue.
# Arguments:
#   msg
#######################################
echo_blue(){
  echo_color '36m'"${@}"
}


#######################################
# Prints message to the command line interface
#   in red when an error is intened to be raised.
# Arguments:
#   msg
#######################################
exit_error(){
  echo_red "${@}"
  exit 1
}


#######################################
# Logs the command to file, and executes (runs) the command.
# Globals:
#   log
#   err
# Arguments:
#   Command to be logged and performed.
#######################################
run(){
  echo "${@}"
  "${@}" >>${log} 2>>${err}
  if [[ ! ${?} -eq 0 ]]; then
    echo "failed: see log files ${log} ${err} for details"
    exit 1
  fi
  echo "-----------------------"
}


#######################################
# Logs the command to file.
# Globals:
#   log
#   err
# Arguments:
#   Command to be logged and performed.
#######################################
log(){
  echo "${@}"
  # echo "${@}" >>${log} 2>>${err}
  # echo "-----------------------"
}


#######################################
# Uses shell's built-in hash function to check dependency.
# Globals:
#   log
#   err
# Arguments:
#   Dependency to check, e.g. shell command.
# Returns
#   0 if no errors, non-zero on error.
#######################################
dependency_check(){
  if ! hash ${1} 2>/dev/null; then
    exit_error "Dependency ${1} is not installed or added to the system path. Please check. Exiting..."
  fi
}


#######################################
# Checks the dimensions of an input DWI file
# and a corresponding reverse phase encoded 
# sbref/b0.
# Globals:
#   log
#   err
# Arguments:
#   dwi: Input DWI file.
#   b0: Reversed phase encoded b0 (or single band reference).
# Returns
#   0 if no errors, non-zero on error.
#######################################
check_dim(){
  # Parse arguments
  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      --dwi) shift; local dwi=${1} ;;
      --b0) shift; local b0=${1} ;;
      -*) echo_red "$(basename ${0}) | check_dim: Unrecognized option ${1}" >&2; Usage; ;;
      *) break ;;
    esac
    shift
  done
  
  # Set dimension variables
  local x1=$(fslval ${dwi} dim1)
  local y1=$(fslval ${dwi} dim2)
  local z1=$(fslval ${dwi} dim3)

  local x2=$(fslval ${b0} dim1)
  local y2=$(fslval ${b0} dim2)
  local z2=$(fslval ${b0} dim3)

  # Check dimensions
  [[ ${x1} -ne ${x2} ]] && log "ERROR | check_dim: Input DWI and sbref are of different dimensions - DWI x: ${x1} rpe_sbref x: ${x2}" && exit_error "ERROR | check_dim: Input DWI and sbref are of different dimensions - DWI x: ${x1} rpe_sbref x: ${x2}"
  [[ ${y1} -ne ${y2} ]] && log "ERROR | check_dim: Input DWI and sbref are of different dimensions - DWI y: ${y1} rpe_sbref y: ${y2}" && exit_error "ERROR | check_dim: Input DWI and sbref are of different dimensions - DWI y: ${y1} rpe_sbref y: ${y2}"
  [[ ${z1} -ne ${z2} ]] && log "ERROR | check_dim: Input DWI and sbref are of different dimensions - DWI z: ${z1} rpe_sbref z: ${z2}" && exit_error "ERROR | check_dim: Input DWI and sbref are of different dimensions - DWI z: ${z1} rpe_sbref z: ${z2}"
}


#######################################
# Writes the index file for use with FSL's
# topup, and eddy. 
# 
# NOTE: This function assumes uniform phase-encoding
#   for the DWI/dMRI. The output index file is just 
#   a sequence 1's.
# Required Arguments:
#   dwi: Input DWI file.
#   out-idx: Slice phase encoding index.
# Returns
#   0 if no errors, non-zero on error.
#######################################
write_idx(){
  # Parse arguments
  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      --dwi) shift; local dwi=${1} ;;
      --out-idx) shift; local out_idx=${1} ;;
      -*) echo_red "$(basename ${0}) | write_idx: Unrecognized option ${1}" >&2; Usage; ;;
      *) break ;;
    esac
    shift
  done

  # Number of volumes/dynamics
  nvols=( $( echo $(seq 1 1 $(fslval ${dwi} dim4)) ) )

  log "LOG | write_idx: Writing DWI/dMRI index file. NOTE: this assumes uniform phase encoding in the dMRI."

  for i in ${nvols[@]}; do
    echo "1" >> "${out_idx}"
  done
}


#######################################
# Imports relevant information such as slice
# order, phase encoding index, and acquisition
# parameters.
# Globals:
#   log
#   err
# Required Arguments:
#   slspec: Slice order specification file.
#   acqp: Acquisition parameter file.
#   out-slspec: Output filename of the slice order specification file.
#   out-acqp: Output filename of the acquisition parameter file.
# Optional Arguments:
#   idx: Slice phase encoding index.
#   out-idx: Output filename of the slice phase encoding index.
#   dwi: Input DWI file.
# Returns
#   0 if no errors, non-zero on error.
#######################################
import_info(){
  # Set defaults
  local idx=""
  local dwi=""

  # Parse arguments
  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      --slspec) shift; local slspec=${1} ;;
      --idx) shift; local idx=${1} ;;
      --acqp) shift; local acqp=${1} ;;
      --dwi) shift; local dwi=${1} ;;
      --out-slspec) shift; local out_slspec=${1} ;;
      --out-idx) shift; local out_idx=${1} ;;
      --out-acqp) shift; local out_acqp=${1} ;;
      -*) echo_red "$(basename ${0}) | import_info: Unrecognized option ${1}" >&2; Usage; ;;
      *) break ;;
    esac
    shift
  done

  if [[ ! -f ${idx} ]] && [[ -f ${dwi} ]] && [[ ! -z ${out_idx} ]]; then
    run write_idx --dwi ${dwi} --out-idx ${out_idx}
    idx=${out_idx}
  else
    run cp ${idx} ${out_idx}
  fi

  # Check input arguments
  [[ -z ${slspec} ]] || [[ ! -f ${slspec} ]] && log "ERROR | import_info: Slice specification order file required." && exit_error "ERROR | import_info: Slice specification order file required."
  [[ -z ${idx} ]] || [[ ! -f ${idx} ]] && log "ERROR | import_info: Slice index file required." && exit_error "ERROR | import_info: Slice index file required."
  [[ -z ${acqp} ]] || [[ ! -f ${acqp} ]] && log "ERROR | import_info: Acquisition parameters file required." && exit_error "ERROR | import_info: Acquisition parameters file required."

  [[ -z ${out_slspec} ]] && log "ERROR | import_info: Slice specification order output filename required." && exit_error "ERROR | import_info: Slice specification order output filename required."
  [[ -z ${out_idx} ]] && log "ERROR | import_info: Slice index output filename required." && exit_error "ERROR | import_info: Slice index output filename required."
  [[ -z ${out_acqp} ]] && log "ERROR | import_info: Acquisition parameters output filename required." && exit_error "ERROR | import_info: Acquisition parameters output filename required."

  # Import info
  run cp ${slspec} ${out_slspec}
  run cp ${acqp} ${out_acqp}
}


#######################################
# Extracts and merges b0s in a dMRI volume.
# Globals:
#   log
#   err
# Required Arguments:
#   d, dwi: Input DWI file.
#   b, bval: Corresponding bval file.
#   e, bvec: Corresponding bvec file.
#   o, out: Output file name.
# Returns
#   0 if no errors, non-zero on error.
#######################################
extract_b0(){
  # Parse arguments
  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      -d|--dwi) shift; local dwi=${1} ;;
      -b|--bval) shift; local bval=${1} ;;
      -e|--bvec) shift; local bvec=${1} ;;
      -o|--out) shift; local out=${1} ;;
      -*) echo_red "$(basename ${0}) | extract_b0: Unrecognized option ${1}" >&2; Usage; ;;
      *) break ;;
    esac
    shift
  done

  # Create tmp dir
  cwd=${PWD}
  tmp_dir=$(remove_ext ${out})_tmp_${RANDOM}
  run mkdir -p ${tmp_dir}
  run cd ${tmp_dir}

  # Create mif file
  run mrconvert -fslgrad ${bvec} ${bval} ${dwi} dwi.mif

  # Extract b0s
  run dwiextract -bzero dwi.mif dwi.b0.nii.gz

  # Merge b0s
  run fslmaths dwi.b0.nii.gz -Tmean ${out}

  # Clean-up
  cd ${cwd}
  rm -rf ${tmp_dir}
}


#######################################
# Imports relevant data and information needed
# for diffusion weighted image (DWI) preprocessing.
# Globals:
#   log
#   err
# Required Arguments:
#   d, dwi: Input DWI file.
#   b, bval: Corresponding bval file.
#   e, bvec: Corresponding bvec file.
#   b0: Reversed phase encoded b0 (or single band reference).
# Optional Arguments:
#   data-dir: Output parent data directory.
#   slspec: Slice order specification file.
#   idx: Slice phase encoding index.
#   acqp: Acquisition parameter file.
#   dwi-json: DWI JSON file that contains MR associated information.
#   b0-json:  Reversed phase encoded b0/sbref JSON file that contains MR associated information.
# Returns
#   0 if no errors, non-zero on error.
#######################################
import_data(){
  # Set defaults
  local dwi_json=""
  local b0_json=""

  # Parse arguments
  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      -d|--dwi) shift; local dwi=${1} ;;
      -b|--bval) shift; local bval=${1} ;;
      -e|--bvec) shift; local bvec=${1} ;;
      -b0|--b0) shift; local b0=${1} ;;
      --slspec) shift; local slspec=${1} ;;
      --idx) shift; local idx=${1} ;;
      --acqp) shift; local acqp=${1} ;;
      --dwi-json) shift; local dwi_json=${1} ;;
      --b0-json) shift; local b0_json=${1} ;;
      --data-dir) shift; local data_dir=${1} ;;
      -*) echo_red "$(basename ${0}) | import_data: Unrecognized option ${1}" >&2; Usage; ;;
      *) break ;;
    esac
    shift
  done

  # Local variable info
  local sub_id=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $1}' | sed "s@sub-@@g")
  local run_id=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $4}' | sed "s@run-@@g")
  local dwi_PE=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $3}' | sed "s@dir-@@g")
  local bshell=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $2}' | sed "s@acq-@@g")
  local outdir=${data_dir}/sub-${sub_id}/${bshell}/run-${run_id}

  # Check (required) input arguments
  if [[ -z ${data_dir} ]]; then
    log "ERROR | import_data: Output data directory was not specified."
    exit_error "ERROR | import_data: Output data directory was not specified."
  fi

  if [[ -z ${dwi} ]] || [[ ! -f ${dwi} ]]; then
    log "ERROR | import_data: Input DWI file was not specified or does not exist."
    exit_error "ERROR | import_data: Input DWI file was not specified or does not exist."
  else
    local dwi=$(realpath ${dwi})
  fi

  if [[ -z ${bval} ]] || [[ ! -f ${bval} ]]; then
    log "ERROR | import_data: Input bval file was not specified or does not exist."
    exit_error "ERROR | import_data: Input bval file was not specified or does not exist."
  else
    local bval=$(realpath ${bval})
  fi

  if [[ -z ${bvec} ]] || [[ ! -f ${bvec} ]]; then
    log "ERROR | import_data: Input bvec file was not specified or does not exist."
    exit_error "ERROR | import_data: Input bvec file was not specified or does not exist."
  else
    local bvec=$(realpath ${bvec})
  fi

  if [[ -z ${b0} ]] || [[ ! -f ${b0} ]]; then
    log "ERROR | import_data: Input reversed phase (rPE) b0 file was not specified or does not exist."
    exit_error "ERROR | import_data: Input reversed phase (rPE) b0 file was not specified or does not exist."
  else
    local b0=$(realpath ${b0})
  fi

  # Check (optional) arguments
  if [[ ! -z ${dwi_json} ]]; then 
    if [[ -f ${dwi_json} ]]; then
      local dwi_json=$(realpath ${dwi_json})
    else
      log "ERROR | import_data: DWI JSON file specified, but it does not exist."
      exit_error "ERROR | import_data: DWI JSON file specified, but it does not exist."
    fi
  fi

  if [[ ! -z ${b0_json} ]]; then 
    if [[ -f ${b0_json} ]]; then
      local b0_json=$(realpath ${b0_json})
    else
      log "ERROR | import_data: Reversed phase (rPE) b0 JSON file specified, but it does not exist."
      exit_error "ERROR | import_data: Reversed phase (rPE) b0 JSON file specified, but it does not exist."
    fi
  fi

  # Declare global variables
  local log_dir=${outdir}/logs
  log=${log_dir}/dwi.log
  err=${log_dir}/dwi.err

  # Import data
  if [[ ! -d ${outdir}/import ]]; then
    mkdir -p ${log_dir}
    run mkdir -p ${outdir}/import
  fi

  check_dim --dwi ${dwi} --b0 ${b0}

  run import_info --out-slspec ${outdir}/import/dwi.slice_order --out-acqp ${outdir}/import/dwi.params.acqp --dwi ${dwi} --out-idx ${outdir}/import/dwi.idx --slspec ${slspec} --idx ${idx} --acqp ${acqp}
  run extract_b0 --dwi ${dwi} --bval ${bval} --bvec ${bvec} --out ${outdir}/import/sbref_pa.nii.gz

  run imcp ${dwi} ${outdir}/import/dwi &
  run imcp ${b0} ${outdir}/import/sbref_ap &
  run cp ${dwi} ${outdir}/import/dwi.bval
  run cp ${dwi} ${outdir}/import/dwi.bvec

  [[ ! -z ${dwi_json} ]] && run cp ${dwi_json} ${outdir}/import/dwi.json
  [[ ! -z ${b0_json} ]] && run cp ${b0_json} ${outdir}/import/sbref_ap.json

  wait

  echo "${outdir}"
}


N4(){
  N4BiasFieldCorrection "${@}"
}


# TODO: 
#   1. Topup
#   2. Eddy
#   3. Post-process (DTI-FIT)



main(){
  # Main function

  # Check args

  # # TEST ARGS (LOCAL MAC OS)
  # local dwi=/Users/adebayobraimah/Desktop/projects/dwi_preproc/test_data/sub-144/sub-144_acq-b800_dir-PA_run-01_dwi.nii.gz
  # local bval=/Users/adebayobraimah/Desktop/projects/dwi_preproc/test_data/sub-144/sub-144_acq-b800_dir-PA_run-01_dwi.bval
  # local bvec=/Users/adebayobraimah/Desktop/projects/dwi_preproc/test_data/sub-144/sub-144_acq-b800_dir-PA_run-01_dwi.bvec
  # local sbref=/Users/adebayobraimah/Desktop/projects/dwi_preproc/test_data/sub-144/sub-144_acq-b0TE88_dir-AP_run-01_sbref.nii.gz
  # local outdir=/Users/adebayobraimah/Desktop/projects/dwi_preproc/test_data/test_proc

  # TEST ARGS (LOCAL CENTOS)
  local dwi=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b800_dir-PA_run-01_dwi.nii.gz
  local bval=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b800_dir-PA_run-01_dwi.bval
  local bvec=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b800_dir-PA_run-01_dwi.bvec
  local sbref=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b0TE88_dir-AP_run-01_sbref.nii.gz

  local dwi_json=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b800_dir-PA_run-01_dwi.json
  local sbref_json=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b0TE88_dir-AP_run-01_sbref.json

  local outdir=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/code/dwi_preproc/test_data/test_proc

  local slice_order=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/code/dwi_preproc/misc/b800/dwi.b800.slice_order
  local params=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/code/dwi_preproc/misc/b800/dwi.params.b800.acq

  # # Load modules
  # module load fsl/6.0.4
  # module load ants/2.3.1
  # 
  # # Add MRtrix3 SS3T to PATH
  # export PATH=${PATH}:~/bin/MRtrix/MRtrixSS3T/MRtrix3Tissue_linux/bin

  # Check dependencies
  local deps=( topup eddy N4 )

  for dep in ${deps[@]}; do
    dependency_check ${dep}
  done

  import_data \
  --dwi ${dwi} \
  --bval ${bval} \
  --bvec ${bvec} \
  --b0 ${sbref} \
  --data-dir ${outdir} \
  --acqp ${params} \
  --slspec ${slice_order} \
  --dwi-json ${dwi_json} \
  --b0-json ${sbref_json}

  log "END"
}

main "${@}"

# made changes
