#!/bin/sh

opt_a=0
opt_s=15

while getopts 'ahs:' option; do
  case $option in
    a) opt_a=1;;
    h) opt_h=1;;
    s) opt_s="$OPTARG";;
  esac
done
set +e
shift `expr $OPTIND - 1`

if [ $# -gt 0 -o "$opt_h" = "1" ]; then
  echo "Usage: $0 [opts]"
  echo " -a: automatically run script without pausing"
  echo " -h: this help message"
  echo " -s bps: speed (default $opt_s)"
  exit 1
fi

slow() {
  echo -n "\$ $@" | pv -qL $opt_s
  if [ "$opt_a" = "0" ]; then
    read lf
  else
    echo
  fi
}

clear

slow ''

clear

slow 'image=regclient/regsync:edge-alpine'
image=regclient/regsync:edge-alpine

slow 'localrepo=localhost:5000/regclient/regsync'
localrepo=localhost:5000/regclient/regsync

slow 'localimage=${localrepo}:edge-alpine'
localimage=${localrepo}:edge-alpine

slow 'regctl tag ls ${localrepo}'
regctl tag ls ${localrepo}

slow 'regctl image copy -v info ${image} ${localimage}'
regctl image copy -v info ${image} ${localimage}

slow 'regctl manifest get ${localimage} | more'
regctl manifest get ${localimage} | more

slow 'regctl manifest get ${localimage} --platform linux/amd64 --format body | jq . | more'
regctl manifest get ${localimage} --platform linux/amd64 --format body | jq . | more

slow 'regctl image config ${localimage} --platform linux/amd64 | more'
regctl image config ${localimage} --platform linux/amd64 | more

slow 'regctl image mod --help | more'
regctl image mod --help | more

slow 'regctl image mod ${localimage} --create mod --to-oci --label-to-annotation'
regctl image mod ${localimage} --create mod --to-oci --label-to-annotation

slow 'regctl manifest get ${localrepo}:mod | more'
regctl manifest get ${localrepo}:mod | more

slow 'regctl manifest get ${localrepo}:mod --platform linux/amd64 --format body | jq . | more'
regctl manifest get ${localrepo}:mod --platform linux/amd64 --format body | jq . | more

slow 'regctl image config ${localrepo}:mod --platform linux/amd64 | more'
regctl image config ${localrepo}:mod --platform linux/amd64 | more
