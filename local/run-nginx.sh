#!/bin/sh

cd $(dirname $0)

if docker container inspect nginx-preso >/dev/null 2>&1; then
  docker stop nginx-preso
  sleep 10
fi

docker run --name nginx-preso --rm -d -p 127.0.0.1:5080:8080 \
  -u "$(id -u):$(id -g)" \
  -v "$(pwd)/nginx.conf:/etc/nginx/nginx.conf" \
  -v "$(pwd)/..:/usr/share/nginx/html" \
  nginx:latest

echo "Connect to http://127.0.0.1:5080"

