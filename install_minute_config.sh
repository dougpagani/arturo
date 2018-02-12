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
# If this directory isn't a git-directory, it isn't being run from the right directory
[ -d .git ] || echo "ERROR: gotta GIT into the right directory; not in the top-level of the repo"; return

# IF script not-present, download it
[ -r ./install/extension.py ] ||
    curl "https://gist.githubusercontent.com/lukevs/a16f94b42ff693b8b79243f62e67f1ed/raw/6d8e02bb3c8a98c2edd70f82693441f645bceba8/extension.py" > install/extension.py
mv ./install/extension.py ~/.zipline/extension.py

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

[[ -r "$data_dir"  ]] || echo "data_dir not set correctly"; return 1

################################################################################
# Finish the script
################################################################################

mkdir -p ./DOWNLOADS/minute
mv ./DOWNLOADS/csv_data.zip ./DOWNLOADS/minute/csv_data.zip
unzip ./DOWNLOADS/minute/csv_data.zip

################################################################################
# DOCKER, zipline build
################################################################################

# Get the patched ZIPLINE fork (for minute data)
git clone https://github.com/lukevs/zipline ./DOWNLOADS/luke-zipline
#> Starbucks Wifi: 50, 5, 3
time -p docker build -t quantopian/zipline ./DOWNLOADS/luke-zipline
#> with cache: 716, 0.9, 0.8
# But did it work? ___ 
# TO REMOVE: 
if false; then
    docker stop $(docker ps -aq) && docker rm $(docker ps -aq); # Running containers, first
    docker rmi --force $(docker images --all -q); # Built images, last
fi
#> without cache:


## STILL TO TEST:

docker run -v ~/cinco:/projects -v ~/.zipline:/root/.zipline -v ~/minute:/csv_data -p 8888:8888/tcp --name zipline -it quantopian/zipline
docker exec -it zipline zipline ingest -b csv-bundle
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

# Store things on a shared drive, then...
# /opt/share ...
bless_user() {

}
