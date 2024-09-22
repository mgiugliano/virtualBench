#!/usr/bin/env bash

# Sets up the environment for the project
#
# Usage: bash ./setup.sh
#
# Sep 2024 - Michele Giugliano, PhD
#

# Check if the PIXI_PROJECT_ROOT is set: this means we are inside a PIXI environment
if [ -z "$PIXI_PROJECT_ROOT" ]; then
    echo ""
    echo "Error: PIXI_PROJECT_ROOT not set!"
    echo
    echo "This script must be run inside a pixi environment (as a task or through pixi shell command)!"
    echo "Otherwise, set PIXI_PROJECT_ROOT to the root of the PIXI project dir."
    echo ""
    exit
fi

# We create the necessary directories

mkdir -p $PIXI_PROJECT_ROOT/data            # data directory: contains output files, in subfolders named as the model in use
mkdir -p $PIXI_PROJECT_ROOT/.models         # models directory (hidden): contains the model files, organised in subfolders
mkdir -p $PIXI_PROJECT_ROOT/.tmp            # tmp directory (hidden): contains temporary files

LOGFILE=$PIXI_PROJECT_ROOT/.log

# Disable the cite message of parallel once for all
mkdir -p ~/.parallel
touch ~/.parallel/will-cite


DATE=$(date +"%Y-%m-%d %H:%M:%S")
echo "$DATE:  -=-=-=-=-=-=- Setup completed -=-=-=-=-=-=-" >> $LOGFILE
echo "" >> $LOGFILE

