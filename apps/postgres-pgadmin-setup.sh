#!/bin/bash
# usage: curl -sL bit.ly/mlgrm-postgres | EMAIL=mail@example.com [PASSWORD=xxxxxxx] bash

set -e

[[ -z $PASSWD ]] && PASSWD=$(apg -n 1) && >&2 echo "password: $PASSWD"
[[ -z $EMAIL ]] && >&2 echo "need to set EMAIL" && exit 
[[ -z $DOCKER_HOST ]] || ! docker ps 2>&1 > /dev/null && >&2 echo "need DOCKER_HOST defined and running docker"

#if [[ -z $(docker ps --filter name=traefik -q) ]]; then curl -sL bit.ly/mlgrm-traefik-setup | bash; fi
if ! gcloud compute instances describe "$HOST" --format json| jq -r '.tags.items[]' | grep -q '^postgres$'; then
    gcloud compute instances add-tags "$HOST" --tags postgres
fi


if [[ -z $(docker network list --filter name=postgres -q) ]]; then docker network create postgres; fi
    
curl -sL bit.ly/mlgrm-traefiker |
    HOSTNAME=pgadmin \
    bash -s -- run -d \
    --name pgadmin \
    -v /mnt/disks/data/pgadmin:/var/lib/pgadmin \
    -e PGADMIN_DEFAULT_EMAIL=$EMAIL \
    -e PGADMIN_DEFAULT_PASSWORD=$PASSWD \
    --network postgres \
    dpage/pgadmin4

docker run -d \
    -v /mnt/disks/data/postgresql:/var/lib/postgresql \
    --name postgres \
    -h postgres \
    -e POSTGRES_PASSWORD=$PASSWD \
    --network postgres \
    -p 5432:5432 \
    postgres
