#!/bin/bash
# usage: curl -sL bit.ly/mlgrm-traefiker-rstudio | [USER=user] [PASSWD=passwd] bash

DATA=${DATA:-/mnt/disks/data}

if [[ -z $PASSWD ]]; then PASSWD=$(apg -n 1) && >&2 echo "password: $PASSWD"; fi
USER=${USER:-$USER}

if [[ -n $(docker network list --filter name=postgres -q) ]]; then PG_NETWORK="--network postgres"; fi

curl -sL bit.ly/mlgrm-traefiker | 
    HOSTNAME=rstudio:shiny PORT=8787:3838 SERVICE=rstudio:shiny \
    bash -s -- run -d \
    -v $DATA/home:/home \
		-v $DATA/R:/usr/local/lib/R \
    -e USER=$USER \
    -e PASSWORD=$PASSWD \
    -e ROOT=TRUE \
    -e ADD=shiny \
    --name rstudio \
    --hostname rstudio \
    $PG_NETWORK \
    rocker/tidyverse
    
    
    
