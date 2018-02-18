# install_conda_macos.sh
################################################################################

wget https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
echo 'export PATH="$HOME/miniconda/bin:$PATH"' >>~/.bashrc
echo 'export PATH="$HOME/miniconda/bin:$PATH"' >>~/.bash_profile
echo 'source activate zipper' >> ~/.bash_profile

conda update conda --yes

conda-env remove -n zipper --yes 2> /dev/null
conda create -n zipper -f env.yml
# env.yml generated with:
#   $ source activate zipper && conda env export > ./env.yml 

# Activate it & get rolling
source activate zipper
