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

slow 'localrepo=localhost:5000/regclient/regsync'
localrepo=localhost:5000/regclient/regsync

slow 'localimage=${localrepo}:mod'
localimage=${localrepo}:mod

slow 'syft packages ${localimage} -o json >syft.json'
syft packages ${localimage} -o json >syft.json

slow 'syft convert syft.json -o cyclonedx-json >syft.cyclonedx.json'
syft convert syft.json -o cyclonedx-json >syft.cyclonedx.json

slow 'syft convert syft.json -o spdx-json >syft.spdx.json'
syft convert syft.json -o spdx-json >syft.spdx.json

slow 'regctl tag ls ${localrepo}'
regctl tag ls ${localrepo}

slow 'regctl artifact list ${localimage}'
regctl artifact list ${localimage}

slow 'regctl artifact put --artifact-type application/example.syft \
  -f syft.cyclonedx.json -m application/example.syft.cyclonedx+json \
  -f syft.spdx.json -m application/example.syft.spdx+json \
  --annotation created_by=syft \
  --annotation "created_on=$(date --utc --rfc-3339=seconds)" \
  --refers ${localimage}'

regctl artifact put --artifact-type application/example.syft \
  -f syft.cyclonedx.json -m application/example.syft.cyclonedx+json \
  -f syft.spdx.json -m application/example.syft.spdx+json \
  --annotation created_by=syft \
  --annotation "created_on=$(date --utc --rfc-3339=seconds)" \
  --refers ${localimage}

slow 'echo "Hello OCI" | regctl artifact put --annotation message=greeting --refers ${localimage}'
echo "Hello OCI" | regctl artifact put --annotation message=greeting --refers ${localimage}

slow 'regctl artifact list ${localimage}'
regctl artifact list ${localimage}

slow 'regctl artifact get --filter-annotation message=greeting --refers ${localimage}'
regctl artifact get --filter-annotation message=greeting --refers ${localimage}

slow 'regctl artifact get \
  --filter-artifact-type application/example.syft \
  -m application/example.syft.spdx+json \
  --refers ${localimage} | more'
regctl artifact get \
  --filter-artifact-type application/example.syft \
  -m application/example.syft.spdx+json \
  --refers ${localimage} | more

slow 'regctl tag ls ${localrepo}'
regctl tag ls ${localrepo}

slow 'digest=$(regctl image digest ${localimage})'
digest=$(regctl image digest ${localimage})

slow 'echo ${digest}'
echo ${digest}

slow 'regctl manifest get ${localrepo}:sha256-$(echo $digest | cut -f2 -d:)'
regctl manifest get ${localrepo}:sha256-$(echo $digest | cut -f2 -d:)

slow 'artifact="$(regctl manifest get ${localrepo}:sha256-$(echo $digest | cut -f2 -d:) \
  --format "{{ (index .Manifests 0).Digest }}")"'
artifact="$(regctl manifest get ${localrepo}:sha256-$(echo $digest | cut -f2 -d:) \
  --format "{{ (index .Manifests 0).Digest }}")"

slow 'regctl manifest get ${localrepo}@${artifact} --format body | jq .'
regctl manifest get ${localrepo}@${artifact} --format body | jq .

slow 'regctl image digest ${localimage}'
regctl image digest ${localimage}
