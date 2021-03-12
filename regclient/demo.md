# Demo Scripts

## Prep

```shell
PS1='\n\$ '
export HUB_USER=sudobmitch
vi ~/.docker/hub_token
```

## regctl

```shell
# first create a network
docker network create registry

# start a local registry that allows deletes and image layers that point to MS repos
docker run -d --restart=unless-stopped --name registry --net registry \
  -e "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry" \
  -e "REGISTRY_STORAGE_DELETE_ENABLED=true" \
  -e "REGISTRY_VALIDATION_DISABLED=true" \
  -v "registry-data:/var/lib/registry" \
  -p "127.0.0.1:5000:5000" \
  registry:2

# all regctl commands will be run using a docker container on the registry network
regctl() {
  docker container run -it --rm --net registry \
    -v regctl-conf:/home/appuser/.regctl/ \
    regclient/regctl:latest "$@"
}

# repo ls fails since the registry isn't configured with TLS
regctl repo ls registry:5000

# tell regctl to not use TLS or https
regctl registry set registry:5000 --tls disabled --scheme http

# provide Docker Hub credentials
regctl registry login -u "$HUB_USER" -p "$(cat ~/.docker/hub_token)"

# repo ls now shows an empty list
regctl repo ls registry:5000

# copy from an external registry
regctl image copy regclient/regctl:latest registry:5000/regclient/regctl:latest -v info

# copy between repositories on same registry
regctl image copy registry:5000/regclient/regctl:latest registry:5000/example/regclient/regctl:latest -v info

# and retag an image in same repository
regctl image copy registry:5000/regclient/regctl:latest registry:5000/regclient/regctl:stable -v info

# we now see a few repos
regctl repo ls registry:5000

# list the tags
regctl tag ls registry:5000/regclient/regctl

# show the manifest
regctl image manifest registry:5000/regclient/regctl:latest

# manifest list shows that we didn't copy a single platform
regctl image manifest registry:5000/regclient/regctl:latest --list

# inspect the image without pulling it
regctl image inspect registry:5000/regclient/regctl:latest

# format string to extract the label
regctl image inspect registry:5000/regclient/regctl:latest --format '{{index .Config.Labels "org.opencontainers.image.version"}}'

# deleting a single tag
regctl tag delete registry:5000/regclient/regctl:stable

# verify the tag is gone
regctl tag ls registry:5000/regclient/regctl

# replace the tag
regctl image copy registry:5000/regclient/regctl:latest registry:5000/regclient/regctl:stable

# we can get the digest
# "tr" to work-around the tty: https://github.com/moby/moby/issues/8513
digest=$(regctl image digest --list registry:5000/regclient/regctl:latest | tr -d "\r")
echo $digest

# the image (manifest) digest is the same for all the images since they are copies
regctl image digest --list registry:5000/regclient/regctl:stable

# deleting an image requires the digest
regctl image delete registry:5000/regclient/regctl@$digest

# and when you delete an image, every tag pointing to that same image is gone
regctl tag ls registry:5000/regclient/regctl

# for Hub and any other registry that implements rate limits, we can check that limit
regctl image ratelimit regclient/regctl
```

## regsync

Create a file called `regsync.yml` ([example](example/regsync.yml)).

```shell
vi regsync.yml
```

Run it as a one-time command, useful for CI pipelines:

```shell
docker container run -it --rm --net registry \
  -v "$(pwd)/regsync.yml:/home/appuser/regsync.yml:ro" \
  -v "$HOME/.docker/hub_token:/var/run/secrets/hub_token:ro" \
  -e "HUB_USER" \
  regclient/regsync:latest -c /home/appuser/regsync.yml once

regctl repo ls registry:5000

regctl tag ls registry:5000/library/busybox

regctl tag ls registry:5000/library/alpine
```

Run it as a long running server, useful for a background service:

```shell
docker container run -d --restart=unless-stopped --name regsync --net registry \
  -v "$(pwd)/regsync.yml:/home/appuser/regsync.yml:ro" \
  -v "$HOME/.docker/hub_token:/var/run/secrets/hub_token:ro" \
  -e "HUB_USER" \
  regclient/regsync:latest -c /home/appuser/regsync.yml server

docker container ls
```

## Using a mirror

Define images that can easily change out the registry to another mirror:

```Dockerfile
ARG registry=docker.io
ARG tag=3
FROM ${registry}/library/alpine:${tag}
CMD echo "The time is now $(date)"
```

Build that image using the local mirror, test, and push to the same registry:

```shell
docker image build \
  --build-arg registry=localhost:5000 \
  -t localhost:5000/example/time .

docker container run --rm localhost:5000/example/time

docker image push localhost:5000/example/time

```

## regbot

Create a file called `regbot.yml` ([example](example/regbot.yml)).

```shell
vi regbot.yml
```

```shell
regctl image copy -v info \
    regclient/regctl:v0.0.1 registry:5000/example/app:latest \
&& \
regctl image copy -v info \
    registry:5000/example/app:latest registry:5000/example/app:ci-001 \
&& \
regctl image copy -v info \
    registry:5000/example/app:latest registry:5000/example/app:ci-002 \
&& \
regctl image copy -v info \
    registry:5000/example/app:latest registry:5000/example/app:ci-003 \
&& \
regctl image copy -v info \
    registry:5000/example/app:latest registry:5000/example/app:stable \
&& \
regctl image copy -v info \
    library/debian:latest registry:5000/library/debian:latest \
&& \
regctl tag ls registry:5000/example/app
```

First perform a dry run to see what would happen:

```shell
docker container run -it --rm --net registry \
  -e "HUB_USER" \
  -v "$HOME/.docker/hub_token:/var/run/secrets/hub_token:ro" \
  -v "$(pwd)/regbot.yml:/home/appuser/regbot.yml" \
  regclient/regbot:latest -c /home/appuser/regbot.yml once --dry-run
```

Next perform a one time execution to run all the steps now, useful for CI pipelines:

```shell
docker container run -it --rm --net registry \
  -e "HUB_USER" \
  -v "$HOME/.docker/hub_token:/var/run/secrets/hub_token:ro" \
  -v "$(pwd)/regbot.yml:/home/appuser/regbot.yml" \
  regclient/regbot:latest -c /home/appuser/regbot.yml once
```

Finally, leave the script running on a regular schedule in the background:

```shell
docker container run -d --restart=unless-stopped --name regbot --net registry \
  -e "HUB_USER" \
  -v "$HOME/.docker/hub_token:/var/run/secrets/hub_token:ro" \
  -v "$(pwd)/regbot.yml:/home/appuser/regbot.yml" \
  regclient/regbot:latest -c /home/appuser/regbot.yml server

docker container ls
```

```shell
regctl repo ls registry:5000

regctl tag ls registry:5000/library/alpine | sort && \
regctl tag ls registry:5000/library/debian | sort && \
regctl tag ls registry:5000/regclient/example | sort
```

## Cleanup

```shell
docker container stop regsync regbot registry
docker container rm   regsync regbot registry
docker volume    rm   regctl-conf registry-data
docker network   rm   registry
```
