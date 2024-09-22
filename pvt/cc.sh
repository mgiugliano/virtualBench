#! /usr/bin/env bash

# CC arbitrary current injection virtual experiments generator

#
# Sep 2024, M. Giugliano, University of Modena and Reggio Emilia (UNIMORE)
#

# Clear the screen
#clear

# PARAMETERS TO BE MODIFIED BY THE USER (if needed)
# dur=1000 # duration of the experiment (ms)


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



MODELNAME=$(basename "$(readlink -f .models/mymodel)")
# if this is empty, no model has been previously selected by the user
if [ -z "$MODELNAME" ]; then
    echo ""
    echo "ERROR: No model selected!"
    echo
    echo "Please pick up a model, by:"
    echo "pixi run pick"
    echo ""
    exit
fi


TMPDIR=$PIXI_PROJECT_ROOT/.tmp
LOGFILE=$PIXI_PROJECT_ROOT/.log
MODELDIR=$PIXI_PROJECT_ROOT/.models

# User provides as input name of the stimulus file (or folder containing stimulus files)

input=$PIXI_PROJECT_ROOT/data/$1
if [ -z $input ]; then
    echo "Please provide the name of the stimulus file (or folder containing stimulus files)."
    exit
fi

# Check if the input is a file or a folder
if [ -f $input ]; then
    files=$input
    Nfiles=1
    DATA=$PIXI_PROJECT_ROOT/data/$MODELNAME/CC
elif [ -d $input ]; then
    # Let's put into an array all the file names in the folder
    files=($input/*)       # entries include the full path and exclude . and ..
    Nfiles=${#files[@]}
    DATA=$PIXI_PROJECT_ROOT/data/$MODELNAME/CC/$(basename $input)
else
    echo "The input is not a valid file or folder."
    exit
fi


# DO NOT MODIFY THE FOLLOWING LINES
if [ ! -d $DATA ]; then
    mkdir -p $DATA
fi

if [ ! -d $TMPDIR ]; then
    mkdir -p $TMPDIR
fi

if [ -f $TMPDIR/commands.sh ]; then
    rm -f $TMPDIR/commands.sh
fi

# remove the files_map.dat file if it exists

if [ -f $DATA/files_map.dat ]; then
    rm -f $DATA/files_map.dat
fi

echo "CC arbitrary current protocol."
# Ask the user for the range of the mean current
read -p "Enter stim duration [ms] (enter for default) : " -r dur

if [[ -z $dur ]]; then
    dur=0
fi

CMD="python cc.py $MODELNAME $dur" # command to run the experiment
# - model - name of the cell model
# - duration [ms] - duration of the stimulus current waveform
# - waveform file - stimulus current waveform
# - index_number - index number of the stimulus current waveform



index=1 # starting value for the "index" variable

# Generate the commands - one for each current injection waveform
# The for loop is from 1 to Nfiles, because the index starts from 1
for i in $(seq 1 $Nfiles)
do
   echo "$CMD ${files[$i-1]} $index > /dev/null" >> $TMPDIR/commands.sh
   echo "$index ${files[$i-1]}" >> $TMPDIR/files_map.dat
   index=$((index+1))
done

echo "$((index-1)) simulations scheduled."

echo "Selected model:   $MODELNAME"
echo "Data saved in:    $DATA"
echo "input file(s):    $input"

read -p "Proceed? [Y/n] " -n 1 -r answer
echo    # (optional) move to a new line

if [[ $answer =~ ^[Yy]$ ]] || [[ -z $answer ]]; then
    echo "Running simulations..."
    rm -f $DATA/*.dat $DATA/*.pdf $DATA/.*.dat
    mv $TMPDIR/files_map.dat $DATA
    cd $MODELDIR/$MODELNAME
    parallel --bar -a $TMPDIR/commands.sh
    cd $PIXI_PROJECT_ROOT
    echo "Done! Find results in $DATA"
    DATE=$(date +"%Y-%m-%d %H:%M:%S")
    echo "" >> $LOGFILE
    echo "$DATE:  $MODEL CC with $input ($CELLNAME)" >> $LOGFILE
    echo "$DATE:  $MODEL CC with $input ($CELLNAME)"
else
    echo "Aborted."
    exit
fi
