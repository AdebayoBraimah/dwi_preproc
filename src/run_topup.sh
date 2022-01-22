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
  
  Performs dMR image distortion estimation of 4D reverse phase-encoded b0s.

  Required arguments
    -p, --phase                     4D reverse phase-encoded b0s.
    -a, --acqp                      Acquisition parameter file.
    --out-dir                       Parent output directory.
  
  Optional arguments
    -c, --config                    Topup configuration file.
    -h, -help, --help               Prints the help menu, then exits.

USAGE
  exit 1
}


# SCRIPT MAIN BODY

# Set defaults
config=${scripts_dir}/../misc/b02b0.cnf

# Parse arguments
[[ ${#} -eq 0 ]] && Usage;
while [[ ${#} -gt 0 ]]; do
  case "${1}" in
    -p|--phase) shift; phase=${1} ;;
    -a|--acqp) shift; acqp=${1} ;;
    -c|--config) shift; config=${1} ;;
    --out-dir) shift; outdir=${1} ;;
    -*) echo_red "$(basename ${0}): Unrecognized option ${1}" >&2; Usage; ;;
    *) break ;;
  esac
  shift
done

# Log variabes
log_dir=${outdir}/logs
log=${log_dir}/dwi.log
err=${log_dir}/dwi.err

# Topup output dir
cwd=${PWD}
topup_dir=${outdir}/topup
if [[ ! -d ${topup_dir} ]]; then 
  run mkdir -p ${topup_dir}

  cd ${topup_dir}

  run imcp ${phase} phase && phase=${PWD}/phase
  run cp ${acqp} params.acqp && acqp=params.acqp

  log "START: TOPUP"

  # Run topup
  run topup --imain=${phase} --datain=${acqp} --config=${config} --fout=${topup_dir}/fieldmap --iout=${topup_dir}/topup_b0s --out=${topup_dir}/topup_results -v

  # Run BET on topup output
  run fslmaths ${topup_dir}/topup_b0s -Tmean ${topup_dir}/topup_hifib0
  run bet ${topup_dir}/topup_hifib0 ${topup_dir}/nodif_brain -m -f 0.25 -R

  cd ${cwd}
  
  log "END: TOPUP"
fi
