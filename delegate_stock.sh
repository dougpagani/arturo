#!/usr/bin/env bash
# - CONTEXT: run by ARTURO
# - usage: delegate_stock.sh <DATA-PATH> <ALGO-PATH>
################################################################################
#{{{ TASKLIST:
# - provision server -- spinup_server.sh
# - send stock.csv
# - send algo.py
#}}}
################################################################################
DATA_FILE="$1"
ALGO_FILE="$2"
PRIV_IP=""
SEND_LOCATION=""
PROJECT_DIR="$HOME/project" # declared in docker_run-invocation
DATA_DIR="$HOME/data" # declared in docker_run-invocation
DROP_OFF_POINT= # the point on ARTURO where axlets have access to
#^ could just authenticate the axlets for root@arturo

#^ data to be ingested



################################################################################
#{{{ 1. Provision server
# ... spinup, build docker, run container
# ... GAP (2 & 3 == sending contingent materials)
# ... kick-off execution
################################################################################
# $DATA_DIR -- used to mkdir in provision_server.sh

# TODO: either call "spinup_axlet.sh" or do it with ssh-streamed cmds

# RETURN: private server-ip
SEND_LOCATION=

#}}}


################################################################################
#{{{ 2. send stock.csv
################################################################################
SEND_LOCATION_DATA="${PRIV_IP}:${DATA_DIR}"

scp "$DATA_FILE"  "$SEND_LOCATION_DATA"

#}}}

################################################################################
#{{{ 3. send algo.py
################################################################################
SEND_LOCATION_DATA="${PRIV_IP}:${PROJECT_DIR}" # e.g. root@a32:~/project

scp "$ALGO_FILE"  "$SEND_LOCATION_ALGO"

#}}}

################################################################################
#{{{ 4. Kick-off execution on AXLET
################################################################################

# SEND CMDs:
# docker ingest <DATA>
# docker exec <ALGO>
# ... time, pickle is output in /project


################################################################################
#{{{ 5. Retrieve pickle
################################################################################

# Setup a file-watch for the pickle, bind it to a reverse scp-cmd
# send fswatch to background via ssh-execcution
# fswatch ~/projects/*.pickle | xargs -I{} scp {} <ARTURO-IP>:~/<run-of-folder>/
    # TODO: what are REGEX's for fswatch ... any file named pickle
    # the destination of pickle-delivery must be organized as a folder, 
    # ... perhaps an arg given to this script, as per larger runs

# DRO

################################################################################
