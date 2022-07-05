#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# DESCRIPTION:
# 
# Intended for building sphinx documentation
#   locally.

cwd=$(pwd)
wd=$(dirname $(realpath ${0}))

sphinx-apidoc -o source ../../dwi_preproc

make clean; make html

cd ${cwd}
