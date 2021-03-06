#!/bin/bash
export HOSTNAME=transmission PORT=9091 
PIA_GW=${PIA_GW:-"Spain"}
[[ -z "$PASSWD" ]] && >&2 echo "PASSWD must be set" && exit 1
./traefiker.sh --cap-add=NET_ADMIN \
              -v /mnt/disks/data/tranmission:/data \
              -v /etc/localtime:/etc/localtime:ro \
              -e CREATE_TUN_DEVICE=true \
              -e OPENVPN_PROVIDER=PIA \
              -e OPENVPN_CONFIG="$PIA_GW" \
              -e OPENVPN_USERNAME="$PIA_USER" \
              -e OPENVPN_PASSWORD="$PIA_PASS" \
              -e WEBPROXY_ENABLED=false \
              -e LOCAL_NETWORK=$(docker network inspect traefik | jq -r '.[0].IPAM.Config[0].Subnet') \
              -e TRANSMISSION_RPC_AUTHENTICATION_REQUIRED=true \
              -e TRANSMISSION_RPC_USERNAME=${TRANSMISSION_RPC_USERNAME:-"transmission"} \
              -e TRANSMISSION_RPC_PASSWORD=$PASSWD \
              --name transmission \
              --hostname transmission \
              --dns 8.8.8.8 \
              --dns 8.8.4.4 \
              --log-driver json-file \
              --log-opt max-size=10m \
              haugene/transmission-openvpn
