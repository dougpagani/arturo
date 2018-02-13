#!/usr/bin/env bash
################################################################################
## {{{ Debugging Lines
# vim: foldmethod=marker
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
# }}}
################################################################################
ORIG_PWD="${PWD}"
ZIPDIRNAME=quantopian-zipline
cd DOWNLOADS
if ! [[ -d $ZIPDIRNAME ]]; then
    mkdir $ZIPDIRNAME
    git clone https://github.com/dougpagani/zipline $ZIPDIRNAME
fi
cd $ZIPDIRNAME
# Dockerfile aspects:
# - FROM python:3.5
# - ENV tini -- to change TINI_VERSION, and have it impact the build-cache
# - ADD <URL> /tini
# - make tini executable
# - There is an ENTRYPOINT before EOF: /tini --
# - /tini is the lightweight replacement for _bash_
# - another env
# - ENV can be used with a [[:space:]] delimiter, or =
# - RUN: make the project-directory, 
# ... run apt-get-updates & installs (for TA-lib)
# ... download the TA-source with curl, EXTRACT it
# ... 'tar' can be piped-to, apparently
# WORKDIR /ta-lib
# ... pwd=(TA-lib's)
# RUN: install zipline's pip-dependencies FIRST
# > numpy, scipy, pandas, matplotlib, jupyter
# ${NOTEBOOK_PORT} is used by 'EXPOSE', so ENV must stay after RUN statements
# Two persistent-ADDs:
#   1. /zipline (just add THIS, the entire build-context)
#   > so perhaps, if you change anything, including the Dev-dockerfile, the whole cache
#  ... will rebuild.
#   2. /docker_cmd.sh (the CMD)
#   ... uses openssl to prep
#   ... tracks "first time" by touch'ing /var/tmp/zipline_init
#   ... /tmp/ is effectively 'persistent' for docker-containers, since they never "boot-down"
#   ... the 'jupyter notebook' invoke is more complicated
docker build -t quantopian/zipline .
# could just do 'docker pull midas/zipline' if we had an account
# ... I'll just work-off my own account for now, though, until it's needed

cd "$ORIG_PWD"
echo ${PWD}
./docker_run.sh quantopian/zipline q_zippy

# An example of the CMD produced above:
#
# docker run \
#     -v ${PWD}:/projects \
#     -v ~/.zipline-quantopian:/root/.zipline
#     -p 8888:8888
#     --name zippy
#     -it quantopian/zipline
