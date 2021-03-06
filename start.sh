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

# add the http and https tags
gcloud compute instances add-tags --tags http-server,https-server "$HOST" &> /dev/null || >&2 echo "http/https tags already set"


# # get the docker remote function if we don't have it
# if [[ $(test -t docker_host) != "function" ]]; then
#     fun=$(curl -sL bit.ly/mlgrm-docker-remote)
#     echo "$fun" | tail -n +3 >> $HOME/.bashrc
#     eval "$fun"
# fi
docker-host () {
    if [[ -n $1 ]]; then
        export DOCKER_HOST="tcp://$(gcloud compute instances describe $1 \
            --format 'value(networkInterfaces[0].accessConfigs[0].natIP)'):2376" DOCKER_TLS_VERIFY=1
        if ! [[ -d $HOME/.docker && $(ls $HOME/.docker/{ca,cert,key}.pem | wc -l) -eq 3 ]]; then
            >&2 echo "need to get the pem files and put them in ~/.docker.  (maybe saved in drive as $1-tls.tgz?)"
        fi
    else
        unset DOCKER_HOST DOCKER_TLS_VERIFY
    fi
}

docker-host $HOST

IP=$(sed -E 's/tcp:\/\/([0-9.]+).*/\1/' <<< $DOCKER_HOST)

# copy files to host

# wait for ssh to come up
>&2 echo "waiting for ssh..."
until netcat -z $IP 22; do sleep 1; done

# wait for data disk to be mounted
>&2 echo "waiting for data disk..."
until gcloud compute ssh cosima --command mount | grep -q '^/dev/sd[b-z] on /mnt/disks/data'; do
    sleep 5
done

gcloud compute ssh $HOST --command "sudo mkdir -p $DATA/traefik" -- -n

export DOMAIN ACME_EMAIL

# if it doesn't already exist, get our traefik.toml template and substitute our DOMAIN and ACME_EMAIL
[[ -s "traefik.toml" ]] || curl -sL http://bit.ly/2YbJXCK > traefik.toml
envsubst < traefik.toml | \
					 gcloud compute ssh $HOST --command "sudo tee $DATA/traefik/traefik.toml > /dev/null"

# initialize the let's encrypt secrets file if they don't exist
gcloud compute ssh $HOST --command "[[ -f $DATA/traefik/acme.json ]] ||
    sudo touch $DATA/traefik/acme.json && sudo chmod 600 $DATA/traefik/acme.json" -- -n

# wait for docker to be available
>&2 echo "waiting for docker..."
until netcat -z $IP 2376; do sleep 10; done

if [[ -z $(docker network list --filter name=traefik -q) ]]; then docker network create traefik; fi

if docker container inspect traefik > /dev/null 2>&1 ; then
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
 
