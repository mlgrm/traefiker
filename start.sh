#!/bin/bash
# usage curl -sL bit.ly/mlgrm-traefik-setup | DOMAIN=traefik.example.com HOST=gcp_hostname EMAIL=mail@example.com bash

set -e

ACME_EMAIL=${ACME_EMAIL:-$EMAIL}
DATA=${DATA:-/mnt/disks/data}
[[ -z $DOMAIN || -z $HOST || -z $ACME_EMAIL ]] && echo 'all of DOMAIN, HOST, and ACME_EMAIL must be defined' && exit 1 

#set -e

# if the docker host doesn't exist, create it.
res=$(gcloud compute instances list --filter "name~^$HOST$" 2> /dev/null)
if grep "TERMINATED$" <<< $res; then gcloud compute instances start $HOST; fi
if [[ -z $res ]]; then  
    HOST=$HOST IP_NAME=$IP_NAME BOOT_DISK_SIZE=$BOOT_DISK_SIZE ./gcp-make-docker-host
fi

# get the docker remote function if we don't have it
if [[ $(test -t docker_host) != "function" ]]; then
    fun=$(curl -sL bit.ly/mlgrm-docker-remote)
    echo "$fun" | tail -n +3 >> $HOME/.bashrc
    eval "$fun"
fi

docker_host $HOST
IP=$(sed -E 's/tcp:\/\/([0-9.]+).*/\1/' <<< $DOCKER_HOST)

# copy files to host

# wait for ssh to come up
>&2 echo "waiting for ssh..."
until netcat -z $IP 22; do sleep 1; done
gcloud compute ssh $HOST --command "sudo mkdir -p $DATA/traefik" -- -n

export DOMAIN ACME_EMAIL

# get our traefik.toml template and substitute our DOMAIN and ACME_EMAIL
curl -sL http://bit.ly/2YbJXCK |
    envsubst |
    gcloud compute ssh $HOST --command "sudo tee $DATA/traefik/traefik.toml > /dev/null"

# initialize the let's encrypt secrets file if they don't exist
gcloud compute ssh $HOST --command "[[ -f $DATA/traefik/acme.json ]] || 
    sudo touch $DATA/traefik/acme.json && sudo chmod 600 $DATA/traefik/acme.json" -- -n

# wait for docker to be available
>&2 echo "waiting for docker..."
until netcat -z $IP 2376; do sleep 5; done

if [[ -z $(docker network list --filter name=traefik -q) ]]; then docker network create traefik; fi

if docker container inspect traefik 2>&1 > /dev/null; then
    >&2 echo "container exists, deleting"
    docker rm -f traefik
fi
docker run -d \
    --restart always \
    -p 80:80 -p 443:443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $DATA/traefik/traefik.toml:/traefik.toml \
    -v $DATA/traefik/acme.json:/acme.json \
    --name traefik \
    --network traefik \
    traefik
 
