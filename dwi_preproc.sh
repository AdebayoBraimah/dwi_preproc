#!/usr/bin/env bash
# 
# -*- coding: utf-8 -*-
# title           : dwi_preproc.sh
# description     : [description]
# author          : Adebayo B. Braimah
# e-mail          : adebayo.braimah@cchmc.org
# date            : 2019 09 10 10:09:13
# version         : 0.1.0
# usage           : dwi_preproc.sh [-h,--help]
# notes           : [notes]
# bash_version    : 5.0.7
#==============================================================================

#
# Define Usage(s) & (Miscellaneous) Function(s)
#==============================================================================

# Basic/Essential Usage
Usage() {
  cat << USAGE

  Usage: $(basename ${0}) --dwi [dwi.nii.gz] --bvals [bvals.bval] --bvec [bvec.bvec] --sub 001

Fully automated Diffusion Weighted Image (DWI) preprocessing pipeline.
This pipeline dependencies are FSL v5.0.11 (or v6.0.0+ should the --qc option be used)
and Python3.

Overall, this pipeline covers most use cases that typically arise in 
DW image preprocessing.

This pipeline performs the preprocessing in several stages:

- Stage 1: Extract reversed phase encoded (rPE) B0s [if a PE B0 is provided].
- Stage 2: Calculate EPI Readout time and write parameter and index files (for use with FSL's Eddy)
- Stage 3: Distortion Field Estimation and correction (w/ FSL's Topup & ApplyTopup) [if a rPE B0 is provided]
- Stage 4: Eddy current correction & bvector rotation (, if necessary - w/ FSL's eddy)
- Stage 5: Create FA Maps and other DW image derivatives (w/ FSL's DTI-FIT) [Optional]
- Stage 6: Quality Control is performed on the specified DW image (w/ FSL's 'eddy_quad') [Optional]
- Stage 7: Create DTI-TK compatible DTI (Diffusion Tensor Image) files (w/ DTI-TK) [Optional]

Compulsory Arguments:

-d,--dwi           Diffusion Weighted Image (DWI) nifti file.
-b,--bvals         Corresponding .bval file for the DWI
-e,--bvecs         Corresponding .bvec file for the DWI
-s,--sub           Subject ID

Optional Arguments:

--B0              Corresponding reverse phase encoded (rPE) B0 image nifti file for the DWI. NOTE: This B0 is assumed to rPE and is thus not checked.
                  One should ensure that the B0 is rPE.
-data,--data-dir  Parent preprocessing directory that will contain the working directory and the preprocessed data [Default: current working directory]
-o,--out          Output directory for the preprocessed DWIs should the default location is not suitable [Defualt: <data-dir>/derivatives/sub-<subject ID>]
-ses,--ses        Session ID [Default: 001]
--mb              Multi-band factor used [Default: 1].
-n,--nocleanup    No clean-up; subject working directory is not removed at the completion of the pipeline [Default: disabled]
--tensor          Performs FSLs DTI-FIT to create FA Maps [Default: disabled]
--dti-tk          Creates DTI-TK compatible image files from FSL preprocessed data. Automatically activates the '--tensor' flag
                  NOTE: Requires DTI-TK to be installed. [Default: disabled]
--qc              Perform DWI Quality Control (Requires FSL v6.0.0+) [Default: disabled]
-f,--fsldir       FSLDIR environmental variable [Default: System defined path]
--fig             Creates vector field overlays on FA Map. NOTE: Requires FSLeyes to be installed and working. This option may be an issue on HPCs.
                  Simply re-run the pipeline locally once finished. [Default: disabled]
--additional      Copies additional data to the output directory which includes:
                    - All of FSL's eddy outputs
                    - Miscellaneous DW image information
                    - Topup Distortion Estimation & Correction [if rPE B0 is provided]
-v,--verbose      Enables verbose output [Default: disabled]

----------------------------------------

-h,-help,--help           Prints usage and exits.
-fh,-full,--full-help     Prints full usage and exits.

NOTES: 

- This pipeline performs best when a reversed phase encoded (rPE) B0 is provided.
- This pipeline assumes that the DWI B0s are at the beginning of the acquisition. 
- Should quality control need to be run, it should be ran in the same session as 
  the main portions of the pipeline, unlike the other optional portions (e.g. 
  Stages: 5, and 7), which can run as standalone versions.
- Temporary log files are written to the current workind directory. One should 
  ensure that one has write permissions in the current working directory.

----------------------------------------

Adebayo B. Braimah - 2019 09 10 10:09:13

$(basename ${0}) v0.1.0

----------------------------------------

  Usage: $(basename ${0}) --dwi [dwi.nii.gz] --bvals [bvals.bval] --bvec [bvec.bvec] --sub 001

USAGE
  exit 1
}

# Full Usage
FullUsage() {
  cat << FULLUSAGE

  Usage: $(basename ${0}) --dwi [dwi.nii.gz] --bvals [bvals.bval] --bvec [bvec.bvec] --sub 001

Fully automated Diffusion Weighted Image (DWI) preprocessing pipeline.
This pipeline dependencies are FSL v5.0.11 (or v6.0.0+ should the --qc option be used)
and Python3.

Overall, this pipeline covers most use cases that typically arise in 
DW image preprocessing.

This pipeline performs the preprocessing in several stages:

- Stage 1: Extract reversed phase encoded (rPE) B0s [if a PE B0 is provided].
- Stage 2: Calculate EPI Readout time and write parameter and index files (for use with FSL's Eddy)
- Stage 3: Distortion Field Estimation and correction (w/ FSL's Topup & ApplyTopup) [if a rPE B0 is provided]
- Stage 4: Eddy current correction & bvector rotation (, if necessary - w/ FSL's eddy)
- Stage 5: Create FA Maps and other DW image derivatives (w/ FSL's DTI-FIT) [Optional]
- Stage 6: Quality Control is performed on the specified DW image (w/ FSL's 'eddy_quad') [Optional]
- Stage 7: Create DTI-TK compatible DTI (Diffusion Tensor Image) files (w/ DTI-TK) [Optional]

Compulsory Arguments:

-d,--dwi           Diffusion Weighted Image (DWI) nifti file.
-b,--bvals         Corresponding .bval file for the DWI
-e,--bvecs         Corresponding .bvec file for the DWI
-s,--sub           Subject ID

Optional Arguments:

--B0              Corresponding reverse phase encoded (rPE) B0 image nifti file for the DWI. NOTE: This B0 is assumed to rPE and is thus not checked.
                  One should ensure that the B0 is rPE.
-data,--data-dir  Parent preprocessing directory that will contain the working directory and the preprocessed data [Default: current working directory]
-o,--out          Output directory for the preprocessed DWIs should the default location is not suitable [Defualt: <data-dir>/derivatives/sub-<subject ID>]
-ses,--ses        Session ID [Default: 001]
--mb              Multi-band factor used [Default: 1].
-n,--nocleanup    No clean-up; subject working directory is not removed at the completion of the pipeline [Default: disabled]
--tensor          Performs FSLs DTI-FIT to create FA Maps [Default: disabled]
--dti-tk          Creates DTI-TK compatible image files from FSL preprocessed data. NOTE: Requires DTI-TK to be installed. [Default: disabled]
--qc              Perform DWI Quality Control (Requires FSL v6.0.0+) [Default: disabled]
-f,--fsldir       FSLDIR environmental variable [Default: System defined path]
--fig             Creates vector field overlays on FA Map [Default: disabled]
--additional      Copies additional data to the output directory which includes:
                    - All of FSL's eddy outputs
                    - Miscellaneous DW image information
                    - Topup Distortion Estimation & Correction [if rPE B0 is provided]
-v,--verbose      Enables verbose output [Default: disabled]

ADVANCED USAGE ARGUMENTS

BIDS Specific Arguments:

-d,--dwi          Diffusion Weighted Image (DWI) nifti file. [Required]
--B0              Corresponding reverse phase encoded (rPE) B0 image nifti file for the DWI. [optional]
-B,--BIDS         Uses BIDS named data for parsing and obtaining the associated files and their corresponding parameters to compute the necessary
                  information pertaining to preprocessing. Should this option be used, the subject ID, .bval, and .bvec files do not need to specified 
                  as they should have the same name as the DWI. This option also requires that there is/are corresponding JSON sidecars for the DWI (and
                  the associated rPE B0, should it be provided). Notably, this preprocessing script uses a custom version of BIDS which follows this
                  naming convention:
                    - sub-[sub]_ses-[ses]_acq-[acq]_dirs-[dirs]_bval-[bval]_run-[run]_dwi
                      - sub = subject ID
                      - ses = session ID
                      - acq = acquisition direction (e.g. PA, AP, LR, or RL)
                      - dirs = number of directions
                      - bval = bvalue for the acquisition (assumes single shell)
                      - run = run number of the same/similar acquisition
                  This version of custom BIDS also contains additional fields in the JSON sidecar (specific for Philips scanners), which include:
                    - WaterFatShift       - EchoTrainLength 
                    - AccelerationFactor  - MultiBandFactor
                  [Default: disabled]

Readout Time (Computation) Arguments:

--readout         Readout time (ms) of the associated DW image [Default: 0.05]
--mr-scanner      MR-scanner used to obtain the data. This is used for the calculation of the readout time (should the Echo Train Length be known). 
                  Valid arguments are: 'Philips', 'Siemens', or 'GE'. [Default: Philips]
--ETL             Echo Train Length (ms) of the DWI. This can usually be obtained from the exam card, or the MR physicist/technologist
                  NOTE: Specifying a value for this argument overrides the '--readout' argument value.
--wfs             Water Fat Shift (Hz/pixel) of the EPI/DWI. This is a Philips specific parameter used exclusively to calculate the readout time
--acc             Acceleration factor used [Default: 1]

Topup Specific Arguments (Should a rPE B0 be provided):

--config          Configuration file used for Topup. [Default: b02b0.cnf]
--top_interp      Topup image interpolation model, 'linear' or 'spline'. [Default spline]
--method          Modulation/Resampling method used in Topup. Valid options include 'lsr' (least-squares resampling) or 'jac' (jacobian modulation). [Default: lsr]

Eddy Arguments:

--interp          Eddy interpolation model for estimation step ('spline'/'trilinear') [Default: spline]
--residuals       Write residuals (between GP and observations) [Default: disabled]
--repol           Detect and replace outlier slices [Default: disabled]
--cnr_maps        Write shell-wise cnr-maps [Default: disabled]
--use-gpu         Enables GPU support of FSL's eddy and thus allows for slice-to-volume (s2v) motion correction [Default: disabled]

Slice-to-volume (s2v) Arguments [Should GPU Processing be enabled]:

--mporder           Order of slice-to-vol movement model (should be greater than 0).
--s2v_niter         Number of iterations for slice-to-vol [Default: 5]
--s2v_lambda        Regularisation weight for slice-to-vol movement. [Default: 1, reasonable range 1-10]
--s2v_interp        Slice-to-vol interpolation model for estimation step ('spline'/'trilinear') [Default: trilinear]

----------------------------------------

-h,-help,--help           Prints usage and exits.
-fh,-full,--full-help     Prints full usage and exits.

NOTES: 

- This pipeline performs best when a reversed phase encoded (rPE) B0 is provided.
- This pipeline assumes that the DWI B0s are at the beginning of the acquisition. 
- Should quality control need to be run, it should be ran in the same session as 
  the main portions of the pipeline, unlike the other optional portions (e.g. 
  Stages: 5, and 7), which can run as standalone versions.
- Temporary log files are written to the current workind directory. One should 
  ensure that one has write permissions in the current working directory.

----------------------------------------

Adebayo B. Braimah - 2019 09 10 10:09:13

$(basename ${0}) v0.1.0

----------------------------------------

  Usage: $(basename ${0}) --dwi [dwi.nii.gz] --bvals [bvals.bval] --bvec [bvec.bvec] --sub 001

FULLUSAGE
  exit 1
}

#
# Define Logging Function(s)
#==============================================================================

# Echoes status updates to the command line
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

exit_error(){
  echo_red "${@}"
  exit 1
}

# Run and log the command
run_cmd(){
  # stdOut=${outDir}/LogFile.txt
  # stdErr=${outDir}/ErrLog.txt
  echo_blue "${@}"
  eval ${@} >> ${log} 2>> ${err}
  if [ ! ${?} -eq 0 ]; then
    exit_error "${@} : command failed, see error log file for details: ${err}"
  fi
}

# log function for completion
run()
{
  # log=${outDir}/LogFile.txt
  # err=${outDir}/ErrLog.txt
  echo "${@}"
  "${@}" >>${log} 2>>${err}
  if [ ! ${?} -eq 0 ]; then
    echo "failed: see log files ${log} ${err} for details"
    exit 1
  fi
  echo "-----------------------"
}

if [ ${#} -lt 1 ]; then
  Usage >&2
  exit 1
fi

#
# Define Bash Helper Function(s)
#==============================================================================

if ! hash realpath 2>/dev/null; then
  # realpath function substitute
  # if it does not exist.
  # NOTE: Requires FSL to be 
  # installed
  realpath () { fsl_abspath ${1} ; }
fi

getRuns(){
  # Function that determines the
  # number of runs for a subject
  # pertaining to each bvalue.
  # 
  # Inputs:
  # -w,-work,--work:  working directory to be searched
  # -d,-dir,--dir:    (regEx string in the) directory string being searched for
  # 
  # Output(s):
  # prints the run number to the command line (prints the number of current runs +1)

  # Parse options
  while [ ${#} -gt 0 ]; do
    case "${1}" in
      -w|-work|--work) shift; local work=${1} ;;
      -d|-dir|--dir) shift; local dir=${1} ;;
      -*) echo_red "$(basename ${0}): Unrecognized option ${1}" >&2; ;;
      *) break ;;
    esac
    shift
  done

  # Get fullpath(s)
  local work=$(realpath ${work})
  local cwd=$(pwd)

  # Determine number of directories that match regEx string
  cd ${work}
  local a=( $(ls -d ${dir}*/) )
  cd ${cwd}

  # echo the number of similar directories
  echo $(zeropad $((${#a[@]}+1)) 2)
}

#
# Parse Command Line Variables
#==============================================================================

# Run time switches native to bash
# set -e # exit if error
scriptsDir=$(dirname $(realpath ${0}))

# Set defaults
cleanup=true
dataDir=$(pwd)
# outDir=${dataDir}/derivatives
outDir=""
ses=001
bids=false
useGPU=false
dtITK=false
modulation=lsr
acc=1
mb=1
etl=""
wfs=""
reconMatPE=""
qc=false
tensor=false
config=${FSLDIR}/etc/flirtsch/b02b0.cnf
scannerType="Philips"
readTime=0.05
FSLDIR=$(echo ${FSLDIR})
verbose=false
verboseLogging=false
top_interp=spline # linear, spline
additional=false
fig=false

# Eddy defaults
eddy_interp=spline # trilinear, spline
eddy_residuals=false
eddy_repol=false
eddy_cnr=false
# eddy_verbose=false

# Eddy slice-to-volume (s2v) motion correction
mporder=0
s2v_niter=5
s2v_lambda=1
s2v_interp=trilinear # trilinear, spline

# Parse options
while [ ${#} -gt 0 ]; do
  case "${1}" in
    -d|--dwi) shift; dwi=${1} ;;
    -b|--bvals) shift; bvals=${1} ;;
    -e|--bvecs) shift; bvecs=${1} ;;
    --B0) shift; B0=${1} ;;
    -data|--data-dir) shift; dataDir=${1} ;;
    -o|--out) shift; outDir=${1} ;;
    -s|--sub) shift; sub=${1} ;;
    -ses|--ses) shift; ses=${1} ;;
    -n|--nocleanup) cleanup=false ;;
    -B|--BIDS) bids=true ;;
    --mr-scanner) shift; scannerType=${1} ;;
    --method) shift; modulation=${1} ;;
    --ETL) shift; etl=${1} ;;
    --wfs) shift; wfs=${1} ;;
    --acc|--acceleration) shift; acc=${1} ;;
    --mb) shift; mb=${1} ;;
    --tensor) tensor=true ;;
    --qc) qc=true ;;
    -f|--fsldir) shift; FSLDIR=${1} ;;
    --interp) shift; eddy_interp=${1} ;;
    --residuals) eddy_residuals=true ;;
    --repol) eddy_repol=true ;;
    --cnr_maps) cnr_maps=true ;;
    --mporder) shift; mporder=${1} ;;
    --s2v_niter) shift; s2v_niter=${1} ;;
    --s2v_lambda) shift; s2v_lambda=${1} ;;
    --s2v_interp) shift; s2v_interp=${1} ;;
    --readout) shift; readTime=${1} ;;
    --config) shift; config=${1} ;;
    --use-gpu) useGPU=true ;;
    --dti-tk) dtITK=true ;;
    --additional) additional=true ;;
    --fig) fig=true ;;
    -v|--verbose) verbose=true ;;
    -vL|--verbose-logging) verboseLogging=true ;;
    -h|-help|--help) Usage; ;;
    -fh|-full|--full-help) FullUsage; ;;
    -*) echo_red "$(basename ${0}): Unrecognized option ${1}" >&2; Usage; ;;
    *) break ;;
  esac
  shift
done

# Old options
# --verbose-eddy) eddy_verbose=true ;;

# Enable verbosity if specified
if [ ${verbose} = "true" ]; then
  set -x # for verbose printing/debugging
fi

# Write temporary log files (change log filenames later)
log=$(pwd)/${RANDOM}.log
err=$(pwd)/${RANDOM}.err

# # Write temporary log files (change log filenames later)
# log=/tmp/${RANDOM}.log
# err=/tmp/${RANDOM}.err

# Write Date-Time Log information
dt=$(date); # year-month-day Hrs:Min.
printf "${dt} \t (Format: day MONTH DAY Hrs:Min:Sec TIMEZONE YEAR)\n" > ${log}
printf "${dt} \t (Format: day MONTH DAY Hrs:Min:Sec TIMEZONE YEAR)\n" > ${err}

# if [ ${verboseLogging} = "true" ]; then
#   set -x # for verbose printing/debugging
# fi

#
# Verify Essential Arguments & Get Absolute Paths
#==============================================================================

# Required Arguments
if [ ! -f ${dwi} ] || [ -z ${dwi} ]; then
  echo_red "Required: DW image was not passed as an argument or does not exist. Please check."
  run echo "Required: DW image was not passed as an argument or does not exist. Please check."
  exit 1
else
  dwi=$(realpath ${dwi})
fi

# Optional Arguments
if [ ! -d ${FSLDIR} ]; then
  echo_red "${FSLDIR} environmental path variable not set. Please specify the path to the fsl installation directory."
  run echo "${FSLDIR} environmental path variable not set. Please specify the path to the fsl installation directory."
  exit 1
else
  export FSLDIR=$(realpath ${FSLDIR})
  FSLBIN=${FSLDIR}/bin
fi

if [ -f ${B0} ] && [ ! -z ${B0} ]; then
  B0=$(realpath ${B0})
  runTopup=true
elif [ ! -f ${B0} ] && [ ! -z ${B0} ]; then
  echo_red "Reversed Phase Encoded B0 specified at the command line but was not provided an argument or does not exist. Please check."
  run echo "Reversed Phase Encoded B0 specified at the command line but was not provided an argument or does not exist. Please check."
  exit 1
elif [ -z ${B0} ]; then
  runTopup=false
fi

if [ -z ${dataDir} ]; then
  echo_red "Data directory was specified at the command line but was not provided. Please check."
  run echo "Data directory was specified at the command line but was not provided. Please check."
  exit 1
else
  dataDir=$(realpath ${dataDir})
fi

if [ ! -d ${dataDir}/logs ]; then
  echo_blue "Making Log Directory"
  run mkdir -p ${dataDir}/logs
fi


#
# Verify That Certain Options Are Available
#==============================================================================

# Check DTI-TK
if [ ${dtITK} = "true" ]; then
  if ! hash fsl_to_dtitk 2>/dev/null; then
    # Check if DTI-TK is installed.
    echo_red "ERROR: DTI-TK is not installed. Tensor conversion is not possible. Please run again, but do not use the '--dti-tk' flag."
    run echo "ERROR: DTI-TK is not installed. Tensor conversion is not possible. Please run again, but do not use the '--dti-tk' flag."
    exit 1
  fi
  DTITKscripts=$(dirname $(which fsl_to_dtitk))
fi

# Check Eddy
if [ ${useGPU} = "true" ]; then
  # Check for each release of eddy_cuda
  ${FSLBIN}/eddy_cuda9.1; cuda91=${?}
  ${FSLBIN}/eddy_cuda8.0; cuda80=${?}
  ${FSLBIN}/eddy_cuda; cuda=${?}

  # Check to see if any release is available to use
  if [ ${cuda91} -eq 1 ]; then
    echo_blue "GPU Processing Enabled"
    run echo "GPU Processing Enabled"
    eddy="eddy_cuda9.1"
  elif [ ${cuda80} -eq 1 ]; then
    echo_blue "GPU Processing Enabled"
    run echo "GPU Processing Enabled"
    eddy="eddy_cuda8.0"
  elif [ ${cuda} -eq 1 ]; then
    echo_blue "GPU Processing Enabled"
    run echo "GPU Processing Enabled"
    eddy="eddy_cuda"
  else
    echo_red "ERROR: CUDA is not installed on this system. GPU Processing is not available on this system. Please install the appropriate CUDA driver(s) for your system or remove the '--use-gpu' flag on the command line."
    run echo "ERROR: CUDA is not installed on this system. GPU Processing is not available on this system. Please install the appropriate CUDA driver(s) for your system or remove the '--use-gpu' flag on the command line."
    exit 1
  fi
elif [ ${useGPU} = "false" ]; then
  # Check for each release of eddy (not eddy_correct)
  ${FSLBIN}/eddy_openmp ; cmd_mp=${?}
  ${FSLBIN}/eddy ; cmd=${?}

  # Check to see if any release is availabe to use
  if [ ${cmd_mp} -eq 1 ]; then
    echo_blue "Parallel Processing Enabled"
    run echo "Parallel Processing Enabled"
    eddy="eddy_openmp"
  elif [ ${cmd} -eq 1 ]; then
    echo_blue "Eddy program found"
    run echo "Eddy program found"
    eddy="eddy"
  else
    echo_red "ERROR: Eddy does not appear to be installed on this system. Please check your FSL installation."
    run echo "ERROR: Eddy does not appear to be installed on this system. Please check your FSL installation."
    exit 1
  fi
fi

# Check FSLeyes
if [ ${fig} = "true" ]; then
  # Check to see if FSLeyes works from the command line
  ${FSLBIN}/fsleyes -h; eyes=${?}

  # Check if working 
  if [ ! ${eyes} -eq 0 ]; then
    echo_red "ERROR: FSLeyes is not available on this system via the command line. Please run the pipeline without the '--fig' option."
    run echo "ERROR: FSLeyes is not available on this system via the command line. Please run the pipeline without the '--fig' option."
    exit 1
  fi
fi

# Run time switches native to bash
set -e # exit if error

#
# Make Working Directory [in the case of BIDS data]
#==============================================================================

if [ ! -d ${dataDir}/work ]; then
	echo_blue "Making working directory"
	run mkdir -p ${dataDir}/work
fi

if [ ${bids} = "true" ]; then
  # Define dwi filename basename
  # filename=$(basename ${dwi%.*})
  file_dwi=$(basename $(remove_ext ${dwi}))
  outFile=${dataDir}/work/${RANDOM}_BIDS_info.txt

  # Parse BIDS filename for info
  run ${scriptsDir}/dwInfo.py --info parse --parse ${file_dwi} --output ${outFile}

  # Get BIDS file info
  infoBIDS=( sub ses bval run)

  for ((i = 0; i < ${#infoBIDS[@]}; i++)); do
    info=${infoBIDS[$i]}
    eval ${info}=$(grep ${infoBIDS[$i]} ${outFile} | awk '{print $2}')
  done

  # Define working directory
  work=${dataDir}/work/${sub}-${ses}_bval-${bval}_run-${run}
  subID=sub-${sub}_ses-${ses}_bval-${bval}_run-${run}

  # Get Additional DWI associated files
  bvals=$(dirname ${dwi})/${file_dwi}.bval*
  bvecs=$(dirname ${dwi})/${file_dwi}.bvec*

  if [ ! -d ${work}/source ]; then
    echo_blue "Making sub-${sub} working directory"
    run mkdir -p ${work}/source
  fi

  # Define file basenames
  dwi_files=$(remove_ext ${dwi})

  # Copy over BIDS related files
  run mv ${outFile} ${work}/source/sub-${sub}_ses-${ses}_run-${run}_BIDS_info.txt
  run cp ${dwi_files}.* ${work}/source

  # Redefine variables
  dwi=${work}/source/$(basename ${dwi})
  bvals=${work}/source/$(basename ${bvals})
  bvecs=${work}/source/$(basename ${bvecs})

  # JSON Sidecar(s)
  dwi_json=${work}/source/$(basename ${dwi_files}).json

  # If rPE B0 provided
  if [ ${runTopup} = "true" ]; then
    B0_files=$(remove_ext ${B0})
    run cp ${B0_files}.* ${work}/source
    B0=${work}/source/$(basename ${B0})
    B0_json=${work}/source/$(basename ${B0_files}).json
  fi
fi

#
# Verify Required Arguments & Get Absolute Paths
#==============================================================================

# Verify inputs

# Required Arguments
if [ ! -f ${bvals} ] || [ -z ${bvals} ]; then
  echo_red "Required: bvalues were not passed as an argument or do not exist. Please check."
  run echo "Required: bvalues were not passed as an argument or do not exist. Please check."
  exit 1
else
  bvals=$(realpath ${bvals})
fi

if [ ! -f ${bvecs} ] || [ -z ${bvecs} ]; then
  echo_red "Required: bvectors were not passed as an argument or do not exist. Please check."
  run echo "Required: bvectors were not passed as an argument or do not exist. Please check."
  exit 1
else
  bvecs=$(realpath ${bvecs})
fi

if [ -z ${sub} ]; then
  echo_red "Required: Subject ID was not passed as an argument. Please check."
  run echo "Required: Subject ID was not passed as an argument. Please check."
  exit 1
fi

#
# Verify Optional Arguments & Get Absolute Paths
#==============================================================================

# Optional Arguments
if [ ! -f ${config} ] || [ -z ${config} ]; then
  echo_red "Topup configuration file was not passed as an argument or does not exist. Please check."
  run echo "Topup configuration file was not passed as an argument or does not exist. Please check."
  exit 1
else
  config=$(realpath ${config})
fi

# if [ -z ${outDir} ]; then
#   echo_red "Output directory was specified at the command line but was not provided. Please check."
#   run echo "Output directory was specified at the command line but was not provided. Please check."
#   exit 1
# else
#   outDir=$(realpath ${outDir})
# fi

if [ -z ${outDir} ]; then
  outDir=${dataDir}/derivatives
elif [ ! -z ${outDir} ]; then
  outDir=$(realpath ${outDir})
fi

if [ -z ${ses} ]; then
  echo_red "Session was specified at the command line but was not provided. Please check."
  run echo "Session was specified at the command line but was not provided. Please check."
  exit 1
else
  ses=$(zeropad ${ses} 3)
fi

if [ ${dtITK} = "true" ]; then
  tensor="true"
elif [ ${fig} = "true" ]; then
  tensor="true"
fi

if [ -z ${scannerType} ]; then
  echo_red "mr-scanner was specified at the command line but vendor was not provided. Please check."
  run echo "mr-scanner was specified at the command line but vendor was not provided. Please check."
  exit 1
elif [ ${scannerType,,} = "philips" ]; then
  scannerType="Philips"
elif [ ${scannerType,,} = "siemens" ] || [ ${scannerType^^} = "GE" ]; then
  scannerType="Regular"
else
  echo_red "${scannerType}: Invalid argument for mr-scanner. Valid arguments include: 'philips', 'siemens', or 'GE'."
  run echo "${scannerType}: Invalid argument for mr-scanner. Valid arguments include: 'philips', 'siemens', or 'GE'."
fi

if [ -z ${modulation} ]; then
  echo_red "modulation was specified at the command line but interpolation method was not specified. Please check."
  run echo "modulation was specified at the command line but interpolation method was not specified. Please check."
  exit 1
elif [ ${modulation,,} = "lsr" ]; then
  modulation="lsr"
elif [ ${modulation,,} = "jac" ]; then
  modulation="jac"
else
  echo_red "${modulation}: Invalid argument for modulation method. Valid arguments include: 'lsr',or 'jac'."
  run echo "${modulation}: Invalid argument for modulation method. Valid arguments include: 'lsr',or 'jac'."
  exit 1
fi

if [ ! -z ${etl} ]; then
  if ! [[ "${etl}" =~ ^[0-9]+$ ]]; then
          echo_red "ETL argument requires integers only [1-9999999]"
          run echo "ETL argument requires integers only [1-9999999]"
          exit 1
  fi
  readTime=""
fi

if [ ! -z ${wfs} ]; then
  if ! [[ "${wfs}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
          echo_red "wfs (water fat shift) argument requires floats [1.0-9999999.0]"
          run echo "wfs (water fat shift) argument requires floats [1.0-9999999.0]"
          exit 1
  fi
fi

if [ ! -z ${acc} ]; then
  if ! [[ "${acc}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
          echo_red "acceleration (Acceleration Factor) argument requires floats [1.0-9999999.0]"
          run echo "acceleration (Acceleration Factor) argument requires floats [1.0-9999999.0]"
          exit 1
  fi
fi

if [ ! -z ${mb} ]; then
  if ! [[ "${mb}" =~ ^[0-9]+$ ]]; then
          echo_red "mb (Multi-Band Factor) argument requires integers only [1-9999999]"
          run echo "mb (Multi-Band Factor) argument requires integers only [1-9999999]"
          exit 1
  fi
fi

if [ ! -z ${readTime} ]; then
  if ! [[ "${readTime}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
          echo_red "readout (readout time) argument requires floats [1.0-9999999.0]"
          run echo "readout (readout time) argument requires floats [1.0-9999999.0]"
          exit 1
  fi
fi

# Eddy Specific Optional Arguments
if [ -z ${eddy_interp} ]; then
  echo_red "eddy interpolation method was specified at the command line but was not provided. Please check."
  run echo "eddy interpolation method was specified at the command line but was not provided. Please check."
  exit 1
elif [ ${eddy_interp,,} = "spline" ]; then
  eddy_interp="spline"
elif [ ${eddy_interp,,} = "trilinear" ]; then
  eddy_interp="trilinear"
else
  echo_red "${eddy_interp}: Invalid argument for modulation method. Valid arguments include: 'spline',or 'trilinear'."
  run echo "${eddy_interp}: Invalid argument for modulation method. Valid arguments include: 'spline',or 'trilinear'."
fi

# Eddy s2v (slice-to-volume) Specific Optional Arguments
if [ ! -z ${mporder} ]; then
  if ! [[ "${mporder}" =~ ^[0-9]+$ ]]; then
          echo_red "Eddy slice-to-volume mporder argument requires integers only [1-9999999]"
          run echo "Eddy slice-to-volume mporder argument requires integers only [1-9999999]"
          exit 1
  fi
fi

if [ ! -z ${s2v_niter} ]; then
  if ! [[ "${s2v_niter}" =~ ^[0-9]+$ ]]; then
          echo_red "Eddy slice-to-volume number of iterations (s2v_niter) argument requires integers only [1-9999999]"
          run echo "Eddy slice-to-volume number of iterations (s2v_niter) argument requires integers only [1-9999999]"
          exit 1
  fi
fi

if [ ! -z ${s2v_lambda} ]; then
  if ! [[ "${s2v_lambda}" =~ ^[0-9]+$ ]]; then
          echo_red "Eddy slice-to-volume strength of temporal regularisation of the estimated movement parameters (s2v_lambda) argument requires integers only [1-9999999]"
          run echo "Eddy slice-to-volume strength of temporal regularisation of the estimated movement parameters (s2v_lambda) argument requires integers only [1-9999999]"
          exit 1
  fi
fi

if [ -z ${s2v_interp} ]; then
  echo_red "Eddy slice-to-volume interpolation method was specified at the command line but was not provided. Please check."
  run echo "Eddy slice-to-volume interpolation method was specified at the command line but was not provided. Please check."
  exit 1
elif [ ${s2v_interp,,} = "spline" ]; then
  s2v_interp="spline"
elif [ ${s2v_interp,,} = "trilinear" ]; then
  s2v_interp="trilinear"
else
  echo_red "${s2v_interp}: Invalid argument for interpolation method. Valid arguments include: 'spline',or 'trilinear'."
  run echo "${s2v_interp}: Invalid argument for interpolation method. Valid arguments include: 'spline',or 'trilinear'."
  exit 1
fi

#
# Make Working Directory [in the case of non-BIDS data]
#==============================================================================

if [ ${bids} = "false" ]; then
  # Define working directory name
  run=$(getRuns --work ${dataDir}/work --dir ${sub}-${ses})
  work=${dataDir}/work/${sub}-${ses}_run-${run}
  subID="sub-${sub}_ses-${ses}_run-${run}"

  if [ ! -d ${work}/source ]; then
    echo_blue "Making sub-${sub} working directory"
    run mkdir -p ${work}/source
  fi

  # copy files to working directory
  run cp ${dwi} ${work}/source
  run cp ${bvals} ${work}/source
  run cp ${bvecs} ${work}/source

  # Redefine variables
  dwi=${work}/source/$(basename ${dwi})
  bvals=${work}/source/$(basename ${bvals})
  bvecs=${work}/source/$(basename ${bvecs})

  # If rPE B0 provided
  if [ ${runTopup} = "true" ]; then
    run cp ${B0} ${work}/source
    B0=${work}/source/$(basename ${B0})
  fi
fi

#
# Make Log Directory
#==============================================================================

if [ ! -d ${dataDir}/logs ]; then
  echo_blue "Making Log Directory"
  run mkdir -p ${dataDir}/logs
fi

# Copy and rename log files
cp ${log} ${dataDir}/logs/${subID}.log
cp ${err} ${dataDir}/logs/${subID}.err

# Remove tempory log files
rm ${log}
rm ${err}

# Rename log file variables
unset log err
log=${dataDir}/logs/${subID}.log
err=${dataDir}/logs/${subID}.err

#
# DWI Preprocessing: Stage 0 - Gather (BIDS related) Files & Compute
# DWI/EPI related Variables
#==============================================================================

cd ${work}

# Create directory to store miscellaneous files
if [ ! -d ${work}/dwi.misc ]; then
  echo_blue "Making Misc Directory"
  run mkdir -p ${work}/dwi.misc
fi

if [ ${bids} = "true" ]; then

  run cd ${work}/dwi.misc
  run mv ${work}/source/sub-${sub}_ses-${ses}_run-${run}_BIDS_info.txt ${work}/dwi.misc

  # Parse DWI JSON File
  dwiParams=${work}/dwi.misc/sub-${sub}_ses-${ses}_dwi_info_params.txt
  run ${scriptsDir}/dwInfo.py --info BIDS --BIDS ${dwi_json} --param ${dwiParams}

  # Get individual parameters (from custom BIDS fields)
  parameter=( EchoTime RepetitionTime ReconMatrixPE WaterFatShift EchoTrainLength AccelerationFactor MultiBandFactor bvalue )
  paramVar=( te tr reconMatPE wfs etl acc mb bvalue )

  for ((i = 0; i < ${#parameter[@]}; i++)); do
    param=${paramVar[$i]}
    eval ${param}=$(grep ${parameter[$i]} ${dwiParams} | awk '{print $2}')
  done
elif [ ${bids} = "false" ]; then
  # Compute the necessary variable(s)
  # reconMatPE (Phase Encoded Reconstruction Matrix)
  # is equivalent to the number of phase encoding steps
  # in the Z-direction.
  reconMatPE=$(${FSLBIN}/fslval ${dwi} dim3)
fi

# Output directory file check variables
if [ ${bids} = "true" ]; then
  # Define BIDS output directory
  outDir=${outDir}/sub-${sub}/ses-${ses}/dwi/bval-${bval}_run-${run}
elif [ ${bids} = "false" ]; then
  # Define output directory
  outDir=${outDir}/sub-${sub}/dwi_run-${run}
fi

#
# DWI Preprocessing: Stage 1 - Make PE-rPE B0s File
#==============================================================================

cd ${work}

if [ ! -f ${outDir}/${subID}_dwi.nii.gz ]; then
  if [ ${runTopup} = "true" ]; then
    # Make Topup working directory
    if [ ! -d ${work}/Topup ]; then
      echo_blue "Making Topup Directory"
      run mkdir -p ${work}/Topup
    fi

    run cd ${work}/Topup

    # Extract B0s from PA PE direction (for the case of CCHMC Philips DWI data, 
    # in which the B0s are at the beginning)
    numB0s=$(${scriptsDir}/dwInfo.py --info B0 --bvalue ${bvals})
    numB0s=$(zeropad ${numB0s} 3)
    run ${FSLBIN}/fslroi ${dwi} ${work}/Topup/B0s_PA_num-${numB0s} --tmin ${numB0s}

    # Merge B0s
    run ${FSLBIN}/fslmaths ${B0} -Tmean ${work}/Topup/mean_B0s_AP.nii.gz
    run ${FSLBIN}/fslmaths ${work}/Topup/B0s_PA_num-${numB0s}.nii.gz  -Tmean ${work}/Topup/mean_B0s_PA.nii.gz
    # run ${FSLBIN}/fslmerge -t ${work}/Topup/B0s ${work}/Topup/mean_B0s_PA.nii.gz ${B0}
    run ${FSLBIN}/fslmerge -t ${work}/Topup/B0s ${work}/Topup/mean_B0s_PA.nii.gz ${work}/Topup/mean_B0s_AP.nii.gz

    cd ${work}
  fi
fi

#
# DWI Preprocessing: Stage 2 - Write DWI Distortion Correction Information
# Files (Used in Topup & Eddy)
#==============================================================================

# Calculate Readout Time
# Unless the Readout Time is
# already given or
# the Echo-Train Length
# is unavailable.
if [ ! -z ${etl} ]; then
  case ${scannerType} in
    Philips)
      if [ ! -z ${wfs} ]; then
        varsEPI=( $(${scriptsDir}/calc_readOut_time.py --method ${scannerType} --ETL ${etl} --WFS ${wfs} --acceleration ${acc}) )
      else
        scannerType="Regular"
        varsEPI=( $(${scriptsDir}/calc_readOut_time.py --method ${scannerType} --ETL ${etl} --PE ${reconMatPE} --acceleration ${acc}) )
      fi
      ;;
    Regular)
      varsEPI=( $(${scriptsDir}/calc_readOut_time.py --method ${scannerType} --ETL ${etl} --PE ${reconMatPE} --acceleration ${acc}) )
      ;;
  esac

  # store as EPI variables array
  # [0] = EPI dwell time
  # [1] = EPI readout time
  dwell=${varsEPI[0]}
  readTime=${varsEPI[1]}
fi

# Write slice acquisition file
if [ ${mb} -eq 0 ]; then mb=1; fi # Check if multi-band factor is 0, if so, change to 1
slspec=${work}/dwi.misc/slice_spec.txt
run ${scriptsDir}/mb_slice_order.py --slices ${reconMatPE} --mb ${mb} --mode interleaved --out ${slspec}

# Write acqp (ACQuired Parameters) file
param=${work}/dwi.misc/mr_params.acqp
run ${scriptsDir}/dwInfo.py --info acqp --read ${readTime} --acqp ${param}

if [ ${runTopup} = "false" ]; then
  # Remove the additional line in the 
  # acqp file that corresponds to the 
  # rPE B0.
  echo $(grep -v '0 -1 0' ${param}) > ${param}
fi

# Write idx file
idx=${work}/dwi.misc/mr_frame_index.idx
run ${scriptsDir}/dwInfo.py --info idx --dwi ${dwi} --idx ${idx}

#
# DWI Preprocessing: Stage 3 - DWI Distortion Field Estimation &
# Correction (w/ Topup)
#==============================================================================

if [ ! -f ${outDir}/${subID}_dwi.nii.gz ]; then
  if [ ${runTopup} = "true" ]; then
    # Perform Field Distortion Estimation
    run cd ${work}/Topup

    # Run Topup
    run ${FSLBIN}/topup --imain=${work}/Topup/B0s --datain=${param} --config=${FSLDIR}/etc/flirtsch/b02b0.cnf --out=${work}/Topup/suscept_corr_B0 --fout=${work}/Topup/suscept_field_Hz --iout=${work}/Topup/unwarped_B0s --scale=1 --verbose

    # split B0s used for topup
    run ${FSLBIN}/fslsplit ${work}/Topup/B0s.nii.gz diff_B0 -t

    # Rename B0s
    run mv diff_B0*0.nii.gz B0_PA.nii.gz
    run mv diff_B0*1.nii.gz B0_AP.nii.gz

    # Apply Topup
    run ${FSLBIN}/applytopup --imain=B0_PA.nii.gz,B0_AP.nii.gz --datain=${param} --inindex=1,2 --topup=${work}/Topup/suscept_corr_B0 --method=lsr --out=${work}/Topup/hifi --verbose

    run cd ${work}
  fi
fi

#
# DWI Preprocessing: Stage 4 - DWI Eddy Current Correction (w/ Eddy)
#==============================================================================

if [ ! -f ${outDir}/${subID}_dwi.nii.gz ] && [ ! -f ${outDir}/${subID}_dwi.bvec ]; then
  # Make Eddy working directory
  if [ ! -d ${work}/Eddy ]; then
    echo_blue "Making Eddy Directory"
    run mkdir -p ${work}/Eddy
  fi

  run cd ${work}/Eddy

  if [ ${runTopup} = "false" ]; then
    # Create (Mean) B0 image
    numB0s=$(${scriptsDir}/dwInfo.py --info B0 --bvalue ${bvals})
    numB0s=$(zeropad ${numB0s} 3)
    run ${FSLBIN}/fslroi ${dwi} ${work}/Eddy/B0s_PA_num-${numB0s} --tmin ${numB0s}

    # Take Mean of B0s
    run ${FSLBIN}/fslmaths ${work}/Eddy/B0s_PA_num-${numB0s}.nii.gz  -Tmean ${work}/Eddy/mean_B0s_PA.nii.gz

    # Create Brain Mask
    run bet ${work}/Eddy/mean_B0s_PA ${work}/Eddy/${subID}_hifi_brain -m -R
  elif [ ${runTopup} = "true" ]; then
    # Create Brain Mask
    run bet ${work}/Topup/hifi ${work}/Eddy/${subID}_hifi_brain -m -R
  fi

  # Define eddy as a function depending on whether GPU is enabled
  if [ ${useGPU} = "true" ]; then
    # Define Eddy function
    # eddy () { ${FSLBIN}/${eddy} "${@}" ; }
    # eddy_corr+="eddy "
    eddy_corr+="${FSLBIN}/${eddy} "
    if [ ${mporder} -gt 0 ]; then
      # Determine if slice-to-volume (s2v) is used
      s2vArg=( mporder s2v_niter s2v_lambda s2v_interp slspec )
      s2vVar=( ${mporder} ${s2v_niter} ${s2v_lambda} ${s2v_interp} ${slspec} )
      for ((i = 0; i < ${#s2vArg[@]}; i++)); do
        eddy_corr+="--${s2vArg[$i]}=${s2vVar[$i]} "
      done
    fi
  elif [ ${useGPU} = "false" ]; then
    # Define Eddy function
    # eddy () { ${FSLBIN}/${eddy} "${@}" ; }
    # eddy_corr+="eddy "
    eddy_corr+="${FSLBIN}/${eddy} "
  fi

  # Main Eddy Arguments/Parameters
  if [ ${runTopup} = "true" ]; then
    out_dwi=${work}/Eddy/${subID}_eddy_dist_corr
    eddy_corr+="--topup=${work}/Topup/suscept_corr_B0 "
  else
    out_dwi=${work}/Eddy/${subID}_eddy_corr
  fi

  eddy_corr+="--imain=${dwi}  --bvecs=${bvecs} --bvals=${bvals} " # DWI specific files
  eddy_corr+="--mask=${work}/Eddy/${subID}_hifi_brain_mask --acqp=${param} --index=${idx} " # DWI mask and parameter files
  eddy_corr+="--out=${out_dwi} --verbose "

  # (Additional) Eddy Specific Optional Arguments/Parameters
  if [ ! -z ${eddy_interp} ]; then
    eddy_corr+="--interp=${eddy_interp} "
  fi

  if [ ${eddy_residuals} = "true" ]; then
    eddy_corr+="--residuals "
  fi

  # Replace outliers
  if [ ${eddy_repol} = "true" ]; then
    eddy_corr+="--repol "
  fi

  if [ ${eddy_cnr} = "true" ]; then
    eddy_corr+="--cnr_maps "
  fi

  # Perform Eddy Current & Motion Correction
  run ${eddy_corr}

  bvec=$(ls *rotated_bvecs*)
  bvec=$(realpath ${bvec})
elif [ -f ${outDir}/${subID}_dwi.nii.gz ] && [ -f ${outDir}/${subID}_dwi.bvec ]; then
  out_dwi=${outDir}/${subID}_dwi
  bvec=${outDir}/${subID}_dwi.bvec
fi

#
# DWI Preprocessing: Stage 5 - Create FA Maps & Associated Data (w/ DTI-FIT)
#==============================================================================

if [ ${tensor} = "true" ] && [ ! -d ${outDir}/Tensor ]; then
  # Make output directory
  if [ ! -d ${work}/Tensor ]; then
    echo_blue "Making Tensor Directory"
    run mkdir -p ${work}/Tensor
  fi

  run cd ${work}/Tensor

  # DTI-FIT
  fit=${subID} # for now, change later
  # ${FSLBIN}/dtifit --data=${out_dwi} --out=${fit} --mask=${work}/Eddy/hifi_brain_mask --bvecs=${bvec} --bvals=${bvals} --save_tensor # testing
  run ${FSLBIN}/dtifit --data=${out_dwi} --out=${fit} --mask=${work}/Eddy/${subID}_hifi_brain_mask --bvecs=${bvec} --bvals=${bvals} --save_tensor
else
  fit=${subID} # for now, change later
fi

# #
# # DWI Preprocessing: Stage 6 - QC (eddy_quad)
# #==============================================================================

# # test and include options for s2v processed data
# if [ ${qc} = "true" ] && [ ! -d ${outDir}/Eddy.qc ]; then
#   # Perform QC
#   # ${FSLBIN}/eddy_quad ${out_dwi} --eddyIdx ${idx} --eddyParams ${param} --mask ${work}/Eddy/${subID}_hifi_brain_mask --bvals ${bvals} --bvecs ${bvec} --output-dir ${work}/${subID}.qc --slspec ${slspec} --field ${work}/Topup/suscept_field_Hz
#   # ${FSLBIN}/eddy_quad ${out_dwi} --eddyIdx ${idx} --eddyParams ${param} --mask ${work}/Eddy/hifi_brain_mask --bvals ${bvals} --bvecs ${bvec} --output-dir ${work}/${subID}.qc --slspec ${slspec} --field ${work}/Topup/suscept_field_Hz # testing
#   # ${FSLBIN}/eddy_quad ${out_dwi} --eddyIdx ${idx} --eddyParams ${param} --mask ${work}/Eddy/hifi_brain_mask --bvals ${bvals} --bvecs ${bvec} --output-dir ${work}/Eddy.qc --slspec ${slspec} --field ${work}/Topup/suscept_field_Hz # testing
#   ${FSLBIN}/eddy_quad ${out_dwi} --eddyIdx ${idx} --eddyParams ${param} --mask ${work}/Eddy/${subID}_hifi_brain_mask --bvals ${bvals} --bvecs ${bvec} --output-dir ${work}/Eddy.qc --slspec ${slspec} --field ${work}/Topup/suscept_field_Hz
# fi

# #
# # DWI Preprocessing: Stage 7 - Create DTI-TK Images (DTI-TK)
# #==============================================================================

# if [ ${dtITK} = "true" ] && [ ! -d ${outDir}/DTI-TK ]; then
#   # Uses DTI-TK to convert
#   # FSL FA maps and eigenvectors
#   # to DTI-TK's format.
#   if [ ! -d ${work}/DTI-TK ]; then
#     echo_blue "Making Subject DTI-TK Directory"
#     mkdir -p ${work}/DTI-TK
#   fi

#   cd ${work}/Tensor
#   files=( $(ls *${fit}*.nii*) )

#   for file in ${files[@]}; do
#     cp -r ${file} ${work}/DTI-TK
#   done

#   cd ${work}/DTI-TK
#   ${DTITKscripts}/fsl_to_dtitk ${fit}

#   for file in ${files[@]}; do
#     rm ${file}
#   done
# fi

#
# DWI Preprocessing: Stage 8 - Copy Files From Working Directory 
# to Output Directory
#==============================================================================

run cd ${work}

if [ ${bids} = "true" ]; then
  # Define BIDS output directory
  # outDir=${outDir}/sub-${sub}/ses-${ses}/dwi/bval-${bval}_run-${run}

  # Make output directory
  if [ ! -d ${outDir} ]; then
    echo_blue "Making Output Directory"
    run mkdir -p ${outDir}
  fi

  if [ ! -f ${outDir}/${subID}_dwi.nii.gz ] && [ ! -f ${outDir}/${subID}_dwi.bvec ]; then
    # Copy preprocessed DW image associated files to output directory
    run cp ${bvals} ${outDir}/${subID}_dwi.bval
    run cp ${bvec} ${outDir}/${subID}_dwi.bvec
    run cp ${out_dwi}.nii.gz ${outDir}/${subID}_dwi.nii.gz
    run cp ${dwi_json} ${outDir}/${subID}_dwi.json
  fi
elif [ ${bids} = "false" ]; then
  # Define output directory
  # outDir=${outDir}/sub-${sub}/bval-${bval}_run-${run}

  # Make output directory
  if [ ! -d ${outDir} ]; then
    echo_blue "Making Output Directory"
    run mkdir -p ${outDir}
  fi

  if [ ! -f ${outDir}/${subID}_dwi.nii.gz ] && [ ! -f ${outDir}/${subID}_dwi.bvec ]; then
    # Copy preprocessed DW image associated files to output directory
    run cp ${bvals} ${outDir}/${subID}_dwi.bval
    run cp ${bvec} ${outDir}/${subID}_dwi.bvec
    run cp ${out_dwi}.nii.gz ${outDir}/${subID}_dwi.nii.gz
  fi
fi

# Copy Option Specific directories to output directory
# if [ ${qc} = "true" ] && [ ! -d ${outDir}/Eddy.qc ]; then
#   cp -r ${work}/Eddy.qc ${outDir}
# fi

# if [ ${tensor} = "true" ] && [ ! -d ${outDir}/Tensor ]; then
#   cp -r ${work}/Tensor ${outDir}

#   # Make Figures
#   if [ ${fig} = "true" ]; then
#     ov1="fsleyes render --scene=ortho -hc -of=${outDir}/Tensor/${subID}_FA_ortho.png ${fit}_FA.nii.gz ${fit}_V1.nii.gz -ot rgbvector"   # Overlay with orthongal views
#     ov2="fsleyes render --scene=lightbox -hc -of=${outDir}/Tensor/${subID}_FA_lightbox.png ${fit}_FA.nii.gz ${fit}_V1.nii.gz -ot rgbvector"  # Overlay with lightbox view
#     ${ov1} && ${ov2} # Create FA map Overlays
#   fi
# elif [ -d ${outDir}/Tensor ] && [ ${fig} = "true" ]; then
#   ov1="fsleyes render --scene=ortho -hc -of=${outDir}/Tensor/${subID}_FA_ortho.png ${fit}_FA.nii.gz ${fit}_V1.nii.gz -ot rgbvector"   # Overlay with orthongal views
#   ov2="fsleyes render --scene=lightbox -hc -of=${outDir}/Tensor/${subID}_FA_lightbox.png ${fit}_FA.nii.gz ${fit}_V1.nii.gz -ot rgbvector"  # Overlay with lightbox view
#   ${ov1} && ${ov2} # Create FA map Overlays
# fi

if [ ${tensor} = "true" ] && [ ! -d ${outDir}/Tensor ]; then
  run cp -r ${work}/Tensor ${outDir}
fi

if [ ${fig} = "true" ] && [ ${tensor} = "true" ]; then
  ov1="fsleyes render --scene=ortho -hc -of=${outDir}/Tensor/${subID}_FA_ortho.png ${outDir}/Tensor/${fit}_FA.nii.gz ${outDir}/Tensor/${fit}_V1.nii.gz -ot rgbvector"   # Overlay with orthongal views
  ov2="fsleyes render --scene=lightbox -hc -of=${outDir}/Tensor/${subID}_FA_lightbox.png ${outDir}/Tensor/${fit}_FA.nii.gz ${outDir}/Tensor/${fit}_V1.nii.gz -ot rgbvector"  # Overlay with lightbox view
  run ${ov1} & # Create FA map Overlays
  run ${ov2} & # Create FA map Overlays
fi

# if [ ${dtITK} = "true" ] && [ ! -d ${outDir}/DTI-TK ]; then
#   cp -r ${work}/DTI-TK ${outDir}
# fi

if [ ${additional} = "true" ] && [ ! -d ${outDir}/dwi.misc ] && [ -d ${work}/dwi.misc ]; then
  run cp -r ${work}/dwi.misc ${outDir}
fi

if [ ${additional} = "true" ] && [ ! -d ${outDir}/Eddy ] && [ -d ${work}/Eddy ]; then
  run cp -r ${work}/Eddy ${outDir}
fi

if [ ${additional} = "true" ] && [ ${runTopup} = "true" ] && [ ! -d ${outDir}/Topup ] && [ -d ${work}/Topup ]; then
  run cp -r ${work}/Topup ${outDir}
fi

#
# DWI Preprocessing: Stage 6 - QC (eddy_quad)
#==============================================================================

# test and include options for s2v processed data
if [ ${qc} = "true" ] && [ ! -d ${outDir}/Eddy.qc ] && [ ${runTopup} = "true" ]; then
  # Perform QC
  # ${FSLBIN}/eddy_quad ${out_dwi} --eddyIdx ${idx} --eddyParams ${param} --mask ${work}/Eddy/${subID}_hifi_brain_mask --bvals ${bvals} --bvecs ${bvec} --output-dir ${work}/${subID}.qc --slspec ${slspec} --field ${work}/Topup/suscept_field_Hz
  # ${FSLBIN}/eddy_quad ${out_dwi} --eddyIdx ${idx} --eddyParams ${param} --mask ${work}/Eddy/hifi_brain_mask --bvals ${bvals} --bvecs ${bvec} --output-dir ${work}/${subID}.qc --slspec ${slspec} --field ${work}/Topup/suscept_field_Hz # testing
  # ${FSLBIN}/eddy_quad ${out_dwi} --eddyIdx ${idx} --eddyParams ${param} --mask ${work}/Eddy/hifi_brain_mask --bvals ${bvals} --bvecs ${bvec} --output-dir ${work}/Eddy.qc --slspec ${slspec} --field ${work}/Topup/suscept_field_Hz # testing
  run ${FSLBIN}/eddy_quad ${out_dwi} --eddyIdx ${idx} --eddyParams ${param} --mask ${work}/Eddy/${subID}_hifi_brain_mask --bvals ${bvals} --bvecs ${bvec} --output-dir ${work}/Eddy.qc --slspec ${slspec} --field ${work}/Topup/suscept_field_Hz
elif [ ${qc} = "true" ] && [ ! -d ${outDir}/Eddy.qc ] && [ ${runTopup} = "false" ]; then
  run ${FSLBIN}/eddy_quad ${out_dwi} --eddyIdx ${idx} --eddyParams ${param} --mask ${work}/Eddy/${subID}_hifi_brain_mask --bvals ${bvals} --bvecs ${bvec} --output-dir ${work}/Eddy.qc --slspec ${slspec}
fi

# Copy Option Specific directories to output directory
if [ ${qc} = "true" ] && [ ! -d ${outDir}/Eddy.qc ]; then
  run cp -r ${work}/Eddy.qc ${outDir}
fi

#
# DWI Preprocessing: Stage 7 - Create DTI-TK Images (DTI-TK)
#==============================================================================

if [ ${dtITK} = "true" ] && [ ! -d ${outDir}/DTI-TK ]; then
  # Uses DTI-TK to convert
  # FSL FA maps and eigenvectors
  # to DTI-TK's format.
  if [ ! -d ${outDir}/DTI-TK ]; then
    echo_blue "Making Subject DTI-TK Directory"
    run mkdir -p ${outDir}/DTI-TK
  fi

  run cd ${outDir}/Tensor
  files=( $(ls *${fit}*.nii*) )

  for file in ${files[@]}; do
    run cp -r ${file} ${outDir}/DTI-TK
  done

  run cd ${outDir}/DTI-TK
  run ${DTITKscripts}/fsl_to_dtitk ${fit}

  for file in ${files[@]}; do
    run rm ${file}
  done
fi

if [ ${dtITK} = "true" ] && [ ! -d ${outDir}/DTI-TK ]; then
  run cp -r ${work}/DTI-TK ${outDir}
fi

#
# DWI Preprocessing: Stage 9 - Clean-up (Remove subject working directory)
#==============================================================================

if [ ${cleanup} = "true" ]; then
  echo_blue "Removing subject working directory"
  run rm -rf ${work}
fi

echo "dwi_preproc completed for sub-${sub}" >> ${log}
echo_green "dwi_preproc completed for sub-${sub}"
