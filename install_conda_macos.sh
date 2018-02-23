# install_conda_macos.sh
################################################################################

CONDA_DEST="$HOME/miniconda"
#CONDA_DEST="/usr/local/miniconda"
wget https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p "$CONDA_DEST"

CONDA_BIN="$CONDA_DEST/bin"
export PATH="${CONDA_BIN}:$PATH"
echo "export PATH=${CONDA_BIN}:"'$PATH' >>~/.bashrc
echo "export PATH=${CONDA_BIN}:"'$PATH' >>~/.bash_profile

#echo 'source activate zipper' >> ~/.bash_profile
echo "
alias zipper='source activate zipper'
    alias zipup='source activate zipper'
    alias zipp='source activate zipper'
" >> ~/.bash_profile

conda update conda --yes

# TODO: get rid of this if you dont want to neessarily create the zipline-dir
conda env remove -n zipper --yes 2> /dev/null
conda env create -n zipper -f ./env.yml || 
    echo "make sure you're in the arturo directory"
# env.yml generated with:
#   $ source activate zipper && conda env export > ./env.yml 

# Activate it & get rolling -- only works if being sourced
#source activate zipper
