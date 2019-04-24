# traefiker
a tool to roll out a docker host running traefik and easily add traefik-proxied containers

* `./start` starts a traefik image on the docker host.  if there is none, `./gcp-make-docker-host` spins one up on the google cloud platform
* `./traefiker [ options ] [ image ]` creates a container from image, attaches the traefik network, configures the labels traefik uses to do proxying, 
and starts the container

all configuration is currently by environment variables, most of which have reasonable defaults.  required variables are:

* `DOMAIN` the top level domain under which all traefik apps will be hosted. (all must point to the docker host's external ip).
* `HOST` the name of the gcp host.  the default region/zone must be specified ahead of time with `gcloud init` or `gcloud config set compute/zone`
* `EMAIL` let's encrypt requires an email.  this is also used as the default login by apps 
