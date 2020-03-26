#!/usr/bin/env bash

# Define logging functions
echo_color(){
  msg='\033[0;'"${@}"'\033[0m'
  # echo -e ${msg} >> ${stdOut} 2>> ${stdErr}
  echo -e ${msg} 
}
echo_red(){
  echo_color '31m'"${@}"
}
echo_green(){
  echo_color '32m'"${@}"
}
echo_blue(){
  echo_color '36m'"${@}"
}

# Define file writing functions
create_figures(){
	# Creates QC images for dMR images.
	# Each output image will have a different
	# suffix appended to its output.
	# 
	# Args
	# 	out_name: output path and name
	# 	dwi: input preprocessed dMR image
	# 	fa: corresponding FA image
	# 	v1: corresponding set of initial eigenvectors
	# 
	# Outpus
	# 	${out_name}_dwi_ortho.png
	# 	${out_name}_dwi_ortho.png ${dwi}
	# 	${out_name}_FA_ortho.png
	# 	${out_name}_FA_lightbox.png

	local out_name=${1}
	local dwi=${2}
	local fa=${3}
	local v1=${4}

	ov1="fsleyes render --scene=ortho -hc -of=${out_name}_FA_ortho.png ${fa} ${v1} -ot rgbvector"   # Overlay with orthongal views
	ov2="fsleyes render --scene=lightbox -hc -of=${out_name}_FA_lightbox.png ${fa} ${v1} -ot rgbvector"  # Overlay with lightbox view

	rg1="fsleyes render --scene=ortho -hc -of=${out_name}_dwi_ortho.png ${dwi}"   # Overlay with orthongal views
	rg2="fsleyes render --scene=lightbox -hc -of=${out_name}_dwi_lightbox.png ${dwi}"  # Overlay with lightbox view

	${ov1} 
	${ov2} 
	${rg1} 
	${rg2} 
}

mkd_sub(){
  # Function that writes subject
  # ID to markdown file

  local mkdwn=${1}
  local sub=${2}

cat <<- mkdwn_sub >> ${mkdwn}
## sub-${sub}                  

mkdwn_sub
}

mkd_link(){
  # Function that writes filepaths
  # of image files to markdown file.

  local mkdwn=${1}
  local pic1=${2}
  local pic2=${3}
  local pic3=${4}
  local pic4=${5}

cat <<- mkdwn_sub >> ${mkdwn}  
![](${pic1})          

![](${pic2})          

![](${pic3})          

![](${pic4})          

mkdwn_sub
}

# Rstudio markdown knit - requires pandoc, R, and Rstudio
renderHTML(){ Rscript -e "library(rmarkdown); rmarkdown::render('${1}','html_document')" ;}

# Define directory variables
echo ""
echo_blue "Setting directory variables"

scripts_dir=$(dirname $(realpath ${0}))
parent_deriv_dir=/Volumes/brac4g/IRC317H/BIDS/derivatives/dwi_preproc.s2v
derivative_dirs=( ${parent_deriv_dir}/b2000.preproc ${parent_deriv_dir}/b800.preproc )
output_dir=${scripts_dir}/dwi.preproc.qc

# Create qc images - iterating through: b-val acqs, and subjects
for derivative_dir in ${derivative_dirs[@]}; do
	# create subject list
	echo ""
	echo_blue "Creating subject list"
	subs=( $(cd ${derivative_dir}/derivatives; ls -d * | sed "s@sub-@@g") )

	# create output variables
	if [[ ${derivative_dir} = *"b2000"* ]]; then
		out_dir=${output_dir}/b2000
		mkdwn=${out_dir}/b2000.md 
		pic_dir=${out_dir}/imgs; mkdir -p ${pic_dir}
		bval=b2000
	else
		out_dir=${output_dir}/b800
		mkdwn=${out_dir}/b800.md 
		pic_dir=${out_dir}/imgs; mkdir -p ${pic_dir}
		bval=b800
	fi

	echo ""
	echo_blue "Processing ${bval} acqs"

	# create qc images for each subject
	for sub in ${subs[@]}; do
		acqs=( $(cd ${derivative_dir}/derivatives/sub-${sub}/*/*; ls -d $(pwd)/*) )
		for acq in ${acqs[@]}; do
			run_num=$(basename ${acq} | sed "s@bval-${bval}_@@g")
			out_name=${pic_dir}/sub-${sub}_${run_num}
			dwi=$(ls ${acq}/*.nii*)
			fa=$(ls ${acq}/Tensor/*FA*.nii*)
			v1=$(ls ${acq}/Tensor/*V1*.nii*)

			if [[ ! -f ${dwi} ]] || [[ ! -f ${fa} ]] || [[ ! -f ${v1} ]]; then
				echo "sub-${sub}_bval-${bval}_${run_num} does not have a complete set of preprocessed dMR image files"
				echo "sub-${sub}_bval-${bval}_${run_num} does not have a complete set of preprocessed dMR image files" >> ${scripts_dir}/err_log.txt
			else
				echo ""
				echo_blue "Processing sub-${sub}_bval-${bval}_${run_num}"
				create_figures ${out_name} ${dwi} ${fa} ${v1}
				qc1=${out_name}_dwi_ortho.png
				qc2=${out_name}_dwi_lightbox.png
				qc3=${out_name}_FA_ortho.png
				qc4=${out_name}_FA_lightbox.png

				mkd_sub ${mkdwn} ${sub}_${run_num}
				mkd_link ${mkdwn} ${qc1} ${qc2} ${qc3} ${qc4}
			fi
		done
	done
	echo ""
	echo_blue "Creating QC webpage for ${bval} acqs"
	renderHTML ${mkdwn}
	echo ""
	echo_green "Finished creating QC images for ${bval} acqs"
done

