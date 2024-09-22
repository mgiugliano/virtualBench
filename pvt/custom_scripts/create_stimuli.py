#!/usr/bin/env python

# create_stimuli.py
#
# Sep 2024, M. Giugliano, University of Modena and Reggio Emilia (UNIMORE)
#

import os       # to create directories, run commands, etc.
import numpy    # numerical library for handling arrays
import sys      # to access command line arguments

dt = 0.025  # time step in ms (as in the BBP original script)
f  = 10. / 1000. # frequency in kHz

# Check the number of command line arguments --------------------------------------------
if len(sys.argv) != 3:
    print('Usage: %s duration amplitude' % sys.argv[0])
    sys.exit(1)

# Get the parameters provided as command line arguments
duration = float(sys.argv[1]) / dt
amplitude = float(sys.argv[2])
#-----------------------------------------------------------------------------------------

# Create the stimulus waveform
N = int(duration)
stimulus = numpy.zeros(N)

for i in range(N):
    stimulus[i] = amplitude * numpy.cos(2 * numpy.pi * f * i * dt )
    #stimulus[i] = 0 + amplitude * (i-1) / N


# Save the stimulus waveform to a file
numpy.savetxt('stimulus_CC.dat', stimulus, fmt='%.6f')


