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
# scripts_dir=$(echo $(dirname $(realpath ${0})))
scripts_dir=/data/AICAD-HeLab/Data_TeamShare/dHCP_work/EPS.BIDS/EPS/CINEPS/BIDS/code/dwi_preproc
log_base_name=${scripts_dir}/check_data

derivatives=/data/AICAD-HeLab/Data_TeamShare/dHCP_work/EPS.BIDS/EPS/CINEPS/BIDS/derivatives/dwi_preproc

subs=( $(cd ${derivatives}; ls -d sub-* | sed "s@sub-@@g" ) )

for sub in ${subs[@]}; do

  echo "Processing: sub-${sub}"

  shells=( $(cd ${derivatives}/sub-${sub}; ls -d b* ) )

  for shell in ${shells[@]}; do

    runs=( $(cd ${derivatives}/sub-${sub}/${shell}; ls -d run-* ) )

    for run in ${runs[@]}; do

      # Find files interest
      fmap_file=$(realpath ${derivatives}/sub-${sub}/${shell}/${run}/topup/fieldmap.nii.gz)
      eddy_file=$(realpath ${derivatives}/sub-${sub}/${shell}/${run}/eddy/eddy_corrected.nii.gz)
      eddy_qc_file=$(realpath ${derivatives}/sub-${sub}/${shell}/${run}/eddy.qc/qc.json)
      proc_data=$(realpath ${derivatives}/sub-${sub}/${shell}/${run}/preprocessed_data/dwi.nii.gz)
      tract_file=$(realpath ${derivatives}/sub-${sub}/${shell}/${run}/tractography/AAL/dwi.100000.streamlines.tck)

      if [[ ! -f ${fmap_file} ]]; then
        echo "sub-${sub} | ${shell} | ${run} does not have fieldmap data." >> ${log_base_name}.fmap.log
      fi

      if [[ ! -f ${eddy_file} ]]; then
        echo "sub-${sub} | ${shell} | ${run} does not have EDDY preprocessed data." >> ${log_base_name}.eddy.log
      fi

      if [[ ! -f ${eddy_qc_file} ]]; then
        echo "sub-${sub} | ${shell} | ${run} does not have EDDY QCed data." >> ${log_base_name}.qc.log
      fi

      if [[ ! -f ${proc_data} ]]; then
        echo "sub-${sub} | ${shell} | ${run} does not have fully preprocessed data." >> ${log_base_name}.preproc.log
      fi

      if [[ ! -f ${tract_file} ]]; then
        echo "sub-${sub} | ${shell} | ${run} does not have tractography data." >> ${log_base_name}.tract.log
      fi
    done
  done
done
