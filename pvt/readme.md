# Introduction

There are two scenarios possible:

User gets individual models, on a download-when-needed basis.
Each model is kept in the "models" folder and never deleted.
As the user selects a new model, the folder is checked and the
model is downloaded if not already there.

The user instead downloads upfront all models into the folder.

In both cases, choosing a model to be the "current one" is
implemented as a symbolic link pointing to the correct subfolders.


Individual models can be downloaded from:
https://bbp.epfl.ch/nmc-portal/assets/documents/static/downloads-zip/XXXXXX.zip

where XXXXXX.zip is archive containing the model (e.g. L5_TTPC1_cADpyr232_2.zip, L6_MC_cNAC187_4.zip, etc.)


The whole package, including all models, can be downloaded from:
https://bbp.epfl.ch/nmc-portal/assets/documents/static/Download/hoc_combos_syn.1_0_10.allzips.tar        (~800 MB unpacked)


# Obtaining and curating the model names database

- the model package combo (~800MB) was downloaded
- unpacked in a folder and the following bash-fu used:
-     find . -name "*.zip" -exec basename {} .zip \; > tmp.txt
- and the provided python script:
-     python fnames_curation.py tmp.txt
- this results in a    decorated_BBP_cells.txt

# Searching models

Fuzzy searching can be done simply as:

```bash
CHOICE=$(fzf --preview-window=hidden --no-multi --border --ansi --prompt='  ▶  ' --reverse --height=50% --info=hidden < ./decorated_BBP_cells.txt)

MODEL=$(echo $CHOICE | awk '{print $1}')
echo $MODEL
```

Linking (by a symbolic link) the desired folder can be now done by:

```bash
if [ -d ".model/$MODEL" ]; then
  echo "Folder exists, linking it symbolically..."
  ln -s .model/$MODEL ./model/currentmodel
else
  echo "Folder does not exist, downloading the model..."
  MODELURL=https://bbp.epfl.ch/nmc-portal/assets/documents/static/downloads-zip/$MODEL.zip
  curl -o .model/$MODEL.zip $MODELURL
  unzip $MODEL.zip
  rm -f $MODEL.zip
fi
ln -s /path/to/original/folder /path/to/symbolic/link
```
