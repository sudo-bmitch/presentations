#!/bin/sh

if [ "$(dirname "$0")" != "." -o ! -f "./convert-pdf.sh" ]; then
  echo "This hacky script assumes you are in the presentations directory, please cd there first"
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Please provide an html file to convert"
  exit 1
fi
htmlfile=${1}

if [ $# -gt 1 ]; then
  pdffile=$2
else
  pdffile=$(echo $htmlfile | sed 's/.[^.]*$/.pdf/')
fi

if [ "$htmlfile" = "$pdffile" ]; then
  echo "PDF file cannot be the same as the input file"
  exit 1
fi

if [ -f "$pdffile" ]; then
  echo -n "Overwrite $pdffile [y/n]? "
  read response
  case $response in
    [Yy]*) : ;;
    *)     exit 1;;
  esac
fi

docker container inspect nginx-preso >/dev/null 2>&1
nginx_running_rc=$?

if [ $nginx_running_rc != 0 ]; then
  echo "Running a webserver to avoid CORS errors"
  local/run-nginx.sh
fi
  
docker run --rm -it -u "$(id -u):$(id -g)" -v "$HOME:$HOME" -w "$(pwd)" \
  --net container:nginx-preso \
  astefanutti/decktape "http://localhost:8080/$htmlfile" "$pdffile"

if [ $nginx_running_rc != 0 ]; then
  docker stop nginx-preso
fi

