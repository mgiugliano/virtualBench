#! /usr/bin/env bash

# DC step current injection virtual experiments generator

#
# Sep 2024, M. Giugliano, University of Modena and Reggio Emilia (UNIMORE)
#

# Clear the screen
#clear

# PARAMETERS TO BE MODIFIED BY THE USER (if needed)
# dur=100 # duration of the experiment (ms)


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
DATA=$PIXI_PROJECT_ROOT/data/$MODELNAME/DC
MODELDIR=$PIXI_PROJECT_ROOT/.models

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


echo "DC step-current protocol."
# Ask the user for the range of the mean current
read -p "Enter stim duration [ms] (e.g. 100) : " -r dur

if [[ -z $dur ]]; then
    echo "Default stim duration chosen: 100 ms"
    dur=100
fi

# DO NOT MODIFY THE FOLLOWING LINES
CMD="python dc.py $MODELNAME" # command to run the experiment
# - model - name of the cell model
# - duration [ms] - duration of the stimulus current waveform
# - amplitude [nA] - amplitude of the stimulus current waveform
# - index_number - index number of the stimulus current waveform


read -p "Enter sweep [nA] as: min max step (e.g. -0.1 0.5 0.05) : " -r min max step

if [[ -z $min ]] || [[ -z $max ]] || [[ -z $step ]]; then
    echo "Default sweep chosen: -0.1 0.5 0.05 nA"
    min=-0.1
    max=0.5
    step=0.05
fi


index=1 # starting value for the "index" variable

# Generate the commands
for i in $(seq $min $step $max)
do
   echo "$CMD $dur $i $index > /dev/null" >> $TMPDIR/commands.sh
   #echo "$CMD $dur $i $index" >> $TMPDIR/commands.sh
   echo "$index $i" >> $TMPDIR/files_map.dat
   index=$((index+1))
done

echo "$((index-1)) simulations scheduled."
echo "Selected model:   $MODELNAME"
echo "DC stim duration: $dur ms"
echo "Data saved in:    $DATA"
echo ""

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
    echo "$DATE:  $MODEL DC with $min $max $step nA  and $dur ms ($CELLNAME)" >> $LOGFILE
    echo "$DATE:  $MODEL DC with $min $max $step nA  and $dur ms ($CELLNAME)"
else
    echo "Aborted."
    exit
fi
