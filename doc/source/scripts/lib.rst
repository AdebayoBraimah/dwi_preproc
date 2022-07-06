``lib.sh`` (Bash Library Functions )
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Bash library functions that are referenced throughout the use of the pipeline.

.. code-block:: bash

  #!/usr/bin/env bash
  # -*- coding: utf-8 -*-
  # 
  # DESCRIPTION: 
  #   Bash/shell function library for logging.
  # 
  # 
  # NOTE:
  #   Google shell style guide is used here for consistency. See the 
  #   style guide here: https://google.github.io/styleguide/shellguide.html
  # 


  #######################################
  # Prints message to the command line interface
  #   in some arbitrary color.
  # Args:
  #   msg
  #######################################
  echo_color(){
    msg='\033[0;'"${@}"'\033[0m'
    echo -e ${msg} 
  }


  #######################################
  # Prints message to the command line interface
  #   in red.
  # Args:
  #   msg
  #######################################
  echo_red(){
    echo_color '31m'"${@}"
  }


  #######################################
  # Prints message to the command line interface
  #   in green.
  # Args:
  #   msg
  #######################################
  echo_green(){
    echo_color '32m'"${@}"
  }


  #######################################
  # Prints message to the command line interface
  #   in blue.
  # Args:
  #   msg
  #######################################
  echo_blue(){
    echo_color '36m'"${@}"
  }


  #######################################
  # Prints message to the command line interface
  #   in red when an error is intened to be raised.
  # Args:
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
  # Args:
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
  # Args:
  #   Command to be logged and performed.
  #######################################
  log(){
    echo "${@}"
    echo "${@}" >>${log} 2>>${err}
    echo "-----------------------"
    echo "-----------------------" >>${log} 2>>${err}
  }


  #######################################
  # Extracts and merges b0s in a dMRI volume.
  # Globals:
  #   log
  #   err
  # Required Args:
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
    local cwd=${PWD}
    local tmp_dir=$(remove_ext ${out})_tmp_${RANDOM}
    run mkdir -p ${tmp_dir}
    run cd ${tmp_dir}

    # Create mif file
    run mrconvert -fslgrad ${bvec} ${bval} ${dwi} dwi.mif

    # Extract b0s
    run dwiextract -bzero dwi.mif dwi.b0s.nii.gz

    # Merge b0s
    run fslmaths dwi.b0s.nii.gz -Tmean ${out}

    # Clean-up
    cd ${cwd}
    rm -rf ${tmp_dir}
  }


  #######################################
  # N4 retrospective bias correction algorithm.
  # Globals:
  #   log
  #   err
  # Args:
  #   Same arguments as N4BiasFieldCorrection.
  # Returns
  #   0 if no errors, non-zero on error.
  #######################################
  N4(){
    N4BiasFieldCorrection "${@}"
  }


  #######################################
  # Creates mask from b0s of a dMRI.
  # 
  # NOTE: 
  #   * Still a work in progress.
  #   * Currently not used at the moment.
  # 
  # Globals:
  #   log
  #   err
  # Args:
  #   Same arguments as N4BiasFieldCorrection.
  # Returns
  #   0 if no errors, non-zero on error.
  #######################################
  create_mask(){
    # Set defaults
    frac_int=0.25
    bias_correct="false"

    # Parse arguments
    while [[ ${#} -gt 0 ]]; do
      case "${1}" in
        -d|--dwi) shift; local dwi=${1} ;;
        -b|--bval) shift; local bval=${1} ;;
        -e|--bvec) shift; local bvec=${1} ;;
        -o|--outdir) shift; local out=${1} ;;
        --bias-correct) local bias_correct="true" ;;
        -f|-frac|--frac-int) shift; local frac_int=${1} ;;
        -*) echo_red "$(basename ${0}) | extract_b0: Unrecognized option ${1}" >&2; Usage; ;;
        *) break ;;
      esac
      shift
    done

    # Create tmp dir
    local cwd=${PWD}
    local tmp_dir=$(remove_ext ${out})_tmp_${RANDOM}
    run mkdir -p ${tmp_dir}
    run cd ${tmp_dir}

    # Extract b0s
    run extract_b0 --dwi ${dwi} --bval ${bval} --bvec ${bvec} --out b0s.nii.gz
    b0=$(realpath b0s.nii.gz)

    if [[ "${bias_correct}" = true ]]; then
      run bet ${b0} tmp -R -f 0.1 -m
      run N4 -i ${b0}.nii.gz \
      -x tmp_mask.nii.gz \
      -o "[restore.nii.gz,bias.nii.gz]" \
      -c "[50x50x50,0.001]" \
      -s 2 \
      -b "[100,3]" \
      -t "[0.15,0.01,200]"
    else
      run cp ${b0} restore.nii.gz
    fi

    # WORK IN PROGRESS
    # # Copy files with output preifx
    # run bet restore.nii.gz restore_brain -R -f ${frac_int} -m
    # run imcp restore.nii.gz ${out}/hifib0
    # run imcp restore_brain.nii.gz ${out}_hifi_brain.nii.gz
    # run imcp restore_brain_mask.nii.gz ${out}_hifi_brain_mask.nii.gz

    run cd ${cwd}

  }


  #######################################
  # xfm_tck wrapper function for the 
  # tractography python CLI. CLI options
  # are the same as the referenced command
  # line tool.
  # Globals:
  #   log
  #   err
  # Args:
  #   Same arguments as xfm_tck.py
  # Returns
  #   0 if no errors, non-zero on error.
  #######################################
  xfm_tck(){
    local scripts_dir=$(echo $(dirname $(realpath ${0})))
    # local cmd=$(realpath ${scripts_dir}/../pkgs/xfm_tck/xfm_tck.py)
    local cmd=$(realpath ${scripts_dir}/pkgs/xfm_tck/xfm_tck.py)
    run ${cmd} "${@}"
  }


  #######################################
  # dwinfo wrapper function for the 
  # python CLI. CLI options
  # are the same as the referenced command
  # line tool.
  # Globals:
  #   log
  #   err
  # Args:
  #   Same arguments as dwinfo.py
  # Returns
  #   0 if no errors, non-zero on error.
  #######################################
  dwinfo(){
    local scripts_dir=$(echo $(dirname $(realpath ${0})))
    local cmd=$(realpath ${scripts_dir}/../pkgs/dwinfo/dwinfo.py)
    run ${cmd} "${@}"
  }


  #######################################
  # ``exists`` wrapper function. Checks 
  # if the input file or directory exists.
  # If the input exists (as either a file
  # or directory), then 'True' is 
  # returned/printed to the command line.
  # If the input does not exist, then 
  # 'False' is printed to the command 
  # line.
  # 
  # Globals:
  #   log
  #   err
  # Args:
  #   Input file or directory.
  # Returns
  #   True if directory/file exists, and 
  #     False otherwise
  #######################################
  exists(){
    # Define input
    input="${1}"
    input=$(realpath ${input})

    # Check if input exists as a file or directory
    if [[ -f ${input} ]] || [[ -d ${input} ]]; then
      echo "True"
    else
      echo "False"
    fi
  }
