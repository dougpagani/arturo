#!/usr/bin/env bash
# FILE: install_this_repo.sh
# DESCRIPTION:
#   Make it even easier for others to install this script
# ---> GIVE this file to someone, that they can just run.
################################################################################
## --------- Debugging Lines
set -u # exit upon unset vars
set -e # exit upon first-error
set -o pipefail # exit
# trap read debug

## For simulating function-runs
## > set argone argtwo argthree
# PROMPT_COMMAND='echo "\ Args are: $@ #: $#"'

## ALTERNATIVE TO BASH-DB
# exec 5> >(logger -t $0)
# BASH_XTRACEFD="5"
PS4='$LINENO: '
# set -x # print each line of code 
# trap read debug
# error() {
#   local sourcefile=$1
#   local lineno=$2
#   # ...logic for reporting an error at line $lineno
#   #    of file $sourcefile goes here...
#}
#trap 'error "${BASH_SOURCE}" "${LINENO}"' ERR
# https://stackoverflow.com/questions/10743026/how-to-display-last-command-that-failed-when-using-bash-set-e
################################################################################
echo "Script starting..."
echo "-------------------> Args are: $@ \$#: $#"
echo bash version: $BASH_VERSION
################################################################################

####################
# STEPS:
# 1. TODO: check if authenticated for DATASERVER (arturo)
# 2. clone the repo
# 3. run the install script
####################
INSTALL_SCRIPT=install_minute_config.sh

git clone https://github.com/dougpagani/arturo 

cd arturo
chmod +x "$INSTALL_SCRIPT"

# Execute the script
"$INSTALL_SCRIPT"

