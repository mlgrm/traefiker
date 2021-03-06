#!/bin/bash
# usage: curl -sL bit.ly/mlgrm-traefiker-rstudio | [USER=user] [PASSWD=passwd] bash

DATA=${DATA:-/mnt/disks/data}

if [[ -z $PASSWD ]]; then PASSWD=$(apg -n 1) && >&2 echo "password: $PASSWD"; fi
USER=${USER:-$USER}

if [[ -n $(docker network list --filter name=postgres -q) ]]; then PG_NETWORK="--network postgres"; fi

if docker container inspect rstudio 2>&1 > /dev/null; then
    >&2 echo "container exists, deleting"
    docker rm -f rstudio
fi
HOSTNAME=rstudio:shiny PORT=8787:3838 SERVICE=rstudio:shiny \
    ./traefiker.sh -d \
    -v $DATA/home:/home \
    -e USER=$USER \
    -e PASSWORD=$PASSWD \
    -e ROOT=TRUE \
    --name rstudio \
    --hostname rstudio \
    -e ADD=shiny \
    $PG_NETWORK \
    mlgrm/tidyverse
    
#		-v $DATA/R:/usr/local/lib/R \
    
    
