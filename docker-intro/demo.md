# Demo commands

- What is a container
  ```
  ps -ef | grep tail
  docker container run -d --rm --name test busybox:latest tail -f /dev/null
  ps -ef | grep tail
  docker container exec test ps -ef
  docker container kill test

  ps -ef
  docker container run -it --rm centos:latest bash
  ps -ef
  id
  hostname
  hostname hacker-wuz-here
  date 123123591999
  uname -v
  ls -al /proc/self/ns
  exit

  uname -v
  ls -al /proc/self/ns
  ```

- TODO: Image
  ```
  docker image pull ???
  docker image inspect ...
  docker image history ...
  ```

- Lifecycle
  ```
  docker container run -it --name test1 debian:latest bash
  rm /bin/sleep
  echo "hello world" >/hello
  ls -l /bin/sleep
  cat /hello
  exit

  docker container restart test1
  docker container exec -it test1 bash
  ls -l /bin/sleep
  cat /hello
  exit

  docker container run -it --name test2 debian:latest bash
  ls -l /bin/sleep
  cat /hello
  exit

  docker container ls -a
  docker container restart test2
  docker container stop test1
  docker container kill test2
  docker container rm test1 test2
  ```

- Debugging:
  ```
  docker container run -d --name web -p 8080:80 nginx:latest

  curl localhost:8080
  curl localhost:8080/no-such-file.html
  docker container logs web
  docker container inspect web

  docker container exec -it web bash
  ls -alR /usr/share/nginx/html
  ps -ef
  apt-get update
  apt-get install -y procps
  exit

  docker container stop web
  docker container rm web
  ```

- Volumes:
  ```
  mkdir -p test-vol
  cd test-vol
  cat >Dockerfile <<EOF
  FROM busybox:latest
  
  RUN mkdir -p /vol/anonymous /vol/host /vol/named \
   && echo "from build: anonymous" >/vol/anonymous/build.txt \
   && echo "from build: host" >/vol/host/build.txt \
   && echo "from build: named" >/vol/named/build.txt
  EOF
  docker image build -t test-vol:latest -f Dockerfile .

  docker container run -it --rm test-vol:latest ls -lR /vol

  docker container run -it --name test1 \
    -v /vol/anonymous \
    -v "$(pwd)/host-vol:/vol/host" \
    -v test1:/vol/named \
    test-vol:latest sh
  ls -lR /vol
  cd /vol/anonymous
  echo "anonymous file" >file.txt
  cd /vol/host
  echo "host file" >file.txt
  cd /vol/named
  echo "named file" >file.txt
  more /vol/anonymous/file.txt
  more /vol/host/file.txt
  more /vol/named/file.txt
  exit

  ls -al host-vol

  docker container run -it --name test2 \
    -v /vol/anonymous \
    -v "$(pwd)/host-vol:/vol/host" \
    -v test1:/vol/named \
    test-vol:latest sh
  more /vol/*/file.txt
  exit

  docker volume ls

  docker container rm test1 test2
  cd ..
  ```

- Networking
  ```
  docker network create test-br
  docker network ls

  docker container run -d --net test-br -p 8080:80 --name web nginx:latest

  curl localhost
  curl localhost:8080

  docker container exec -it web sh
  curl localhost:8080
  apt-get update
  apt-get install -y curl
  curl localhost:8080
  curl localhost
  exit

  docker container run -it --net test-br --rm alpine sh
  curl localhost
  apk add curl
  curl localhost
  curl localhost:8080
  ping -c 3 web
  curl web:8080
  curl web
  exit

  docker container stop web
  docker container rm web
  ```

- Docker Compose
  ```
  git clone https://github.com/dockersamples/example-voting-app.git
  cd example-voting-app
  more docker-compose.yml
  docker-compose up -d

  curl localhost:5000
  curl -d "vote=a" localhost:5000
  curl -d "vote=a" localhost:5000
  curl -d "vote=b" localhost:5000

  docker-compose ps
  docker-compose logs vote
  docker-compose logs worker
  docker-compose restart redis
  docker-compose ps
  docker-compose restart worker
  docker-compose ps

  docker-compose down -v
  cd ..
  ```

- Security
  ```
  docker container run -it --rm debian bash
  id
  shutdown -h +15
  mount proc /mnt
  date 123123591999
  date
  ip address change 8.8.8.8 dev eth0
  exit 0

  docker container run -it --rm --read-only --tmpfs /data debian bash
  touch /tmp/test
  cp /bin/rm /bin/ls
  ls /
  cp /bin/rm /data/app
  ls -al /data/app
  /data/app /data/crown-jewels
  mount | grep /data
  exit 0
  ```

- Overlay Filesystem
  ```
  odir=/var/lib/docker/lab
  mkdir -p ${odir}/layer1 ${odir}/layer2 ${odir}/layer3 ${odir}/work
  echo layer1 > ${odir}/layer1/hello
  echo layer1 > ${odir}/layer1/world
  ls -al ${odir}/layer1 ${odir}/layer2 ${odir}/layer3 ${odir}/work
  mkdir -p /mnt/overlay

  mount -t overlay overlay -o workdir=${odir}/work,upperdir=${odir}/layer2,lowerdir=${odir}/layer1 /mnt/overlay
  cat /mnt/overlay/hello
  cat /mnt/overlay/world
  echo layer2 > /mnt/overlay/world
  cat /mnt/overlay/world
  umount /mnt/overlay
  ls -al ${odir}/layer1 ${odir}/layer2 ${odir}/layer3 ${odir}/work

  mount -t overlay overlay -o workdir=${odir}/work,upperdir=${odir}/layer3,lowerdir=${odir}/layer2:${odir}/layer1 /mnt/overlay
  cat /mnt/overlay/hello
  cat /mnt/overlay/world
  rm /mnt/overlay/hello
  chmod 755 /mnt/overlay/world
  echo layer3 > /mnt/overlay/new-file
  umount /mnt/overlay
  ls -al ${odir}/layer1 ${odir}/layer2 ${odir}/layer3 ${odir}/work

  mount -t overlay overlay -o workdir=${odir}/work,lowerdir=${odir}/layer2:${odir}/layer1 /mnt/overlay
  cat /mnt/overlay/hello
  cat /mnt/overlay/world
  echo container > /mnt/overlay/temp
  umount /mnt/overlay
  ls -al ${odir}/layer1 ${odir}/layer2 ${odir}/work

  rm -r ${odir}/layer1 ${odir}/layer2 ${odir}/layer3 ${odir}/work
  ```

- Build Intro - Moby Say
  ```
  mkdir mobysay
  cat >moby.cow <<EOF
  ##
  ## Docker Cow
  ##
  ## Source: https://github.com/docker/whalesay
  \$the_cow = <<EOC;
      \$thoughts
       \$thoughts
        \$thoughts
  EOC
  \$the_cow .= <<'EOC';
                      ##         .
                ## ## ##        ==
             ## ## ## ## ##    ===
         /"""""""""""""""""\___/ ===
        {                       /  ===-
         \______ O           __/
           \    \         __/
            \____\_______/
  
  EOC
  EOF

  cat >Dockerfile <<EOF
  FROM debian:10
  
  ARG DEBIAN_FRONTEND=noninteractive
  RUN apt-get update \
   && apt-get install -y --no-install-recommends cowsay
  
  COPY moby.cow /usr/share/cowsay/cows/
  
  ENV PATH=$PATH:/usr/games
  
  ENTRYPOINT [ "cowsay", "-f", "moby.cow" ]
  CMD [ "Whale hello there" ]
  EOF

  docker image build -t mobysay:0.1 .
  docker run --rm mobysay:0.1
  docker run --rm mobysay:0.1 Whaley great to meet you
  cd ..
  ```

- Build Next Steps - Developer workflow
  ```
  git clone https://github.com/sudo-bmitch/presentations.git
  cd presentations/docker-intro/example/flask
  cat Dockerfile
  docker image build -t flask-demo ./flask

  docker container run -d -p 8080:80 --name flask flask-demo
  curl localhost:8080

  vi templates/index.html # update name or any other content
  docker image build -t flask-demo ./flask
  curl localhost:8080

  docker container run -d -p 8080:80 --name flask flask-demo
  docker container stop flask
  docker container rm flask
  docker container run -d -p 8080:80 --name flask flask-demo
  curl localhost:8080
  docker container stop flask
  docker container rm flask

  docker container run -d -p 8080:80 --name flask --env "NAME=Local Dev" flask-demo
  curl localhost:8080
  docker container stop flask
  docker container rm flask

  docker container run -d -p 8080:80 --name flask -v "$(pwd):/app:ro" flask-demo
  curl localhost:8080
  vi templates/index.html # return to original content
  curl localhost:8080
  docker container stop flask
  docker container rm flask

  cd
  ```






