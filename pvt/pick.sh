#!/usr/bin/env bash

# Usage: bash pick.sh [modelName] - installs a given model from BBP model cells db
# (note: the provided model name as input argument is optional)
#
# Sep 2024, M. Giugliano, University of Modena and Reggio Emilia (UNIMORE)

# NMC Portal BBP cells database (rat somatosensory cortex)
#
# Check if the PIXI_PROJECT_ROOT is set: this means we are inside a PIXI environment
if [ -z "$PIXI_PROJECT_ROOT" ]; then
    echo ""
    echo "ERROR: PIXI_PROJECT_ROOT not set!"
    echo
    echo "This script must be run inside a pixi environment (as a task or through pixi shell command)!"
    echo "Otherwise, set PIXI_PROJECT_ROOT to the root of the PIXI project dir."
    echo ""
    exit
fi

# Default folders, files, and URLs
ASSETSURL=https://bbp.epfl.ch/nmc-portal/assets/documents/static/downloads-zip
FNAMES=$PIXI_PROJECT_ROOT/pvt/BBP_cells.txt
DFNAMES=$PIXI_PROJECT_ROOT/pvt/decorated_BBP_cells.txt
MODELDIR=$PIXI_PROJECT_ROOT/.models
MODS=$PIXI_PROJECT_ROOT/pvt/custom_mods
SCRIPTS=$PIXI_PROJECT_ROOT/pvt/custom_scripts
LOGFILE=$PIXI_PROJECT_ROOT/.log

# Check if the user provided a model name as input argument...
if [ $# -eq 0 ]; then
    echo "No model provided."
    echo "Fuzzy-search and pick up your favourite (note: [e]=excitatory [i]=inhibitory)..."
    CHOICE=$(fzf --preview-window=hidden --no-multi --border --ansi --prompt='  ▶  ' --reverse --height=90% --info=hidden < $DFNAMES)
    MODEL=$(echo $CHOICE | awk '{print $1}')
    # By definition, the model exists also in the list of models in ./pvt/BBP_cells.txt
else

    # We check whether the provided model name is in the list of models in ./pvt/BBP_cells.txt
    if ! grep -q $1 $FNAMES; then
        echo "ERROR: model $1 not found!"
        exit
    fi
    MODEL=$1
fi


# We then check whether $MODEL is already installed
if [ -d "$MODELDIR/$MODEL" ]; then
    rm -f $MODELDIR/mymodel
    ln -s $MODELDIR/$MODEL $MODELDIR/mymodel
    echo "$MODEL is already installed and it has been made the current one!"
    echo "To re-install it, please type:   rm -rf ./.model/$MODEL  and run again this task."
    DATE=$(date +"%Y-%m-%d %H:%M:%S")
    echo "" >> $LOGFILE
    echo "$DATE:  $MODEL selected ($CELLNAME)" >> $LOGFILE
    echo "$DATE:  $MODEL selected ($CELLNAME)"
    exit
else
    echo "Installing model $MODEL..."
    if [ ! -d "$MODELDIR" ]; then
        echo "WARNING: Creating ex novo $MODELDIR..."
        mkdir -p $MODELDIR
    fi
    curl --progress-bar -o $MODELDIR/$MODEL.zip $ASSETSURL/$MODEL.zip
    unzip -q $MODELDIR/$MODEL.zip -d $MODELDIR
    rm -f $MODELDIR/$MODEL.zip
    rm -f $MODELDIR/mymodel
    ln -s $MODELDIR/$MODEL $MODELDIR/mymodel

    # Install custom mechanisms and scripts (if any) in the model's mechanisms/ folder
    #cp $PIXI_PROJECT_ROOT/pvt/custom_mods/*.mod $MODELDIR/mymodel/mechanisms
    #cp $PIXI_PROJECT_ROOT/pvt/custom_scripts/*.py $MODELDIR/mymodel/

    # Create a symbolic link to the pvt/custom_scripts folder for the current model
    # for each of the python scripts in the pvt/custom_scripts folder

    for f in $SCRIPTS/*.py; do
        rm -f $MODELDIR/mymodel/$(basename $f)
        ln -s $f $MODELDIR/mymodel/$(basename $f)
    done

    # Create a symbolic link to the pvt/custom_mods folder for the current model

    for f in $MODS/*.mod; do
        rm -f $MODELDIR/mymodel/mechanisms/$(basename $f)
        ln -s $f $MODELDIR/mymodel/mechanisms/$(basename $f)
    done

    # Compile the mechanisms
    cd $MODELDIR/mymodel/
    nrnivmodl mechanisms > /dev/null 2>&1 # suppress output, including errors and warnings
    cd $PIXI_PROJECT_ROOT

    # Let's extract from the template.hoc file the name of the cell (this allows automation)
    grep 'begintemplate' $MODELDIR/mymodel/template.hoc | awk '{print $2}' > $MODELDIR/mymodel/cellname.txt
    CELLNAME=$(cat $MODELDIR/mymodel/cellname.txt)

    mkdir -p $MODELDIR/mymodel/stylelib # create the stylelib folder
    cp $PIXI_PROJECT_ROOT/pvt/stylelib/* $MODELDIR/mymodel/stylelib/

    # Let's update the log file - use date format like 2024-09-30T12:00:00

    DATE=$(date +"%Y-%m-%d %H:%M:%S")
    echo "" >> $LOGFILE
    echo "$DATE:  $MODEL installed and selected ($CELLNAME)" >> $LOGFILE
    echo "$DATE:  $MODEL installed and selected ($CELLNAME)"
fi
