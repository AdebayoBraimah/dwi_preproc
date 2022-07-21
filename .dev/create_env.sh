#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

# DESCRIPTION:
#   Creates a python virtual environment for development of this package
#   (installed via Anaconda). The environment is intended to have no default
#   packages.
# 
# USAGE:
#   cd .dev; ./create_env.sh
# 
# NOTE:
#   * Intended to be run from the main directory level.
#   * Currently only works with Anaconda.
#   * Environment setup is for python v3+.
#   * If using a machine without administrative privileges, use ``--user`` 
#       flag during the ``pip install`` step.
#   * Change shebang to preferred shell (e.g. 'bash', 'zsh', 'csh', etc).
#     * Change conda init shell to matching shell 

cwd=$(pwd)
scriptdir=$(realpath $(dirname ${0}))

cd ${scriptdir}

if [[ ! -d ../.env ]]; then
  mkdir -p ../.env
fi

envpath=$(realpath ../.env)

# Create environment using conda
conda create -p ${envpath}/env --no-default-packages --yes

# Activate environment
conda activate ${envpath}/env
conda init zsh # Do not copy if copying and pasting to CLI

# Install pip
conda install pip --yes

# Install requirements
pip install -r requirements.txt
