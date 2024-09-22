#! /usr/bin/env bash

# This script generates the commands to run the virtual experiments
# We ask the user to provide the range for the mean current and the number of repetitions

#
# Sep 2024, M. Giugliano, University of Modena and Reggio Emilia (UNIMORE)
#

# PARAMETERS TO BE MODIFIED BY THE USER (if needed)
tau=1 # autocorrelation time constant (ms)
dur=1000 # duration of the experiment (ms)

# DO NOT MODIFY THE FOLLOWING LINES
CMD="python expe.py" # command to run the experiment

if [ -f ./tmp/commands.sh ]; then
    rm ./tmp/commands.sh
fi

if [-f ./traces/files_map.dat ]; then
    rm ./traces/files_map.dat
fi

echo ""
echo "Welcome to the virtual experiments generator!"
echo "This generates the commands to later run (in parallel) as a virtual experiment..."
# Ask the user for the range of the mean current
#echo "Enter the range of the mean current: min max step (e.g. 0.1 0.5 0.1)"
#read -r min max step

echo "Enter a series of mean currents (nA) separated by spaces (e.g. 0.1 0.2 0.3)"
read -r mean_currents

# Ask the user for the range of the standard deviation of the current
#echo "Enter the range of the standard deviation of the current: min max step (e.g. 0.1 0.5 0.1)"
#read -r min_std max_std step_std

echo "Enter a series of standard deviations of the current (nA) separated by spaces (e.g. 0.1 0.2 0.3)"
read -r std_currents


# Ask the user for the number of repetitions
echo "Enter the number of repetitions"
read -r repetitions

# Generate the commands
#for i in $(seq $min $step $max)
#do
#    for j in $(seq $min_std $step_std $max_std)
#    do
#        for k in $(seq 1 $repetitions)
#        do
#            echo "python3 expe.py $i $j $k $tau $index" >> commands.txt
#            index=$((index+1))
#        done
#    done
#done

index=1 # starting value for the "index" variable

for i in $mean_currents  # Loop over the mean currents specified by the user
do
    for j in $std_currents # Loop over the standard deviations specified by the user
    do
        for k in $(seq 1 $repetitions) # Loop over the repetitions
        do
            echo "$CMD $dur $i $j $tau $index > /dev/null" >> ./tmp/commands.sh
            echo "$index $i $j $tau" >> ./traces/files_map.dat
            index=$((index+1))
        done
    done
done

echo "$((index-1)) Commands generated in ./tmp/commands.sh"
echo "Files map generated in ./traces/files_map.dat"
echo ""
echo "You can now run the (virtual) experiments by executing the following command:"
echo "pixi run runme"
echo ""
# End of the script

