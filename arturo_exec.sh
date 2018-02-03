#!/usr/bin/env bash
# arturo_exec.sh
# USAGE:
# > artex 'docker exec zipline algo.py'
################################################################################
# trap read debug
#set -x

HOST="root@do_mango"
SESSION_NAME="SCRIPT_SESSION"

# Switches:
is_py=0
is_bash=0
is_cmdline=1
to_attach_after=1
to_transfer_local_script=0


# Default:
if [[  $is_py = 1 ]]; then
    CMD_WRAPPED="
    python $@
    "
elif  [[  $is_bash = 1  ]]; then
    CMD_WRAPPED="
    bash $@
    "
elif [[  $is_cmdline = 1 ]]; then
    CMD_WRAPPED="$@"

fi
#####################
# Handle if the script needs to be copied local->remote
if [[ $to_transfer_local_script = 1 ]]; then
    scp $HOST
fi

#####################
TMUX_INIT="\
    echo \$-
    [ -t 1 ] && echo Is INTERACTIVE || echo NOT interactive
    tmux new-session -d -s $SESSION_NAME;
    tmux send-keys -t $SESSION_NAME \"$CMD_WRAPPED\" Enter
    tmux split-window -d 'vim ~/dotfiles/tmux_bindings.txt' 
"
echo "$TMUX_INIT" | pbcopy
# TODO: a help-page hosted in a pane of the session you ssh into
# TODO: delete old sessions, or give error if-exists
# ---> giving an informative error makes it so it is easy to coordinate/single-exec
ssh $HOST "$TMUX_INIT" 
# without -t, tmux wont fire-cmds since it isn't interactive


#####################
# Attach to script
# Force allocation since this is a non-i script
ATTACH_CMD="ssh -t $HOST \"tmux attach -t $SESSION_NAME\""
# ssh -t $HOST "tmux attach -t $SESSION_NAME"

if [[  $to_attach_after  = 1 ]]; then
    eval $ATTACH_CMD    # ^ detach to close-out
fi

# Write general alias to bash_profile if doesn't exist
if grep -q arturo_attach ~/.bash_profile; then
    echo "Alias aready present; use 'arturo_attach' to attach to the server running your cmd."
else
    echo "Creating alias: 'arturo_attach'"
    xALIAS='alias arturo_attach="source ~/.arturo_attach"'
    echo "$xALIAS" >> ~/.bash_profile
fi


# Write specific ATTACH cmd
rm ~/.arturo_attach
echo "$ATTACH_CMD" > ~/.arturo_attach



################################################################################
# CONSIDERATIONS:
# - the host must have its environment configured for this

# TODO:
#   - authenticate based on rsa-keys pulled from github
#       - auth as root
#   - do so automatically?
#   - have an install script which installs artex, artatt, and the ssh-server-address
#       - keep in mind that fish is used as well.
#   - have arturo communicate with servers?
#   -   get ssh-attach to pass-through servers
#   - cheat-page for tmux stuff
#   ---> cat: tmux_shortcuts


