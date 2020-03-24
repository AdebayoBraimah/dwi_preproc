#!/usr/bin/env bash

# CCHMC LSF HPC job submission wrapper script
# for IRC317H_NAS (BIDS).
# Performing DWI preproc with slice-to-volume 
# motion correction using GPUs.

# Test shell
# bsub -W 800 -M 16000 -q gpu-nodes -R "span[hosts=1]" -R "rusage[gpu=1]" -n 4 -Is bash
# scripts_dir=/scratch/brac4g/IRC317H/BIDS/scripts/dwi_preproc

# load modules
module load fsl/6.0.3
module load cuda/9.1
module load anaconda3/1.0.0

# source /usr/local/fsl/6.0.3/fslpython/envs/fslpython
# source /usr/local/fsl/6.0.3/fslpython/bin/activate

# module load python/2.7.15
# module load python3/3.6.0
# module load python3/3.7.1

# /usr/local/python/3.7.1/bin/python

# export PATH=/usr/local/python/3.7.1/bin/python:${PATH}

# module load cuda/8.0

# constant vars
scripts_dir=$(dirname $(realpath ${0}))
source=/scratch/brac4g/IRC317H/BIDS/rawdata.dwi

# b800 files
in_800_b0=${scripts_dir}/misc.info/dwi.data.info/b800_b0.list.txt 
in_800=${scripts_dir}/misc.info/dwi.data.info/b800.list.txt 
data_800=/scratch/brac4g/IRC317H/BIDS/derivatives/dwi_preproc.s2v/b800.preproc

# b2000 files
in_2000_b0=${scripts_dir}/misc.info/dwi.data.info/b2000_b0.list.txt 
in_2000=${scripts_dir}/misc.info/dwi.data.info/b2000.list.txt 
data_2000=/scratch/brac4g/IRC317H/BIDS/derivatives/dwi_preproc.s2v/b2000.preproc

# args
mporder=2
s2v_niter=5
s2v_lambda=1

wall=1000
mem=10000

# create arrays
mapfile -t dwi_800_b0 < ${in_800_b0}
mapfile -t dwi_800 < ${in_800}

mapfile -t dwi_2000_b0 < ${in_2000_b0}
mapfile -t dwi_2000 < ${in_2000}

# b2000
for ((i=0; i < ${#dwi_2000[@]}; i++)); do
  sub=$(echo $(basename $(dirname $(dirname $(dirname ${dwi_2000[$i]})))) | sed "s@sub-@@g")
  bsub -J ${sub}_2000 -n 1 -W ${wall} -M ${mem} -R "rusage[gpu=1]" -q gpu-nodes ${scripts_dir}/dwi_preproc.sh --dwi ${source}/${dwi_2000[$i]} --B0 ${source}/${dwi_2000_b0[$i]} --BIDS --data-dir ${data_2000} --residuals --repol --cnr_maps --use-gpu --mporder ${mporder} --s2v_niter ${s2v_niter} --s2v_lambda ${s2v_lambda} --tensor --qc --additional # --fig
done

# args
mporder=2
s2v_niter=5
s2v_lambda=1

wall=1000
mem=10000

# b800
for ((i=0; i < ${#dwi_800[@]}; i++)); do
  sub=$(echo $(basename $(dirname $(dirname $(dirname ${dwi_800[$i]})))) | sed "s@sub-@@g")
  bsub -J ${sub}_800 -n 1 -W ${wall} -M ${mem} -R "rusage[gpu=1]" -q gpu-nodes ${scripts_dir}/dwi_preproc.sh --dwi ${source}/${dwi_800[$i]} --B0 ${source}/${dwi_800_b0[$i]} --BIDS --data-dir ${data_800} --residuals --repol --cnr_maps --use-gpu --mporder ${mporder} --s2v_niter ${s2v_niter} --s2v_lambda ${s2v_lambda} --tensor --qc --additional # --fig
done 


