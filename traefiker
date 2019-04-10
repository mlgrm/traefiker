#!/bin/bash
# run a docker image behind the traefik container created by http://bit.ly/2FpLCNB
#
# usage: 
# curl -sL bit.ly/mlgrm-traefiker | \
#       HOSTNAME=host DOMAIN=example.com [SERVICE=svc] [PORT=port] [PROTOCOL=prtcl] bash -s -- <cmd> <args> <image>
# or
# curl -sl bit.ly/mlgrm-traefiker > traefiker && chmod +x traefiker
# HOSTNAME=host [...] ./traefiker <args> <image>
# 
# you must use the --name parameter.

IFS=":" read -r -a svcs <<< ${SERVICE:-basic}
IFS=":" read -r -a ports <<< ${PORT:-80}
IFS=":" read -r -a hosts <<< $HOSTNAME
IFS=":" read -r -a protocols <<< ${PROTOCOL:-http}

# if traefik isn't running, start it
if ! docker container inspect traefik > /dev/null 2>&1; then curl -sL bit.ly/mlgrm-traefik-setup | bash; fi

[[ $1 != "run" ]] && >&2 echo "command $1 doesn't make sense for traefiker" && exit 1

[[ ${#ports[@]} -ne ${#svcs[@]} ||
    ${#hosts[@]} -ne ${#svcs[@]} ]] && 
    >&2 echo "PORT, HOSTNAME, and SERVICE must all be the same length" &&
    exit 1
    
[[ ${#protocols[@]} -eq 1 && ${#svcs[@]} -gt 1 ]] && 
    for i in ${svcs[@]:1}; do protocols+=($protocols); done
    
labels=("-l traefik.docker.network=traefik" "-l traefik.enable=true")
for i in ${!svcs[@]}; do
    labels+=("-l traefik.${svcs[$i]}.frontend.rule=Host:${hosts[$i]}.$DOMAIN")
    labels+=("-l traefik.${svcs[$i]}.port=${ports[$i]}")
    labels+=("-l traefik.${svcs[$i]}.protocol=${protocols[$i]}")
done

# get rid of run [ -d ]
[[ $1 == "run" ]] && shift
[[ $1 == "-d" ]] && shift

cmd="docker create --rm ${labels[@]} $@"
>&2 echo "docker command: $cmd"
# attach to the traefik network
id=$(eval $cmd)
docker network connect traefik "$id"
docker start $id
