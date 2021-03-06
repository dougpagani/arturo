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
set -e # exit on error
set -u # exit on "unset"
################################################################################
ZIPLINE_DATA_DIR="$HOME/.zipline-dougpagani" # named after the zipline-fork
#QUANDL_RAW_PATH=

CSV_DATA_LOCATION="./DOWNLOADS/csv_data/"
CSV_ZIP_LOCATION="$CSV_DATA_LOCATION/csv_data.zip"
CONVERTED_CSV_DIR="$CSV_DATA_LOCATION/minute"

# If this directory isn't a git-directory, it isn't being run from the right directory
[ -d .git ] || { echo "ERROR: gotta GIT into the right directory; not in the top-level of the repo"; exit 1; }

# IF script not-present, download it
[ -r ./install/extension.py ] ||
    curl "https://gist.githubusercontent.com/lukevs/a16f94b42ff693b8b79243f62e67f1ed/raw/6d8e02bb3c8a98c2edd70f82693441f645bceba8/extension.py" > ./install/extension.py

[ -r ./install/convert_csv.py ] ||
    wget -O ./install/convert_csv.py 'https://gist.githubusercontent.com/m0006/8024963ec1402343b1fafb83c4a8b9df/raw/283c031576c6b0f811d145a4a652fc6cf472f3d6/convert_csv.py'

################################################################################

# Check step 4, then 3, then 2...
# If the csv's are already converted, dont reconvert, just ingest
if [[ -d $CONVERTED_CSV_DIR ]]; then
    STEP3=1
fi

if ! [[ -d $ZIPLINE_DATA_DIR ]]; then
    mkdir $ZIPLINE_DATA_DIR
fi
ln -f ./install/extension.py ${ZIPLINE_DATA_DIR}/extension.py
# Execute the convert_csv.py when docker is available, lower in the script

if ! [[ $STEP3 = 1 ]]; then # skip all data munging processes

    # QUANDL data
    if [ -r $CSV_ZIP_LOCATION ]; then
        data_path=$CSV_ZIP_LOCATION
        GTG=1
    else
        read -p "Do you already have the Quandl data downloaded, somewhere on your computer? [y/n]" choice
        case "$choice" in 
          [yY]* ) 
                echo "OK, perfect, what is the path to the zip-data?"
                read -e -p "PATH-TO-ZIP: " data_path
                if [[ -r "$data_path" ]]; then
                    echo "$data_path CHOSEN"
                    GTG=1
                else 
                    echo "ERROR: NO SUCH ZIP-FILE"
                    exit 1
                fi;;
          [nN]* ) 
                echo "Estimate by dividing the total size, 8GB, by the rate"
                echo "(e.g. 4MB/s for NEUs connection =~ 30m)."
                read -p "Continue?" choice2;;
          * ) 
              echo "ERROR: invalid response; run this again"
              exit 1;;
        esac

        [[ -r "$data_path"  ]] || { echo "data_dir not set correctly"; exit 1; }

        mkdir -p ./DOWNLOADS/csv_data/
        mv "$data_path" ./DOWNLOADS/csv_data/csv_data.zip || :

    fi


    ################################################################################
    # Finish the script
    ################################################################################

    # SKIP
    echo "Unzipping files"
    unzip ./DOWNLOADS/minute/csv_data.zip -d ./DOWNLOADS/minute/ 
    # Will still prompt for CSV's

    # STEP 3
    # Prepare the data, to-be-ingested
    # ... if the local python doesnt work, fuck it, see if docker's does
    # TODO: add arg-functionality to convert_csv.py, to give it the path
    python ./install/convert_csv.py \
        || docker exec $DOCKER_CONTAINER_NAME \
        python ./install/convert_csv.py
        
fi # data-munging done (step 4 == zipline ingest)

################################################################################
# DOCKER, zipline build
################################################################################
ZIP_REPO=dougpagani/zipline
#ZIP_REPO=lukevs/zipline

ZIP_DIR_NAME=$(printf "$ZIP_REPO" | tr '/' '-')
ZIP_DIR_PLACE="./DOWNLOADS/$ZIP_DIR_NAME"

DOCKER_IMAGE_NAME=$ZIP_REPO         # x/zipline
DOCKER_CONTAINER_NAME=$ZIP_DIR_NAME # x-zipline

################################################################################
# Get the patched ZIPLINE fork (for minute data)
# TODO: if CLEAN_BUILD
if ! [[ -d $ZIP_DIR_PLACE ]]; then
    git clone https://github.com/${ZIP_REPO} $ZIP_DIR_PLACE
else
    echo "$ZIP_REPO already cloned" 
fi
#> Starbucks Wifi: 50, 5, 3

# Build the Dockerfile
# TODO: if CLEAN_BUILD, throw a flag in there of "not-from-cache"
if [[ -z $(docker images -q $DOCKER_IMAGE_NAME) ]]; then
    time docker build -t $ZIP_REPO $ZIP_DIR_PLACE
fi
# TODO: -p only works for macOS
#> with cache: 716, 0.9, 0.8
# But did it work? ___ 
#> without cache:

# TO REMOVE PREVIOUS docker-containers & images: 
# TODO: if $CLEAN_BUILD
if false; then
    docker stop $(docker ps -aq) && docker rm $(docker ps -aq); # Running containers, first
    docker rmi --force $(docker images --all -q); # Built images, last
fi

# Named "zippy" to distinguish between the CONTAINER, from the image, repo, project
echo "RUNNING CONTAINER from the Just-Built Image"


# Start the container, get the SSL-auth, background the container
# ... -v-mount for the /csv_data has to be containing the "minute" dir
CSV_REFINED_DIR=$HOME/arturo/DOWNLOADS/csv_data/

test -d ${CSV_REFINED_DIR}/minute || {
    echo "ERROR: The minute-data-directory is not bound to docker correctly" 
    exit 1
}

# Each mount point, of :<DOCKER> is fixed, 
# ... dependent on stuff already built-into the docker container.
docker run \
    -v ${CSV_REFINED_DIR}:/csv_data \
    -v ${ZIPLINE_DATA_DIR}:/root/.zipline \
    -v $HOME/projects:/projects \
    -p 8888:8888/tcp \
\
    --name $DOCKER_CONTAINER_NAME \
    $DOCKER_IMAGE_NAME & 


sleep 2
# Ingest the data
docker exec $DOCKER_CONTAINER_NAME \
    zipline ingest -b csv-bundle

# TODO: Jupyter will now be running, and might forcibly hang the script, as it does
# ... to an interactive terminal.

# Open the port automatically, for jupyter
if [[ "$OSTYPE" == "darwin"* ]]; then
    open -a "Google Chrome" "http://localhost:8888/tree"
fi





################################################################################
exit 0
# TODO: date-range of extension.py -- --full opt or not
# TODO: hard-link the files, dont copy (so you dont mistakenly edit one & not other)
# TODO: change location of csv-dump // unzip
# TODO: change location of zip file dump
# TODO: run convert_csv.py
# TODO: fix hard-pathing for python file (could do sys-arg)
# TODO: make the optional removal a flag in the python script
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

################################################################################
exit 9
################################################################################
################################################################################

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

