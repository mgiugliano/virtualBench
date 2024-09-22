#!/usr/bin/env python

# cc.py
#
# Virtual CC current-clamp arbitrary stimulation experiments with NEURON
# This **miminalistic** script runs a simulation of a neuron model, injecting
# an arbitrary current waveform and obtaining the response of the model. The script
# takes three arguments the duration [ms] (or 0 for default), the waveform file name,
# and the index.
#
# Sep 2024, M. Giugliano, University of Modena and Reggio Emilia (UNIMORE)
#

# Note: input parameters
#
# - model - name of the cell model
# - duration [ms] - duration of the stimulus current waveform
# - waveform filename - the stimulus current waveform
# - index_number - index number of the stimulus current waveform


# Output files:
#
# - soma_001.dat - membrane potential of the soma
# - soma_001.dat - stimulus current waveform
# - soma_001.pdf - plot of the membrane potential and the stimulus current waveform

#
# This is largely based on the work and script of W. van Geit and the BBP team
# The original script is available in the ./tmp/model directory.
#

import os       # to create directories, run commands, etc.
import neuron   # NEURON simulator
import numpy    # numerical library for handling arrays
import sys      # to access command line arguments
from matplotlib import pyplot as plt # for plotting and saving figures

# Check the number of command line arguments --------------------------------------------
if len(sys.argv) != 5:
    print('Usage: %s modelname duration stimulus_CC_filename.dat index_number' % sys.argv[0])
    sys.exit(1)

# Get the parameters provided as command line arguments
modelname = sys.argv[1]             # name of the cell model
duration = float(sys.argv[2])       # duration of the stimulus current waveform
input_fname = sys.argv[3]           # amplitude of the stimulus current waveform
index_number = int(sys.argv[4])     # index

recordings_dir = '../../data/' + modelname + '/CC' # directory to save the recordings
stimuli_dir = '../../data/'
#-----------------------------------------------------------------------------------------

# Load NEURON libraries - initialization -----------------------------------------------
neuron.h.load_file("stdrun.hoc")        # load NEURON libraries for simulations
neuron.h.load_file("import3d.hoc")      # load NEURON libraries for importing 3D morphologies

T0 = 250.0  # start time of the stimulus
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

input_fname = os.path.join(stimuli_dir, input_fname)
fileobj = neuron.h.File()
fileobj.ropen(input_fname)
iext = neuron.h.Vector()
iext.scanf(fileobj)
# Let's change the very last value of the input current to 0
iext.x[-1] = 0

iclamp0 = neuron.h.IClamp(0.5, sec=cell.soma[0])
iclamp0.delay = 0.
iclamp0.dur = T0
iclamp0.amp = 0.

stimuli.append(iclamp0)

iclamp1 = neuron.h.IClamp(0.5, sec=cell.soma[0])
iclamp1.delay = T0
iclamp1.dur = len(iext) * neuron.h.dt
iclamp1.amp = 0.
iext.play(iclamp1._ref_amp, neuron.h.dt)

stimuli.append(iclamp1)

iclamp2 = neuron.h.IClamp(0.5, sec=cell.soma[0])
iclamp2.delay = T0 + len(iext) * neuron.h.dt
iclamp2.dur = 2 * T0
iclamp2.amp = 0.

stimuli.append(iclamp2)



# Create recordings ----------------------------
recordings = {}

recordings['time'] = neuron.h.Vector()
recordings['soma(0.5)'] = neuron.h.Vector()
recordings['stimulus'] = neuron.h.Vector()

recordings['time'].record(neuron.h._ref_t, 0.1)
recordings['soma(0.5)'].record(cell.soma[0](0.5)._ref_v, 0.1)
recordings['stimulus'].record(iclamp1._ref_i, 0.1)

# Run simulation ------------------------------
if duration == 0:        # if duration is negative, use the length of the input file
    duration = (len(iext) * neuron.h.dt)

neuron.h.tstop = duration + 3 * T0
neuron.h.cvode_active(0)

neuron.h.run()

# Save recordings ------------------------------
time = numpy.array(recordings['time'])
soma_voltage = numpy.array(recordings['soma(0.5)'])
stimulus = numpy.array(recordings['stimulus'])

if not os.path.exists(recordings_dir):
    os.makedirs(recordings_dir)

soma_voltage_filename = os.path.join(
    recordings_dir,
    'soma_%03d.dat' % index_number)
numpy.savetxt(
    soma_voltage_filename,
    numpy.column_stack((time,soma_voltage,stimulus))
)

# Plot and save the figure ------------------------------
plt.style.use('./stylelib/dracula.mplstyle')
# Two subplots, the axes array is 1-d
f, axarr = plt.subplots(2, sharex=True)
axarr[0].plot(time, soma_voltage, linewidth=0.5)
#axarr[0].set_title('soma [%s]' % cellname)
axarr[0].set_ylabel('Membrane Potential (mV)')
axarr[0].set_ylim([-85, 40])
axarr[0].grid(True, which='both', linewidth=0.1, color='gray')
axarr[0].text(.01, .99, modelname, ha='left', va='top', transform=axarr[0].transAxes, fontsize=5)

axarr[1].plot(time, stimulus * 1e3, linewidth=0.5)
axarr[1].set_ylabel('Input Current (pA)')
axarr[1].set_xlabel('Time (ms)')
axarr[1].set_ylim([-500, 2000])
#axarr[1].set_title(f'{modelname} - DC step   {amplitude:.4f} nA')
axarr[1].grid(True, which='both', linewidth=0.1, color='gray')

stim_fname = sys.argv[3].split('/')[-1]

axarr[1].text(.01, .99, 'CC ' + stim_fname, ha='left', va='top', transform=axarr[1].transAxes, fontsize=5)
plt.xlabel('Time (ms)')

f.tight_layout()

# filename with format soma_001.pdf, soma_002.pdf, etc.
filename = os.path.join(recordings_dir, 'soma_%03d.pdf' % index_number)
plt.savefig(filename)

# End of the script ------------------------------
# The script is now ready to be run by the pixi task
