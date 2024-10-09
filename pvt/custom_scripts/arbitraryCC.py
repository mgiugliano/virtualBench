#!/usr/bin/env python

# arbitraryCC.py
#
# Virtual current-clamp stimulation experiments with NEURON
# This **miminalistic** script runs a simulation of a neuron model, responding to
# an arbitrary waveform injected somatically as a current stimulus. The script 
# takes the filename of the stimulus from the command line, and it saves the 
# voltage trace of the soma and the stimulus current to files.
#
# Sep 2024, M. Giugliano, University of Modena and Reggio Emilia (UNIMORE)
#

# Note: input parameters
#
# - filename of the stimulus current waveform (values in nA, one per line, in a 
# text file, assuming the time step is 0.025 ms exactly as in the simulation)
#

# This is largely based on the work and script of W. van Geit and the BBP team
# The original script is available in the ./tmp/model directory.
#

import os       # to create directories, run commands, etc.
import neuron   # NEURON simulator
import numpy    # numerical library for handling arrays
import sys      # to access command line arguments
import json     # to read the cell info from a json file
from matplotlib import pyplot as plt # for plotting and saving figures

# Check the number of command line arguments --------------------------------------------
if len(sys.argv) != 3:
    print('Usage: %s stimulus_CC_filename.dat index_number' % sys.argv[0])
    sys.exit(1)

# Get the parameters provided as command line arguments
input_fname = sys.argv[1]       # filename of the stimulus current waveform
index_number = int(sys.argv[2])             # index 
#-----------------------------------------------------------------------------------------


# Open the json file and load the data - THIS IS CURRENTLY NOT USED
with open('cellinfo.json') as f:
    config = json.load(f)
me_type = config['me-type'] # morphoelectric type (worth indicating in the figures?)


# Load NEURON libraries - initialization -----------------------------------------------
neuron.h.load_file("stdrun.hoc")        # load NEURON libraries for simulations
neuron.h.load_file("import3d.hoc")      # load NEURON libraries for importing 3D morphologies

celsius=34  # temperature in celsius (as in the BBP original script)
dt=0.025    # time step in ms (as in the BBP original script)

# There are 5 main steps in the script:
#- create cell
#- create stimuli
#- create recordings
#- run simulation
#- save recordings

# Create the cell model ----------------------------
neuron.h.load_file("morphology.hoc")
neuron.h.load_file("biophysics.hoc")
neuron.h.load_file("template.hoc")

# Get the cell name from the file cellname.txt
# This file is created by the pixi run bootstrap task and it is
# required to avoid hardcoding the cell name in the script.
cellname = open('cellname.txt', 'r').read().strip()

add_synapses = False
cmd = 'cell = neuron.h.' + cellname + '(1 if add_synapses else 0)'
exec(cmd)
#cell = neuron.h.cADpyr232_L5_TTPC1_fc944c2cf3(1 if add_synapses else 0)

# Create the stimuli ------------------------------
stimuli = []

fileobj = neuron.h.File()
fileobj.ropen(input_fname)
iext = neuron.h.Vector()
iext.scanf(fileobj)

duration = (len(iext) * neuron.h.dt)

iclamp = neuron.h.IClamp(0.5, sec=cell.soma[0])
iclamp.delay = 0.
iclamp.dur = duration 
iclamp.amp = 0.

iext.play(iclamp._ref_amp, neuron.h.dt)

stimuli.append(iclamp)
fileobj.close()

# Create recordings ----------------------------
recordings = {}

recordings['time'] = neuron.h.Vector()
recordings['soma(0.5)'] = neuron.h.Vector()
recordings['stimulus'] = neuron.h.Vector()

recordings['time'].record(neuron.h._ref_t, 0.1)
recordings['soma(0.5)'].record(cell.soma[0](0.5)._ref_v, 0.1)
recordings['stimulus'].record(iclamp._ref_i, 0.1)

# Run simulation ------------------------------
neuron.h.tstop = duration
neuron.h.cvode_active(0)

neuron.h.run()

# Save recordings ------------------------------
time = numpy.array(recordings['time'])
soma_voltage = numpy.array(recordings['soma(0.5)'])
stimulus = numpy.array(recordings['stimulus'])

recordings_dir = '../../traces'
if not os.path.exists(recordings_dir):
    os.makedirs(recordings_dir)

soma_voltage_filename = os.path.join(
    recordings_dir,
    'somaV_%03d.dat' % index_number)
numpy.savetxt(
    soma_voltage_filename,
    numpy.column_stack((time,soma_voltage))
)

stimulus_filename = os.path.join(
    recordings_dir,
    'stimI_%03d.dat' % index_number)
numpy.savetxt(
    stimulus_filename,
    numpy.column_stack((time,stimulus))
)

# Plot and save the figure ------------------------------
plt.style.use('./dracula.mplstyle')
# Two subplots, the axes array is 1-d
f, axarr = plt.subplots(2, sharex=True)
axarr[0].plot(time, soma_voltage, linewidth=0.5)
axarr[0].set_title('soma [%s]' % cellname)
axarr[0].set_ylabel('Membrane Potential (mV)')
axarr[0].set_ylim([-85, 40])
axarr[0].grid(True, which='both', linewidth=0.1, color='gray')


axarr[1].plot(time, stimulus, linewidth=0.5)
axarr[1].set_ylabel('Input Current (nA)')
axarr[1].set_xlabel('Time (ms)')
axarr[1].set_ylim([-1, 3])
axarr[1].set_title(input_fname)
axarr[1].grid(True, which='both', linewidth=0.1, color='gray')
plt.xlabel('Time (ms)')

# filename with format soma_001.pdf, soma_002.pdf, etc.
filename = os.path.join(recordings_dir, 'soma_%03d.pdf' % index_number)
plt.savefig(filename)

# End of the script ------------------------------
# The script is now ready to be run by the pixi run task