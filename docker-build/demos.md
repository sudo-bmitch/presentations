# Commands used in Demos

- External Build
  ```
  export DOCKER_BUILDKIT=0 
  cat Dockerfile.external
  rm app
  go build -o app .
  ls -al app
  docker build -f Dockerfile.external -t golang-hello:external .
  docker container run --rm --name golang-demo -p 8080:8080 -d golang-hello:external
  curl localhost:8080/Gophers
  docker rm -f golang-demo
  ```

- Build by Hand
  ```
  rm app main.bin
  docker container run -it --name golang-demo \
    -v "$(pwd):/context" -w "/src" \
    golang:1.12 /bin/bash
  cp -rv /context/. /src/.
  go build -o app .
  ./app &
  curl localhost:8080/Hello
  exit
  docker container diff golang-demo | less
  docker rm -f golang-demo
  ```

- Dockerfile: debian v1
  ```
  export DOCKER_BUILDKIT=0 
  docker build -f Dockerfile.debian1 -t golang-hello:debian1 .
  docker container run --rm --name golang-demo -p 8080:8080 -d golang-hello:debian1
  curl localhost:8080/Gophers
  docker rm -f golang-demo
  ```

- Dockerfile: debian v2
  ```
  export DOCKER_BUILDKIT=0 
  docker build -f Dockerfile.debian2 -t golang-hello:debian2 .
  docker container run --rm --name golang-demo -p 8080:8080 -d golang-hello:debian2
  curl localhost:8080/Gophers
  docker image ls golang
  docker image ls golang-hello
  docker rm -f golang-demo
  ```

- Dockerfile: alpine1
  ```
  export DOCKER_BUILDKIT=0 
  docker build -f Dockerfile.alpine1 -t golang-hello:alpine1 .
  # failed, missing git
  ```

- Dockerfile: alpine2
  ```
  docker build -f Dockerfile.alpine2 -t golang-hello:alpine2 .
  docker container run --rm --name golang-demo -p 8080:8080 -d golang-hello:alpine2
  curl localhost:8080/Gophers
  docker image ls golang
  docker image ls golang-hello
  docker rm -f golang-demo
  ```

- Dockerfile: multi-stage v1
  ```
  export DOCKER_BUILDKIT=0 
  cat Dockerfile.multi-stage1
  docker build -f Dockerfile.multi-stage1 -t golang-hello:multi-stage1 .
  docker container run --rm --name golang-demo -p 8080:8080 golang-hello:multi-stage1
  # failed, missing user
  ```

- Dockerfile: multi-stage v2
  ```
  diff -y Dockerfile.multi-stage1 Dockerfile.multi-stage2
  docker build -f Dockerfile.multi-stage2 -t golang-hello:multi-stage2 .
  docker container run --rm --name golang-demo -p 8080:8080 -d golang-hello:multi-stage2
  curl localhost:8080/Gophers
  # what happened, let's check the logs
  docker logs golang-demo
  # no container, crashed?
  docker container run --rm --name golang-demo -p 8080:8080 golang-hello:multi-stage2
  # no such file or dir, why?
  docker container run --rm --name golang-demo -p 8080:8080 golang-hello:multi-stage2 /bin/sh
  # no /bin/sh in scratch, we need a dev image
  ```

- Dockerfile: multi-stage v3
  ```
  diff -y Dockerfile.multi-stage2 Dockerfile.multi-stage3
  docker build -f Dockerfile.multi-stage3 --target debug -t golang-hello:multi-stage3-debug .
  docker container run --rm --name golang-demo -p 8080:8080 golang-hello:multi-stage3-debug /bin/bash
  # immediately returned? Oh, a shell needs input
  docker container run --rm -it --name golang-demo -p 8080:8080 golang-hello:multi-stage3-debug /bin/bash
    ./app # there's the no such file or directory
    ls -l app # but the file exists
    ldd ./app # oops, we have linked libraries
    exit
  # we need to turn off CGO to remove linked libraries
  ```

- Dockerfile: multi-stage v4
  ```
  diff -y Dockerfile.multi-stage3 Dockerfile.multi-stage4
  docker build -f Dockerfile.multi-stage4 -t golang-hello:multi-stage4 .
  docker container run --rm --name golang-demo -p 8080:8080 -d golang-hello:multi-stage4
  curl localhost:8080/Gophers
  docker image ls golang-hello
  docker rm -f golang-demo
  ```

- Developer local workflow with multi-stage
  ```
  docker build -f Dockerfile.multi-stage4 --target dev -t golang-hello:multi-stage4-dev .
  docker container run --rm --name golang-demo -p 8080:8080 \
    -v "$(pwd):/src" -v "${HOME}:${HOME}" -e "GOPATH=${HOME}/data/golang" -e HOME \
    -u "$(id -u):$(id -g)" -d golang-hello:multi-stage4-dev
  docker logs -f golang-demo
  curl localhost:8080/Gophers
  vi main.go # change header color?
  curl localhost:8080/Gophers
  docker restart golang-demo
  docker logs -f golang-demo
  curl localhost:8080/Gophers
  docker rm -f golang-demo
  ```

- BuildKit Container:
  ```
  curl -sSL -o ~/Downloads/buildkit-v0.6.3.tgz https://github.com/moby/buildkit/releases/download/v0.6.3/buildkit-v0.6.3.linux-amd64.tar.gz
  tar -xvzf ~/Downloads/buildkit-v0.6.3.tgz --strip-components=1 -C ~/bin
  docker run -d --rm --name buildkitd --privileged moby/buildkit:latest
  export BUILDKIT_HOST=docker-container://buildkitd
  buildctl build \
    --frontend dockerfile.v0 \
    --local context=. --local dockerfile=. \
    --opt filename=Dockerfile.buildkit1 \
    --output type=docker,name=golang-hello:buildkit1 \
    | docker load
  docker container run --rm --name golang-demo -p 8080:8080 -d golang-hello:buildkit1
  curl localhost:8080/Gophers
  docker image ls golang-hello
  docker rm -f golang-demo
  ```

- BuildKit Docker
  ```
  diff Dockerfile.multi-stage4 Dockerfile.buildkit2
  DOCKER_BUILDKIT=1 docker build -f Dockerfile.buildkit2 -t golang-hello:buildkit2 .
  docker container run --rm --name golang-demo -p 8080:8080 -d golang-hello:buildkit2
  curl localhost:8080/Gophers
  docker rm -f golang-demo
  ```

- BuildKit experimental:
  ```
  diff -y -W 100 Dockerfile.buildkit2 Dockerfile.buildkit3
  DOCKER_BUILDKIT=0 docker build -f Dockerfile.buildkit3 -t golang-hello:buildkit3 .
  # experimental syntax is not backwards compatible
  DOCKER_BUILDKIT=1 docker build -f Dockerfile.buildkit3 -t golang-hello:buildkit3 .
  # notice that it skipped the debug stage
  docker container run --rm --name golang-demo -p 8080:8080 -d golang-hello:buildkit3
  curl localhost:8080/Gophers
  docker rm -f golang-demo
  ```

- Speed comparison with caching
  ```
  # split screen compare multi-stage to buildkit
  diff Dockerfile.buildkit3 Dockerfile.buildkit4
  DOCKER_BUILDKIT=0 docker build -f Dockerfile.multi-stage4 -t golang-hello:multi-stage4 .
  DOCKER_BUILDKIT=1 docker build -f Dockerfile.buildkit4 -t golang-hello:buildkit4 .
  vi go.mod # change a version number
  DOCKER_BUILDKIT=0 docker build -f Dockerfile.multi-stage4 -t golang-hello:multi-stage4 .
  DOCKER_BUILDKIT=1 docker build -f Dockerfile.buildkit4 -t golang-hello:buildkit4 .
  # buildkit is dramatically faster since it reuses caches of directories between builds
  ```

- Buildkit output
  ```
  rm ./out/app
  ls -al ./out/
  diff -y -W 100 Dockerfile.buildkit4 Dockerfile.buildkit5
  DOCKER_BUILDKIT=1 docker build -f Dockerfile.buildkit5 --target artifact --output type=local,dest=./out/ .
  ./out/app
  ```

- Buildkit with binfmt_misc:
  ```
  cat /proc/sys/fs/binfmt_misc/qemu-aarch64
  docker pull --platform=linux/arm64 golang:1.12-alpine
  DOCKER_BUILDKIT=1 docker build -f Dockerfile.buildkit6 -t golang-hello:buildkit6 \
    --platform linux/arm64 .
  docker image inspect golang-hello:buildkit6
  docker container run --rm --name golang-demo -p 8080:8080 -d golang-hello:buildkit6
  curl localhost:8080/Gophers
  docker rm -f golang-demo
  DOCKER_BUILDKIT=1 docker build -f Dockerfile.buildkit6 -t golang-hello:buildkit6-debug \
    --platform linux/arm64 --target=debug .
  docker container run --rm -it --name golang-demo -p 8080:8080 golang-hello:buildkit6-debug /bin/bash
  apt-get update && apt-get install -y file
  file /app /bin/ls
  exit
  docker pull golang:1.12-alpine
  ```

- Buildkit cross compiling:
  ```
  # different node, without qemu binfmt_misc configured
  cat /proc/sys/fs/binfmt_misc/qemu-arm
  diff -y -W 100 Dockerfile.buildkit6 Dockerfile.buildkit7
  DOCKER_BUILDKIT=1 docker build -f Dockerfile.buildkit6 -t golang-hello:buildkit6 \
    --platform linux/arm64 .
  DOCKER_BUILDKIT=1 docker build -f Dockerfile.buildkit7 -t golang-hello:buildkit7 \
    --platform linux/arm64 .
  docker image inspect golang-hello:buildkit7
  docker container run --rm --name golang-demo -p 8080:8080 -it golang-hello:buildkit7
  # does not work on host without qemu or on native host
  DOCKER_BUILDKIT=1 docker build -f Dockerfile.buildkit7 -t golang-hello:buildkit7-debug \
    --platform linux/arm64 --target=debug .
  docker container run --rm -it --name golang-demo -p 8080:8080 golang-hello:buildkit7-debug /bin/bash
  apt-get update && apt-get install -y file
  file /app /bin/ls
  exit
  ```

- Buildx multi-platform:
  ```
  # reset from previous demo
  docker buildx use default
  docker buildx rm rpi
  docker buildx rm container
  docker context rm rpi0
  ```

  ```
  diff Dockerfile.buildkit7 Dockerfile.buildx1
  # build multiple arch and push to registry
  docker context ls
  docker context create --docker "host=ssh://rpi0" --description "Raspberry Pi" rpi0
  docker --context rpi0 info
  docker buildx create --driver docker-container --name container default 
  docker buildx create --driver docker-container --name rpi rpi0 
  docker buildx inspect --bootstrap container
  docker buildx inspect --bootstrap rpi
  docker buildx ls
  docker buildx use container
  docker buildx build -f Dockerfile.buildx1 --platform linux/amd64,linux/arm64,linux/arm/v7 \
    -t bmitch3020/golang-hello:buildx1 --output type=registry .
  # check the contents of the manifest, note two platforms
  docker manifest inspect bmitch3020/golang-hello:buildx1
  # pull and run it
  docker pull bmitch3020/golang-hello:buildx1
  docker container run --rm -d --name golang-demo -p 8080:8080 \
    bmitch3020/golang-hello:buildx1
  curl localhost:8080/Gophers
  # we see that it's amd64, lets redo this for arm64
  docker rm -f golang-demo
  docker pull --platform linux/arm64 bmitch3020/golang-hello:buildx1
  docker container run --rm -d --name golang-demo -p 8080:8080 \
    --platform linux/arm64 bmitch3020/golang-hello:buildx1
  curl localhost:8080/Gophers
  # now we can see this is on arm64
  docker rm -f golang-demo
  docker --context rpi0 container run --rm -d --name golang-demo -p 8080:8080 \
    bmitch3020/golang-hello:buildx1
  curl rpi0:8080/Gophers
  docker --context rpi0 rm -f golang-demo
  ```

- Cache-to/cache-from
  - **Skip, could not get it to work.**
  ```
  dind-server.sh -t 19.03.0-rc2 3375
  dind-client.sh 3375
  docker buildx create --use --name dind-3375 127.0.0.1:3375 \
    || docker buildx use dind-3375
  docker buildx build -f Dockerfile.buildx2 --platform linux/amd64,linux/arm64 \
    --cache-from bmitch3020/golang-hello:cache2 --cache-to bmitch3020/golang-hello:cache2 \
    -t bmitch3020/golang-hello:buildx2 --output type=registry .
  # lets completely wipe everything and build with a small change
  exit # from dind 3375
  dind-server.sh -t 19.03.0-rc2 4375
  dind-client.sh 4375
  docker buildx create --use --name dind-4375 127.0.0.1:4375 \
    || docker buildx use dind-4375
  # here's the small change
  diff -y Dockerfile.buildx1 Dockerfile.buildx2
  docker buildx build -f Dockerfile.buildx3 --platform linux/amd64,linux/arm64 \
    --cache-from bmitch3020/golang-hello:cache2 --cache-to bmitch3020/golang-hello:cache3 \
    -t bmitch3020/golang-hello:buildx3 --output type=registry .
  # notice how much was cached, we didn't download the golang compiler, only the output layers
  # cleanup
  exit # from dind-4375
  docker rm -f dind-3375 dind-4375
  docker volume rm dind-3375 dind-4375
  ```

