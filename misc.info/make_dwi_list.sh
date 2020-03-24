#!/usr/bin/env bash

# Define functions
mkImg(){
  # Creates/Renders PNG file from 
  # Nifti Image.

  local niiFile=${1}
  local outFile=${2}

  local niiFile=$(realpath ${niiFile})
  local outFile=$(realpath ${outFile})

  fsleyes render --scene=ortho -hc -of=${outFile} ${niiFile}
}

mkdsub(){

  # Function that writes subject
  # ID to markdown file

  local mkdwn=${1}
  local sub=${2}

cat <<- mkdwn_sub >> ${mkdwn}
## sub-${sub}                  

mkdwn_sub
}

mkdLink(){

  # Function that writes filepaths
  # to markdown file.

  local mkdwn=${1}
  local pic1=${2}

cat <<- mkdwn_sub >> ${mkdwn}  
![](${pic1})          

mkdwn_sub
}

renderHTML(){ Rscript -e "library(rmarkdown); rmarkdown::render('${1}','html_document')" ;}

# Directory variables
scripts_dir=$(dirname $(realpath ${0}))/dwi.data.info
source=/Volumes/brac4g/IRC317H/BIDS/rawdata.dwi
pic_dir=${scripts_dir}/b0.qc.pics

mkdwn_800=${scripts_dir}/b0_b800_qc.md
mkdwn_2000=${scripts_dir}/b0_b2000_qc.md

# Output list variables
out_800=${scripts_dir}/b800.list.txt
out_800_b0=${scripts_dir}/b800_b0.list.txt

out_2000=${scripts_dir}/b2000.list.txt
out_2000_b0=${scripts_dir}/b2000_b0.list.txt

missing_data=${scripts_dir}/data.missing.txt

# Make subject lists
subs=( $(cd ${source}; ls -d sub-*) )

if [[ ! -d ${pic_dir} ]]; then
  mkdir -p ${pic_dir}
fi

echo ""

for sub in ${subs[@]}; do
	echo "Processing: ${sub}"
	# b800 acquisitions
	dwi_b800=( $(cd ${source}; ls *${sub}*/ses-*/*dwi*/*b800*.nii*) )
	dwi_b800_b0=( $(cd ${source}; ls *${sub}*/ses-*/*dwi*/*006*b0*.nii* | sort) )

	if [[ ${#dwi_b800[@]} -gt 0 ]]; then
		for dwi in ${dwi_b800[@]}; do
			echo ${dwi} >> ${out_800}
			echo ${dwi_b800_b0[-1]} >> ${out_800_b0}
		done
		# Make QC figures and write to file
		mkdsub ${mkdwn_800} ${sub}
		mkImg ${source}/${dwi_b800_b0[-1]} ${pic_dir}/${sub}_ses-001_acq-b0b800.png
		mkdLink ${mkdwn_800} ${pic_dir}/${sub}_ses-001_acq-b0b800.png
	else
		echo "${sub} is missing b800 acquisitions" >> ${missing_data}
	fi

	# b2000 acquisitions
	dwi_b2000=( $(cd ${source}; ls *${sub}*/ses-*/*dwi*/*b2000*.nii*) )
	dwi_b2000_b0=( $(cd ${source}; ls *${sub}*/ses-*/*dwi*/*007*b0*.nii* | sort) )

	if [[ ${#dwi_b2000[@]} -gt 0 ]];then
		for dwi in ${dwi_b2000[@]}; do
			echo ${dwi} >> ${out_2000}
			echo ${dwi_b2000_b0[-1]} >> ${out_2000_b0}
		done
		# Make QC figures and write to file
		mkdsub ${mkdwn_2000} ${sub}
		mkImg ${source}/${dwi_b2000_b0[-1]} ${pic_dir}/${sub}_ses-001_acq-b0b2000.png
		mkdLink ${mkdwn_2000} ${pic_dir}/${sub}_ses-001_acq-b0b2000.png
	else
		echo "${sub} is missing b2000 acquisitions" >> ${missing_data}
	fi
done

# Render html docs
echo ""
echo "Creating html docs"
renderHTML ${mkdwn_800}
renderHTML ${mkdwn_2000}