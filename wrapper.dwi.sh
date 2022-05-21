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

# job submission command
# bsub -n 1 -R "span[hosts=1]" -q gpu-v100 -gpu "num=1" -M 20000 -W 8000 ./dwi_preproc.sh

# Load modules
module load anaconda3/1.0.0
module load fsl/6.0.4
module load cuda/9.1

# Append/modify PATH variable
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${FSLDIR}/fslpython/envs/fslpython/lib
export PATH=${PATH}:~/bin/MRtrix/MRtrixSS3T/MRtrix3Tissue_linux/bin
export PYTHONPATH=${PYTHONPATH}:$(which python3):$(which python2)

# scripts_dir=$(echo $(dirname $(realpath ${0})))
scripts_dir=/data/AICAD-HeLab/Data_TeamShare/dHCP_work/EPS.BIDS/EPS/CINEPS/BIDS/code/dwi_preproc
struct_dir=/data/AICAD-HeLab/Data_TeamShare/dHCP_work/CINEPS/t2_work/struc_processed/derivatives_corrected
rawdata=/data/AICAD-HeLab/Data_TeamShare/dHCP_work/EPS.BIDS/EPS/CINEPS/BIDS/rawdata
derivatives=/data/AICAD-HeLab/Data_TeamShare/dHCP_work/EPS.BIDS/EPS/CINEPS/BIDS/derivatives


# Template variables
## AAL
aal_template=$(realpath ../fmri_preproc/fmri_preproc_jobs/fmri_preproc/fmri_preproc/resources/atlases/UNC_infant_atlas_2020/atlas/templates/infant-neo-withSkull.nii.gz)
aal_template_brain=$(realpath ../fmri_preproc/fmri_preproc_jobs/fmri_preproc/fmri_preproc/resources/atlases/UNC_infant_atlas_2020/atlas/templates/infant-neo-withCerebellum.nii.gz)
aal_labels=$(realpath ../fmri_preproc/fmri_preproc_jobs/fmri_preproc/fmri_preproc/resources/atlases/UNC_infant_atlas_2020/atlas/templates/infant-neo-aal.nii.gz)

# mporder=8
mporder=""

shells=( 800 2000 )
TEs=( 88 93 )
subs=( $(cd ${rawdata}; ls -d sub-* | sed "s@sub-@@g" ) )
factors=( 4 8 )

# output_dir=${scripts_dir}/test_data/test_proc
# rm -rf ${output_dir}
output_dir=${derivatives}/dwi_preproc

# Test code
for sub in ${subs[@]}; do
  for (( i=0; i < ${#shells[@]}; i++ )); do
    # Gather files
    dwis=( $(realpath ${rawdata}/sub-${sub}/dwi/sub-*_acq-b${shells[$i]}_dir-PA_run-*_dwi.nii.gz) )

    for dwi in ${dwis[@]}; do
      bval=$(remove_ext ${dwi}).bval
      bvec=$(remove_ext ${dwi}).bvec
      json=$(remove_ext ${dwi}).json
      sbref=$(realpath ${rawdata}/sub-${sub}/dwi/sub-*_acq-*${TEs[$i]}_dir-*_run-01_sbref.nii.gz)

      if [[ -f ${dwi} ]] && [[ -f ${bval} ]] && [[ -f ${bvec} ]] && [[ -f ${sbref} ]]; then
        # slspec=${scripts_dir}/misc/b${shells[$i]}/*.slice_order
        # acqp=${scripts_dir}/misc/b${shells[$i]}/*.acq*

        # Tractography test files
        ## dHCP (use single subject files)
        template=$(realpath ${struct_dir}/sub-${sub}/ses-*/anat/*T2w_restore.nii.*)
        template_brain=$(realpath ${struct_dir}/sub-${sub}/ses-*/anat/*T2w_restore_brain.nii.*)
        labels=$(realpath ${struct_dir}/sub-${sub}/ses-*/anat/*drawem_all_labels.nii.*)
        cmd=""

        if [[ -f ${template} ]] && [[ -f ${template_brain} ]] && [[ -f ${labels} ]]; then
          cmd="--template ${template} --template-brain ${template_brain} --labels ${labels} --out-tract dHCP_40wk"
        fi
        
        # bsub -J ${sub}_${shells[$i]} -n 1 -R "span[hosts=1]" -M 25000 -W 10000 \
        bsub -J ${sub}_${shells[$i]} -n 1 -R "span[hosts=1]" -q gpu-v100 -gpu "num=1" -M 25000 -W 10000 \
        ${scripts_dir}/dwi_preproc.sh \
        --dwi ${dwi} \
        --bval ${bval} \
        --bvec ${bvec} \
        --sbref ${sbref} \
        --dwi-json ${json} \
        --data-dir ${output_dir} \
        --mporder ${mporder} \
        --template ${aal_template} --template-brain ${aal_template_brain} \
        --labels ${aal_labels} --out-tract AAL ${cmd}
        # --slspec ${slspec} \
        # --acqp ${acqp} \
        # echo "bsub -J ${sub}_${shells[$i]} -n 1 -R "span[hosts=1]" -q gpu-v100 -gpu "num=1" -M 20000 -W 8000 ${scripts_dir}/dwi_preproc.sh --dwi ${dwi} --bval ${bval} --bvec ${bvec} --sbref ${sbref} --dwi-json ${json} --slspec ${slspec} --acqp ${acqp} --data-dir ${output_dir} --template ${aal_template} --template-brain ${aal_template_brain} --labels ${aal_labels} --out-tract AAL ${cmd}" >> test.file.sh
      fi
    done
  done
done


# #################################
# # Clean-up (and census) code    #
# #################################
# 
# derivatives=/data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/derivatives
# output_dir=${derivatives}/dwi_preproc
# 
# subs=( $(cd ${output_dir}; ls -d sub-* | sed "s@sub-@@g" ) )
# shells=( 800 2000 )
# runs=( 01 02 )
# 
# echo ""
# 
# for sub in ${subs[@]}; do
#   for shell in ${shells[@]}; do
#     for run in ${runs[@]}; do
#       # file=${output_dir}/sub-${sub}/b${shell}/run-${run}/eddy/hifib0.nii.gz
#       file=${output_dir}/sub-${sub}/b${shell}/run-${run}/eddy/eddy_corrected.eddy_mbs_first_order_fields.nii.gz # Use this file to check if eddy mbs and s2v were performed
#       eddy_dir=${output_dir}/sub-${sub}/b${shell}/run-${run}/eddy
# 
#       tck_aal=${output_dir}/sub-${sub}/b${shell}/run-${run}/tractography/AAL/dwi.100000.streamlines.tck
#       tck_dhcp=${output_dir}/sub-${sub}/b${shell}/run-${run}/tractography/dHCP_40wk/dwi.100000.streamlines.tck
#       tck_dir=${output_dir}/sub-${sub}/b${shell}/run-${run}/tractography
# 
#       echo "Processing: sub-${sub}"
# 
#       if [[ ! -f ${file} ]] && [[ -d ${eddy_dir} ]]; then
#         # rm -rf ${eddy_dir}
#         # echo "rm -rf ${eddy_dir}" >> test.file.sh
#         echo "sub-${sub} | b${shell} | run-${run}: Did not undergo s2v motion correction due to GPU memory issue." >> preproc.b${shell}.eddy.log
#       fi
#       if [[ -f ${tck_aal} ]] && [[ -d ${tck_dir} ]]; then
#         echo "sub-${sub} | b${shell} | run-${run}: Has AAL tractography data" >> preproc.b${shell}.aal_tract.log
#       elif [[ ! -f ${tck_aal} ]] && [[ -d ${tck_dir} ]]; then
#         echo "sub-${sub} | b${shell} | run-${run}: Did not undergo AAL tractography" >> preproc.b${shell}.no_aal_tract.log
#       fi
#       if [[ -f ${tck_dhcp} ]] && [[ -d ${tck_dir} ]]; then
#         echo "sub-${sub} | b${shell} | run-${run}: Has dHCP tractography data" >> preproc.b${shell}.dchp_tract.log
#       elif [[ ! -f ${tck_dhcp} ]] && [[ -d ${tck_dir} ]]; then
#         echo "sub-${sub} | b${shell} | run-${run}: Did not undergo dHCP tractography." >> preproc.b${shell}.no_dhcp_tract.log
#       fi
#     done
#   done
# done
