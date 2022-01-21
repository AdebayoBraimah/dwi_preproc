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
# Arguments:
#   msg
#######################################
echo_color(){
  msg='\033[0;'"${@}"'\033[0m'
  echo -e ${msg} 
}


#######################################
# Prints message to the command line interface
#   in red.
# Arguments:
#   msg
#######################################
echo_red(){
  echo_color '31m'"${@}"
}


#######################################
# Prints message to the command line interface
#   in green.
# Arguments:
#   msg
#######################################
echo_green(){
  echo_color '32m'"${@}"
}


#######################################
# Prints message to the command line interface
#   in blue.
# Arguments:
#   msg
#######################################
echo_blue(){
  echo_color '36m'"${@}"
}


#######################################
# Prints message to the command line interface
#   in red when an error is intened to be raised.
# Arguments:
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
# Arguments:
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
# Arguments:
#   Command to be logged and performed.
#######################################
log(){
  echo "${@}"
  echo "${@}" >>${log} 2>>${err}
  echo "-----------------------"
  echo "-----------------------" >>${log} 2>>${err}
}
