# Virtual Bench

Sep 2024 - Michele Giugliano, Univ. of Modena and Reggio Emilia, Italy

## Welcome!

This is my own exercise in minimalism and user experience simplicity, to
simulate an in vitro experiment of cellular electrophysiology.
It is based on Python, on the NEURON simulator, and on the models released
by the Blue Brain Project (BBP) a few years ago claiming to capture the
morphoelectrical phenotype of rat cortical neurons of the somatosensory
cortex.

It makes possible for the user, with little or no experience in Computational
Neuroscience, to mimic the typical steps of an experiment, from the choice of
the neuron model and the recording of its (somatic) membrane potential, to the
design and choice of the stimulus waveform, simulating current-clamp and
conductance-clamp paradigms.

Some pointers and links are provided below, in case you are interested in
learning more about the tools used here:

  - [NEURON simulator](https://neuron.yale.edu/neuron/)
  - [Blue Brain Project](https://bbp.epfl.ch/nmc-portal/welcome.html)
  - [NMC portal of BBP](https://bbp.epfl.ch/nmc-portal/welcome.html)
  - [GNU parallel](https://www.gnu.org/software/parallel/)
  - [pixi](https://prefix.dev)



## pixi and the command line

The use of a terminal emulator and of the *bash shell* is the only way to carry
out the simulations.

The environment is managed by *pixi*, a package manager that allows one
to define and run *tasks* in a declarative way. The tasks are defined in a file
called *pixi.toml* and they are run by invoking the command *pixi run taskname*
from the command line. The tasks simplify the user experience and hide
the complexity of the underlying software and libraries.

As pixi is cross-platform, the same commands can be run on different operating
systems (e.g. MacOS, Linux, Windows) without any modification. The only requirement
is that the software and libraries are made available for the specific platform by
Conda-forge and PyPi.

The use of a minimalistic command line interface is powerful and flexible and
allows scripting and automation.



## Introduction and Typical workflow

After all (pixi and pixi install) installation steps are done, run the *setup* task.
This creates a series of folders (some are hidden) where models files are downloaded
and where input waveforms and output results are saved.

A typical workflow is

  1. choose and download the model (from the BBP cells database)
  2. (optionally) generate the stimuli to be injected and finally
  3. run the (desired) task to launch simulation(s) in parallel

```bash
  pixi run pick
  pixi run dc
```

Every time the *pick* task is launched, the user can choose a different model
from a list of all available models (i.e. 207 morpholectric cell types, with
5 sample instances for each one, resulting in over 1'000 models).
If the model has never been downloaded before, it will be automatically
downloaded from the BBP database (i.e. the NMC portal). The user can also indicate
explicitly the model's name, providing it as an argument:

```bash
pixi run pick L5_STPC_cADpyr232_2
```

When no argument is provided, the task will spawn a fuzzy search, text-based,
interface with a list of available models. This search is based on the filename
as well as description of the models available in the BBP-NMC database. It allows
to quickly spot the desired cell by layer, morphological type, electrophysiological
type, cell name, excitatory/inhibitory type, in a free-form fuzzy search.

Note that only one model can be *selected* at any given time. The model of choice
becomes the *current* model and all the simulated stimulation protocols are applied
to such a model.

Behind the scenes, every time *pick* is run successfully, a symbolic link to the
chosen model's folder (stored in the hidden subfolder /.models) is updated
and the model files are downloaded and *compiled*, unless it was already done.
Models are stored in subfolders named after the model names, containing the model
files, the (to be compiled) mod files, the reconstructed morphology of
the cell, its biophysical parameters, and the scripts to run the simulations.

Additional mechanisms and simulation scripts are automatically inserted in each
model subfolder, so that the same protocol can be applied seamlessly to different
models.

In fact, simulation types correspond to custom python scripts that are copied
(at the time of model selection) from the ./pvt folder to the model
folder. For instance, the script called "cc.py" allows to run a current-clamp
experiment injecting an arbitrary waveform as current stimulus while recording the
cell response. The stimulus file(s) must be in the ./data folder and be indicated
by the user. Other scripts include "gc.py" that allows to run a conductance-clamp
experiment, or the very basic "dc.py" that allows to inject step currents and
test the response of the cell.

These scripts are however "hidden" from the user, who only interacts with the
task-interface of pixi (e.g. pixi run cc). The user can of course modify the
scripts, or add new ones, to customise the simulations. The scripts are written
in Python and they use the NEURON simulator to run the simulations. Python and
the NEURON simulator are installed by pixi, and they are made available to the
tasks by the pixi environment. All the required libraries are also installed
by pixi, and even command line tools such as GNU parallel and fzf are installed
automatically by pixi.


## Installing pixi on your machine

*pixi* (see https://prefix.dev) is a new cross-platform package manager that is
folder-oriented and solves both the problem of packages install and environment
specification. It is based on declarative and explicit configuration and it is
used to recreate a reproducible environment, including all the required libraries
and software tools, (including Python!).


**Note:** you may have to tweak *pixi.toml* in the "platforms" field (currently set only to
["osx-arm64"]). For instance, you might want to replace it with your platform or add
your platform to the list, e.g. ["osx-arm64", "osx-x86_64", "linux-x86_64", "win-x86_64"].
As I am new to pixi, I am not sure if this is the best way to handle multiple platforms
and I am open to suggestions and improvements.


For this project, these are:
  - python3, numpy, matplotlib
  - the NEURON simulator
  - GNU parallel
  - fzf

Installing pixi does not interfere with system-wide tools and can be done by

```bash
    curl -fsSL https://pixi.sh/install.sh | bash
```

Refer to pixi's website for alternative methods (e.g. homebrew).



## Bootstrapping the simulation environment

Clone this repository, e.g. by

```bash
  git clone https://github.com/mgiugliano/virtualBench
```

and then move to the folder "virtualBench" by typing

```bash
  cd virtualBench
```

Now bootstrap the simulation environment, by typing

```bash
  pixi install
```

The step completed by the "install" command are precisely defined in a declaratively
way, in the pixi.toml configuration file.












Next, bootstrap the simulation environment, to study in silico the response
of a conductance-based detailed neuron model of (e.g.) L5 pyramidal cell, by:

```bash
  pixi run bootstrap
```

Finally, preparing a (series of) simulations aimed at exploring multiple combinations
of mean and standard deviation of the noisy somatic injected current, use:

```bash
  pixi run sweep
```

This creates a text file (called *./tmp/commands.sh*) containing for each line an
individual and independent call to python, with appropriate input arguments, spanning
all processes that need to be launched. Once this is ready, simply invoke

```bash
  pixi run runme
```

to use GNU parallel and launch all simulations (i.e. in an embarassingly parallel input parameters
exploration). Warning: this may take a long time, depending on the number of repetitions requested
for each stimulus and/or the duration of each stimulation (see below). Repeated short trials and
a single long trial of course may serve different purposes if one is interested in transients or in
steady-state responses.

When the simulations completes, you will find (pdf) figures and (ASCII) data files in the folder ./traces.
The data files are organised as "space-"separated values with two "columns" (i.e., time and voltage,
or time and current), for both the membrane potential (recorded
at the soma) and for the realisation of the noisy current waveform injected (respectively):

somaV_001.dat, somaV_002.dat, etc.
stimI_001.dat, stimI_002.dat, etc.

soma_001.pdf, soma_002.pdf, ... (the plots, generated for the convenience of a quick visualisation and
ease of reference to the stimulation parameters and to the cell name).

Please note that each file name is tagged with an integer number (e.g. "somaV_007.dat").
This number, called *index*, goes from 001, 002, 003, ... to N (N obtained as the
number of repetitions multiplied by the number of means multiplied by the number of standard deviations tested).
The "map", indicating the correspondence between a certain index and the actual mean and standard deviation
(and tau), is automatically generated (at the time of the *command.sh* generation) and it is saved as a
text file in the ./traces folder (i.e. as files_map.dat).

# Customising the stimuli

If you want to modify the duration of each O.U. stimulation (in ms) or its autocorrelation time length
(in ms), edit the file ```./pvt/generate_command.sh```: check for the variables **dur** and **tau**.

Finally note that, for each simulation, for the first T0 = 250 ms the model is run without any stimulus,
i.e. to let all state variables to "relax" to their "resting" values. In other words, for the first
250ms the injected current is zero and the total duration of the simulations is T0 + dur (ms).

In agreement with the code released by the BBP, the time step used for the simulations is "fixed"
(and not "variable") and set to 0.025 ms.

**Important:** each realisation of the stimulus current is generated with a different (initial) seed.
For simplicity, the seed is passed to the simulation script explicitly and conventionally set to
the "index" number. In such a way, it is guaranteed that each simulation is independent from the others.

# Simulating a different cell

Detailed, multicompartmental, 3d-reconstructed (rat somatosensory cortical) neuron models were
released by the BBP a few years ago. These are described, and available for download, from
https://bbp.epfl.ch/nmc-portal/welcome.html .

The file BBP_cells.txt, provided in the ./pvt folder, contains a list of filenames corresponding to
different cells in the BBP database. To use one cell at random, type:

```bash
shuf -n 1 ./pvt/BBP_cells.txt
```

and then replace the variable MODEL in the file ```install_models.sh```,
