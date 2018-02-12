#!/usr/bin/env bash
################################################################################
# STEPS:

#   1. Make sanity checks
#   2. Get the zipline-FORK (git clone)
#   3. Get some other dependencies if not already present in the repo (data, ext.py)
#   4. Move the dependencies into the right location
#   5. Dockerfile BUILD (--> Image)
#   6. DockerImage START (--> Container) [making sure the right stuff is mounted]
#   7. Zipline INGEST
#   8. If macOS, open the jupyter notebook
#   9. Run algo...

################################################################################
# TODO: "remember" this directory's location, per-site (ie per person's laptop)
# ....  - could use a dot-hidden file in the homedir, print pwd to it


# If this directory isn't a git-directory, it isn't being run from the right directory
[ -d .git ] || echo "ERROR: gotta GIT into the right directory; not in the top-level of the repo"; return

# IF script not-present, download it
[ -r ./install/extension.py ] ||
    curl "https://gist.githubusercontent.com/lukevs/a16f94b42ff693b8b79243f62e67f1ed/raw/6d8e02bb3c8a98c2edd70f82693441f645bceba8/extension.py" > ./install/extension.py

cp ./install/extension.py ~/.zipline/extension.py

# QUANDL data
if [ -r ./DOWNLOADS/csv_data.zip ]; then
    data_path=./DOWNLOADS/csv_data.zip
    GTG=1
else
    read -p "Do you already have the Quandl data downloaded, somewhere on your computer? [y/n]"
    case "$choice" in 
      y|Y ) 
            echo "OK, perfect, what is the path to the zip-data?"
            read -e -p "PATH-TO-ZIP: " data_path
            if [[ -r "$data_path" ]]; then
                echo "$data_path CHOSEN"
                GTG=1
            else 
                echo "ERROR: NO SUCH ZIP-FILE"
                return 1
            fi;;
      n|N ) 
            echo "Estimate by dividing the total size, 8GB, by the rate"
            echo "(e.g. 4MB/s for NEUs connection =~ 30m)."
            read -p "Continue?" choice2;;
      * ) 
          echo "ERROR: invalid response; run this again"
          return 1;;
    esac
fi

[[ -r "$data_path"  ]] || echo "data_dir not set correctly"; return 1

################################################################################
# Finish the script
################################################################################

mkdir -p ./DOWNLOADS/minute
mv ./DOWNLOADS/csv_data.zip ./DOWNLOADS/minute/csv_data.zip
unzip ./DOWNLOADS/minute/csv_data.zip -d ./DOWNLOADS/minute/ 

################################################################################
# DOCKER, zipline build
################################################################################

# Get the patched ZIPLINE fork (for minute data)
git clone https://github.com/lukevs/zipline ./DOWNLOADS/luke-zipline
#> Starbucks Wifi: 50, 5, 3
time -p docker build -t luke/zipline ./DOWNLOADS/luke-zipline
#> with cache: 716, 0.9, 0.8
# But did it work? ___ 
# TO REMOVE: 
if false; then
    docker stop $(docker ps -aq) && docker rm $(docker ps -aq); # Running containers, first
    docker rmi --force $(docker images --all -q); # Built images, last
fi
#> without cache:

# Named "zippy" to distinguish between the CONTAINER, from the image, repo, project
echo "RUNNING CONTAINER from the Just-Built Image"
#
docker run \
    -v $(pwd)/DOWNLOADS/minute:/csv_data\
\
    --name zippy \
    luke/zipline & 
# Example of clean invoke:
if false; then
    docker run -v $(pwd)/:/projects -v ~/.zipline:/root/.zipline --name rgv -it quantopian/zipline

# INGEST the data
echo "INGESTING the data for CSV-bundle"
docker exec zippy \
    zipline ingest -b csv-bundle

# Stop the container
docker stop -it zippy
# Re-start it with an instance of JUPYTER NOTEBOOKS
docker start -it zippy \
    -p 8888:8888/tcp
# OR, if that doesnt work 
# (bc you cant add a port-forwarding rule to an pre-existing container)
docker stop -it zippy \
    && docker rm zippy \
    && \
docker run \
    --name zippy \
    -it luke/zipline
\
    -v ~/.zipline:/root/.zipline \
    -v ./DOWNLOADS/minute:/csv_data
    -p 8888:8888/tcp
fi

# TODO: Jupyter will now be running, and might forcibly hang the script, as it does
# ... to an interactive terminal.

# Open the port automatically, for jupyter
open -a "Google Chrome" "http://localhost:8888/tree"




################################################################################
return 1
################################################################################
## STILL TO TEST, REFINE:
################################################################################

docker run \
    -v ~/cinco:/projects \
    -v ~/.zipline:/root/.zipline \
    -v ~/minute:/csv_data \
    -p 8888:8888/tcp \
    --name zipline \
    -it quantopian/zipline

docker exec -it zipline \
    zipline ingest -b csv-bundle

wget -O convert_csv.py 'https://gist.githubusercontent.com/m0006/8024963ec1402343b1fafb83c4a8b9df/raw/283c031576c6b0f811d145a4a652fc6cf472f3d6/convert_csv.py'
################################################################################
################################################################################
return 0
################################################################################

getghpubkey malachyburke 2>/dev/null | ssh-keygen -lf - -E md5 

198.211.108.237 -- arturo

: ${UN:=root}

cd DOWNLOADS
rsync -Paz -e 'ssh -p 22' $UN@198.211.108.237:/root/minute/csv_data.zip ./
# rsync -Paz -e 'ssh -p 22' root@198.211.108.237:/root/minute/csv_data.zip ./
cd -

ssh-keygen -t rsa -b 4096 -C 'MJB default key, new laptop' -f ~/.ssh/id_rsa

ssh-keygen -lf ${1-~/.ssh/id_rsa.pub} -E md5 | sed 's/.*MD5://' | sed 's/ .*//'

cat ~/.ssh/id_rsa.pub | pbcopy

DATASERVER_IP=198.211.108.237 # arturo
# Store things on a shared drive, then...
# /opt/share ...
bless_user() {
    # OPTS:
        # -k PUBKEYCAT
        # -f PUBKEYPLACE
        # -n GITHUB_NAME
        # -l LOGIN_NAME
        # ... : ${LOGIN_NAME:-$(\id -un)}
        # -r ... just auth for root
        # -s $DATASERVER_IP
        # TODO: grab the ip, automatically, in providing a domain-name
        # ... maybe parsed from ssh -G
################################################################################
# VAR-PREP:
################################################################################

    DATASERVER_IP=198.211.108.237 # arturo
    KEYDATA="$1"

    # if -f
    if [[ $IS_FILE = 1 ]]; then
        KEYDATA=$(cat "$KEYPLACE")
    fi

################################################################################
    # IF -r
    echo "$KEYDATA" | ssh root@${DATASERVER_IP} 'umask 0077; mkdir -p .ssh; cat >> $HOME/.ssh/authorized_keys && cat "$HOME/.ssh/authorized_keys"'

    # ELSE
    # useradd, first, then ssh in as root, or as a sudo'd user, and cat-keys

################################################################################
}
