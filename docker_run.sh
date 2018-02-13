# MANAGING DIFFERENT DOCKER VERSIONS
################################################################################
_help_msg() {
  echo 'Usage: $BASH_SOURCE <SOME_ARG> [...]'
}
################################################################################
if [ $# -eq 0 ] || [ $# -gt 2 ]; then
    _help_msg
    exit 1
fi
################################################################################
# Fuzzy matching
#if [[ quantopian =~ $1 ]]; then
#    echo Running quantopian fork
#    IMAGE=quantopian/zipline
#elif [[ midas =~ $1 ]]; then
#    echo Running midas fork
#    IMAGE=midas/zipline
#else 
#    echo Argument unknown 
#    _help_msg
#    exit 1
#fi

# TODO
# IF THERE IS NO SUCH DOCKER-IMAGE ON THIS MACHINE
#    echo Argument unknown 
#    _help_msg
#    exit 1
#fi

# Exact match of the docker container
IMAGE="$1"

if [[ $# = 2 ]]; then
    CON_NAME="$2"
fi

echo Mounted \'${PWD}\' to the \'/projects\' dir of the container.


CMDLINE=(\
docker run \
    -v $(PWD):/projects \
    -v ~/.zipline-${CON_NAME}:/root/.zipline \
    -p 8888:8888 \
    --name ${CON_NAME:-$IMAGE} \
    -it ${IMAGE}
)
# -v projects -- Mount this directory as the algorithms to expose, run
# -p 8888 -- get access to jupyter in your browser on localhost:8888
# --name -- of the CONTAINER
# -it -- name of the IMAGE (must come last)

# Save the finalized command to the clipboard
echo "DOCKER-INVOKE:"
echo "${CMDLINE[@]}" | tee /dev/tty | pbcopy
echo "(copied to CLIPBOARD)"

# Execute it!
"${CMDLINE[@]}"
################################################################################
exit 0
################################################################################

# TODO: completion which gets IMAGE=$1
# TODO: add "-n" option to just get the formatting of the command, to then edit it

printvar CMDLINE
printvar () 
{ 
    local last_PIPESTATUS=("${PIPESTATUS[@]}");
    varname=${1?"USAGE: printvar VARNAME"};
    if [[ $1 == PIPESTATUS ]]; then
        varname=last_PIPESTATUS;
    fi;
    declare -p ${varname:?"Empty arg"} 2> /dev/null || { 
        error "No variable: \"$varname\"";
        return 1
    };
    echo -e ${RED}\$${varname}${NC} is: ${PURPLE}\"${!varname}\"${NC}
}
