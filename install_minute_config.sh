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

# TODO: ~/.zipline directory for extension.py

# If this directory isn't a git-directory, it isn't being run from the right directory
[ -d .git ] || { echo "ERROR: gotta GIT into the right directory; not in the top-level of the repo"; exit 1; }

# IF script not-present, download it
[ -r ./install/extension.py ] ||
    curl "https://gist.githubusercontent.com/lukevs/a16f94b42ff693b8b79243f62e67f1ed/raw/6d8e02bb3c8a98c2edd70f82693441f645bceba8/extension.py" > ./install/extension.py

[ -r ./install/convert_csv.py ] ||
    wget -O ./install/convert_csv.py 'https://gist.githubusercontent.com/m0006/8024963ec1402343b1fafb83c4a8b9df/raw/283c031576c6b0f811d145a4a652fc6cf472f3d6/convert_csv.py'


ln ./install/extension.py ~/.zipline/extension.py
ln ./install/extension.py ~/.zipline/extension.py

# QUANDL data
if [ -r ./DOWNLOADS/minute/csv_data.zip ]; then
    data_path=./DOWNLOADS/minute/csv_data.zip
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
mkdir -p ./DOWNLOADS/minute
mv "$data_path" ./DOWNLOADS/minute/csv_data.zip

fi


################################################################################
# Finish the script
################################################################################

echo "Unzipping files"
unzip ./DOWNLOADS/minute/csv_data.zip -d ./DOWNLOADS/minute/ 
# Will still prompt for CSV's

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
git clone https://github.com/${ZIP_REPO} $ZIP_DIR_PLACE
#> Starbucks Wifi: 50, 5, 3

# Build the Dockerfile
time docker build -t luke/zipline $ZIP_DIR_PLACE
# TODO: -p only works for macOS
#> with cache: 716, 0.9, 0.8
# But did it work? ___ 
#> without cache:

# TO REMOVE PREVIOUS docker-containers & images: 
if false; then
    docker stop $(docker ps -aq) && docker rm $(docker ps -aq); # Running containers, first
    docker rmi --force $(docker images --all -q); # Built images, last
fi

# Named "zippy" to distinguish between the CONTAINER, from the image, repo, project
echo "RUNNING CONTAINER from the Just-Built Image"


# Start the container, get the SSL-auth, background the container
# TODO: change .zipline to a build-specific directory
docker run \
    -v $(pwd)/DOWNLOADS:/csv_data\
    -v $HOME/.zipline:/root/.zipline
    -v $HOME/projects:/projects
\
    --name $DOCKER_CONTAINER_NAME \
    $DOCKER_IMAGE_NAME & 

# Ingest the data
docker exec $DOCKER_CONTAINER_NAME \
    zipline ingest -b csv-bundle

################################################################################
exit 9
################################################################################


# TODO: Jupyter will now be running, and might forcibly hang the script, as it does
# ... to an interactive terminal.

# Open the port automatically, for jupyter
open -a "Google Chrome" "http://localhost:8888/tree"




################################################################################
exit 1
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
exit 0
################################################################################

# Execute the script to convert the CSVs
python ./install/convert_csv.py

# Now INGEST
docker exec -it zipline \
    zipline ingest -b csv-bundle

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
