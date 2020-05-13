# Demo Commands

## 0 - Prep

- cleanup from previous tests:

```
docker-compose -f docker-compose.demo8.yml down -v
docker container stop hub-cache builder
docker container rm hub-cache builder
docker network rm cache
docker volume rm hub-cache dind
```

- remove existing private repo tags from docker hub, source env

## 1 - Configure Engine to Use a Mirror

```
docker network create cache
docker container run --env-file .env \
  -d --net cache --restart unless-stopped --name hub-cache \
  registry:2
docker container run --env-file .env \
  -d --net cache --restart unless-stopped --name builder --privileged \
  -v dind:/var/lib/docker \
    docker:dind --registry-mirror http://hub-cache:5000
# split screen, show logs in separate terminal
docker container logs -f hub-cache
# attempt pull in original window
docker container exec -it builder docker pull busybox
# that fell back to pulling directly from hub
```

## 2 - Configure Registry As Mirror

```
# stop previous instance
docker container stop hub-cache
docker container rm hub-cache
# recreate with pull through cache options
docker container run --env-file .env \
  -d --net cache --restart unless-stopped --name hub-cache \
  -v "hub-cache:/var/lib/registry" \
  -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry \
  -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
  registry:2
# split screen, show logs in separate terminal
docker container logs -f hub-cache
# in original termainal, run the pull
docker container exec -it builder docker pull busybox
```

## 3 - Comparing Pull Time

```
# pull a new image
time docker container exec -it builder docker pull ubuntu
# recreate the builder, empty /var/lib/docker
docker container stop builder
docker container rm builder
docker volume rm dind
docker container run --env-file .env \
  -d --net cache --restart unless-stopped --name builder --privileged \
  -v dind:/var/lib/docker \
  docker:dind --registry-mirror http://hub-cache:5000
# time a fresh pull, now from the cache
time docker container exec -it builder docker pull ubuntu
```

## 4 - Login and Push to Private Repo

```
docker exec -it builder sh
# login with token from .env file
echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin
docker image tag ubuntu sudobmitch/demo:ubuntu
# split screen, show logs in separate terminal
docker container logs -f hub-cache
# run push and pull in original window
docker image push sudobmitch/demo:ubuntu
docker image pull sudobmitch/demo:ubuntu
exit
# recreate hub-cache image with credentials
docker container stop hub-cache
docker container rm hub-cache
# creds in .env file
. ./.env
docker container run --env-file .env \
  -d --net cache --restart unless-stopped --name hub-cache \
  -v "hub-cache:/var/lib/registry" \
  -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry \
  -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
  -e REGISTRY_PROXY_USERNAME="$DOCKER_USER" \
  -e REGISTRY_PROXY_PASSWORD="$DOCKER_TOKEN" \
  registry:2
# split screen, show logs in separate terminal
docker container logs -f hub-cache
# run push and pull in original window
docker container exec -it builder docker image pull sudobmitch/demo:ubuntu
# run a fresh builder
docker container stop builder
docker container rm builder
docker volume rm dind
docker container run --env-file .env \
  -d --net cache --restart unless-stopped --name builder --privileged \
  -v dind:/var/lib/docker \
  docker:dind --registry-mirror http://hub-cache:5000
docker container exec -it builder docker image pull sudobmitch/demo:ubuntu
```

## 5 - TLS and Pulling Directly from the Cache

```
docker container exec -it builder sh
docker image pull hub-cache:5000/debian
# that failed, we need to configure TLS
exit
# generate certs
./make-certs.demo5.sh
# stop everything to redeploy with certs
docker container stop builder hub-cache
docker container rm builder hub-cache
# redeploy with certs, mounting them in /host
docker container run --env-file .env \
  -d --net cache --restart unless-stopped --name hub-cache \
  -v "$(pwd):/host:ro" \
  -v "hub-cache:/var/lib/registry" \
  -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry \
  -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
  -e REGISTRY_PROXY_USERNAME="$DOCKER_USER" \
  -e REGISTRY_PROXY_PASSWORD="$DOCKER_TOKEN" \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/host/reg.pem \
  -e REGISTRY_HTTP_TLS_KEY=/host/reg-key.pem \
  registry:2
# add the ca cert to /etc/docker/certs.d/hub-cache:5000 in builder
# also note the https on the --registry-mirror arg
docker container run --env-file .env \
  -d --net cache --restart unless-stopped --name builder --privileged \
  -v "$(pwd)/ca.pem:/etc/docker/certs.d/hub-cache:5000/ca.crt:ro" \
  -v dind:/var/lib/docker \
  docker:dind --registry-mirror https://hub-cache:5000
# that didn't work, we can't use a colon in the volume mount short syntax
docker container run --env-file .env \
  -d --net cache --restart unless-stopped --name builder --privileged \
  --mount "type=bind,src=$(pwd)/ca.pem,dst=/etc/docker/certs.d/hub-cache:5000/ca.crt,readonly" \
  -v dind:/var/lib/docker \
  docker:dind --registry-mirror https://hub-cache:5000
# now try to run a pull
docker container exec -it builder sh
time docker image pull sudobmitch/demo:ubuntu
# that worked, so nothing broken, lets try that pull again
docker image pull hub-cache:5000/ubuntu
# that didn't work, hmm...
docker image pull hub-cache:5000/sudobmitch/demo:ubuntu
# private image works, why didn't the other image work?
docker image pull hub-cache:5000/library/ubuntu
# ah ha, library is the repository for official images
exit
```

## 6 - Configure Compose

```
# remove non-compose instances
docker container stop builder hub-cache
docker container rm builder hub-cache
# deploy with docker-compose
more docker-compose.demo6.yml
docker-compose -f docker-compose.demo6.yml up -d
docker-compose -f docker-compose.demo6.yml scale builder=3
# test a pull in 2 windows showing concurrency
docker-compose -f docker-compose.demo6.yml exec --index=1 builder docker image pull sudobmitch/demo:ubuntu
docker-compose -f docker-compose.demo6.yml exec --index=2 builder docker image pull sudobmitch/demo:ubuntu
# then show pristine 3rd instance and fast pull
docker-compose -f docker-compose.demo6.yml exec --index=3 builder sh
docker image ls
docker image pull sudobmitch/demo:ubuntu
exit
```

## 7 - Setup Cache for Gitlab

```
# update the certs for gitlab-cache hostname
more make-certs.demo7.sh
./make-certs.demo7.sh
# deploy the project
more docker-compose.demo7.yml
docker-compose -f docker-compose.demo7.yml up -d
docker-compose -f docker-compose.demo7.yml exec builder sh
# login to gitlab, pull a sample image, and push to gitlab
echo "$GITLAB_TOKEN" | docker login -u "$GITLAB_USER" --password-stdin registry.gitlab.com
docker image pull debian
docker image tag debian registry.gitlab.com/sudo-bmitch/demo:debian
docker image push registry.gitlab.com/sudo-bmitch/demo:debian
# now we can pull through the cache
docker image pull gitlab-cache:5000/sudo-bmitch/demo:debian
```

## 8 - Gitlab with DNS and TLS Injection

```
# update certs for registry.gitlab.com
more make-certs.demo8.sh
./make-certs.demo8.sh
# show change to DNS/TLS certs
more docker-compose.demo8.yml
docker-compose -f docker-compose.demo8.yml up -d
docker-compose -f docker-compose.demo8.yml exec builder sh
# we can pull through the intercepted name
docker image pull registry.gitlab.com/sudo-bmitch/demo:debian
# however we can't push
docker image push registry.gitlab.com/sudo-bmitch/demo:debian
exit
# verify it still works when cache is down
docker-compose -f docker-compose.demo8.yml stop gitlab-cache
docker-compose -f docker-compose.demo8.yml exec builder sh
docker image pull registry.gitlab.com/sudo-bmitch/demo:debian
echo "$GITLAB_TOKEN" | docker login -u "$GITLAB_USER" --password-stdin registry.gitlab.com
docker image push registry.gitlab.com/sudo-bmitch/demo:debian
exit
```


