# traefiker
a tool to roll out a docker host running traefik and easily add traefik-proxied containers

* `./start` starts a traefik image on the docker host.  if there is none, `./gcp-make-docker-host` spins one up on the google cloud platform
* `./traefiker [ options ] [ image ]` creates a container from image, attaches the traefik network, configures the labels traefik uses to do proxying, 
and starts the container

all configuration is currently by environment variables, most of which have reasonable defaults.  required variables are:

* `DOMAIN` the top level domain under which all traefik apps will be hosted. (all must point to the docker host's external ip).
* `HOST` the name of the gcp host.  the default region/zone must be specified ahead of time with `gcloud init` or `gcloud config set compute/zone`
* `EMAIL` let's encrypt requires an email.  this is also used as the default login by apps

once the docker host and traefik container are set up, container apps can be added and proxied by calling the traefiker script:

```bash
export HOSTNAME PORT PROTOCOL
traefiker [ options ] [ image ]
```
where `HOSTNAME` is the subdomain of `DOMAIN` on which the service should appear, `PORT` is the port on which the service runs 
(on the container) (80 by default), and `PROTOCOL` is the protocol expected by the container (http by default).  multiple services
can be run on the same container by chaining variable values together à la `$PATH`.  thus we can run rstudio, shiny and opencpu on
the same container by setting:
```bash
HOSTNAME=rstudio:shiny:opencpu
PORT=8787:3838:8004
```
