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

scripts_dir=$(echo $(dirname $(realpath ${0})))

shells=( 800 2000 )
TEs=( 88 93 )
sub=186

output_dir=${scripts_dir}/test_data/test_proc
# rm -rf ${output_dir}

# Test code
for (( i=0; i < ${#shells[@]}; i++ )); do
  # Gather files
  dwi=$(realpath /data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-${sub}/dwi/sub-*_acq-b${shells[$i]}_dir-PA_run-01_dwi.nii.gz)
  bval=$(remove_ext ${dwi}).bval
  bvec=$(remove_ext ${dwi}).bvec
  json=$(remove_ext ${dwi}).json
  sbref=$(realpath /data/AICAD-HeLab/tmp/tmp.eps/EPS/CINEPS/BIDS/rawdata/sub-${sub}/dwi/sub-*_acq-*${TEs[$i]}_dir-*_run-01_sbref.nii.gz)

  slspec=${scripts_dir}/misc/b${shells[$1]}/*.slice_order
  acqp=${scripts_dir}/misc/b${shells[$1]}/*.acq*

  # Tractography test files
  ## AAL
  aal_template=$(realpath ../fmri_preproc/fmri_preproc_jobs/fmri_preproc/fmri_preproc/resources/atlases/UNC_infant_atlas_2020/atlas/templates/infant-neo-withSkull.nii.gz)
  aal_template_brain=$(realpath ../fmri_preproc/fmri_preproc_jobs/fmri_preproc/fmri_preproc/resources/atlases/UNC_infant_atlas_2020/atlas/templates/infant-neo-withCerebellum.nii.gz)
  aal_labels=$(realpath ../fmri_preproc/fmri_preproc_jobs/fmri_preproc/fmri_preproc/resources/atlases/UNC_infant_atlas_2020/atlas/templates/infant-neo-aal.nii.gz)

  ## dHCP (use single subject files)
  struct_dir=/data/AICAD-HeLab/Data_TeamShare/dHCP_work/CINEPS/t2_work/struc_processed/derivatives_corrected
  template=$(realpath ${struct_dir}/sub-${sub}/ses-*/anat/*T2w_restore.nii.*)
  template_brain=$(realpath ${struct_dir}/sub-${sub}/ses-*/anat/*T2w_restore_brain.nii.*)
  labels=$(realpath ${struct_dir}/sub-${sub}/ses-*/anat/*drawem_all_labels.nii.*)

  bsub -n 1 -R "span[hosts=1]" -q gpu-v100 -gpu "num=1" -M 20000 -W 8000 \
  ${scripts_dir}/dwi_preproc.sh \
  --dwi ${dwi} \
  --bval ${bval} \
  --bvec ${bvec} \
  --sbref ${sbref} \
  --dwi-json ${json} \
  --slspec ${slspec} \
  --acqp ${acqp} \
  --data-dir ${output_dir} \
  --template ${aal_template} --template-brain ${aal_template_brain} --labels ${aal_labels} --out-tract AAL \
  --template ${template} --template-brain ${template_brain} --labels ${labels} --out-tract dHCP_40wk
done


