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


# TODO:
#   * Separate major functions into different scripts
#     * Reference these scripts from this main script


# Workflow: 
#   1. Topup
#   2. Eddy
#   3. Post-process (DTI-FIT)
#   4. Tractography



# SCRIPT BODY

# Check args

# # TEST ARGS (LOCAL MAC OS)
# local dwi=/Users/adebayobraimah/Desktop/projects/dwi_preproc/test_data/sub-144/sub-144_acq-b800_dir-PA_run-01_dwi.nii.gz
# local bval=/Users/adebayobraimah/Desktop/projects/dwi_preproc/test_data/sub-144/sub-144_acq-b800_dir-PA_run-01_dwi.bval
# local bvec=/Users/adebayobraimah/Desktop/projects/dwi_preproc/test_data/sub-144/sub-144_acq-b800_dir-PA_run-01_dwi.bvec
# local sbref=/Users/adebayobraimah/Desktop/projects/dwi_preproc/test_data/sub-144/sub-144_acq-b0TE88_dir-AP_run-01_sbref.nii.gz
# local outdir=/Users/adebayobraimah/Desktop/projects/dwi_preproc/test_data/test_proc

# TEST ARGS (LOCAL CENTOS)
dwi=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b800_dir-PA_run-01_dwi.nii.gz
bval=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b800_dir-PA_run-01_dwi.bval
bvec=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b800_dir-PA_run-01_dwi.bvec
sbref=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b0TE88_dir-AP_run-01_sbref.nii.gz

dwi_json=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b800_dir-PA_run-01_dwi.json
sbref_json=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-144/dwi/sub-144_acq-b0TE88_dir-AP_run-01_sbref.json

data_dir=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/code/dwi_preproc/test_data/test_proc

slice_order=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/code/dwi_preproc/misc/b800/dwi.b800.slice_order
params=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/code/dwi_preproc/misc/b800/dwi.params.b800.acq

# Load modules
module load anaconda3/1.0.0
module load fsl/6.0.4
module load cuda/9.1

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${FSLDIR}/fslpython/envs/fslpython/lib

# module load ants/2.3.1

# Add MRtrix3 SS3T to PATH
export PATH=${PATH}:~/bin/MRtrix/MRtrixSS3T/MRtrix3Tissue_linux/bin

# Check dependencies
deps=( topup eddy mrconvert dwiextract ss3t_csd_beta1 )

for dep in ${deps[@]}; do
  dependency_check ${dep}
done

# variable info
sub_id=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $1}' | sed "s@sub-@@g")
run_id=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $4}' | sed "s@run-@@g")
dwi_PE=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $3}' | sed "s@dir-@@g")
bshell=$(echo $(remove_ext $(basename ${dwi})) | sed "s@_@ @g" | awk '{print $2}' | sed "s@acq-@@g")

outdir=${data_dir}/sub-${sub_id}/${bshell}/run-${run_id}
topup_dir=${outdir}/topup
eddy_dir=${outdir}/eddy 

log_dir=${outdir}/logs
log=${log_dir}/dwi.log
err=${log_dir}/dwi.err


${scripts_dir}/src/import.sh --b0 ${sbref} --dwi ${dwi} --bval ${bval} --bvec ${bvec} --data-dir ${data_dir} --acqp ${params} --slspec ${slice_order} --dwi-json ${dwi_json} --b0-json ${sbref_json}
${scripts_dir}/src/run_topup.sh --phase ${outdir}/import/phase --acqp ${outdir}/import/dwi.params.acqp --out-dir ${outdir}
${scripts_dir}/src/run_eddy.sh --dwi ${dwi} --bval ${bval} --bvec ${bvec} --outdir ${outdir} --acqp ${outdir}/import/dwi.params.acqp --slspec ${outdir}/import/dwi.slice_order --topup-dir ${topup_dir}

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

log "END"

# job submission command
# bsub -n 1 -R "span[hosts=1]" -q gpu-v100 -gpu "num=1" -M 20000 -W 8000 ./dwi_preproc.sh
