#!/usr/bin/env python

# Generate "decorated" names from each of BBP cell filenames.

import os
import sys
import json

# Let's get the list of BBP cells filenames as input argument
if len(sys.argv) != 2:
    print('Usage: python fnames_curation.py <path_to_BBP_cells_list>')
    sys.exit(1)

with open(sys.argv[1], 'r') as f:
    filenames = f.readlines()

# Each filename is a string with the following structure:
# L5_TTPC1_cADpyr232_2.zip (.zip has been removed)

# Dictionaries to explain the meaning of each part of the filename
layers = {
    'L1': 'Layer 1',
    'L23': 'Layer 2/3',
    'L4': 'Layer 4',
    'L5': 'Layer 5',
    'L6': 'Layer 6'
}

m_types = {
    'DAC': '[i] Descending Axon c.',
    'NGC-DA': '[i] Neurogliaform c. with dense axonal arborization',
    'NGC-SA': '[i] Neurogliaform c. with slender axonal arborization',
    'HAC': '[i] Horizontal Axon c.',
    'LAC': '[i] Large Axon c.',
    'DLAC': '[i] Dense Local Arborizing c.',
    'SAC': '[i] Small Axon c.',
    'SLAC': '[i] Sparse Local Arborizing c.',
    'MC': '[i] Martinotti c.',
    'BTC': '[i] Bitufted c.',
    'DBC': '[i] Double Bouquet c.',
    'BP': '[i] Bipolar c.',
    'NGC': '[i] Neurogliaform c.',
    'LBC': '[i] Large basket c.',
    'NBC': '[i] Nest basket c.',
    'SBC': '[i] Small basket c.',
    'ChC': '[i] Chandelier c.',

    'PC': '[e] Pyramidal c.',
    'SP': '[e] Star Pyramidal c.',
    'SS': '[e] Spiny Stellate c.',
    'TTPC1': '[e] Thick-tufted Pyramidal c. (late bifurcating apical tuft)',
    'TTPC2': '[e] Thick-tufted Pyramidal c. (early bifurcating apical tuft)',
    'UTPC': '[e] Untufted pyramidal c.',
    'STPC': '[e] Slender tufted pyramidal c.',
    'TPC_L4': '[e] Tufted Pyramidal c. with dendritic tuft terminating in layer 4',
    'TPC_L1': '[e] Tufted Pyramidal c. with dendritic tuft terminating in layer 1',
    'IPC': '[e] Pyramidal c. with inverted apical-like dendrites',
    'BPC': '[e] Pyramidal c. with bipolar apical-like dendrites',
}

e_types = {
    'cAC': 'Continuous Accommodating',
    'bAC': 'Burst Accommodating',
    'cNAC': 'Continuous Non-accommodating',
    'bNAC': 'Burst Non-accommodating',
    'dNAC': 'Delayed Non-accommodating',
    'cAD': 'Continuous Adapting',
    'bIR': 'Burst Irregular',
    'cIR': 'Continuous Irregular',
    'dSTUT': 'Delayed Stuttering',
    'bSTUT': 'Burst Stuttering',
    'cSTUT': 'Continuous Stuttering',
}

# Let's now generate the decorated names

# Let's open a file to write the decorated names
fp = open('./decorated_BBP_cells.txt', 'w')

for filename in filenames:
    # Remove the newline character
    filename = filename.strip()
    # Split the filename into its components
    parts = filename.split('_')

    if len(parts) == 4:
        layer = parts[0] # e.g. L5
        m_type = parts[1] # e.g. TTPC1
        e_type = parts[2] # e.g. cADpyr232
        instance = parts[3].split('.')[0] # e.g. 2 (without .zip)
    else:
        layer = parts[0] # e.g. L5
        m_type = f'{parts[1]}_{parts[2]}' # e.g. TPC_L4
        e_type = parts[3] # e.g. cADpyr232
        instance = parts[4].split('.')[0] # e.g. 2 (without .zip)

    # e_type contains the e-type and the cell number, so we need to search which key of the dictionary is the most similar to the first characters of the e_type

    for key in e_types.keys():
        if key in e_type:
            e_type1 = key
            break

    #decorated_name = f'{layers[layer]}: {m_types[m_type]} -- {e_types[e_type1]} (#{instance})'
    decorated_name = f'{layers[layer]} -- {m_types[m_type]} -- {e_types[e_type1]}'
    fp.write(filename + ' ::: ' + decorated_name + '\n')
    #jprint(filename)
    #print(decorated_name)
    #print("Press Enter to continue...")
    #input()
fp.close()


