#!/bin/sh

opt_a=0
opt_s=10

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
slow

slow 'repo1="localhost:5001/demo-referrers-2023"
$ repourl1="http://localhost:5001/v2/demo-referrers-2023"
$ repo2="localhost:5002/demo-referrers-2023"
$ repourl2="http://localhost:5002/v2/demo-referrers-2023"
$ mtIndex="application/vnd.oci.image.index.v1+json"
$ mtImage="application/vnd.oci.image.manifest.v1+json"'

repo1="localhost:5001/demo-referrers-2023"
repourl1="http://localhost:5001/v2/demo-referrers-2023"
repo2="localhost:5002/demo-referrers-2023"
repourl2="http://localhost:5002/v2/demo-referrers-2023"
mtIndex="application/vnd.oci.image.index.v1+json"
mtImage="application/vnd.oci.image.manifest.v1+json"

# setup a distribution/distribution registry, OCI v1.0
slow 'docker run -d --rm --label demo=referrers \
  -e "REGISTRY_STORAGE_DELETE_ENABLED=true" \
  -e "REGISTRY_VALIDATION_DISABLED=true" \
  -p "127.0.0.1:5001:5000" \
  registry:2'
docker run -d --rm --label demo=referrers \
  -e "REGISTRY_STORAGE_DELETE_ENABLED=true" \
  -e "REGISTRY_VALIDATION_DISABLED=true" \
  -p "127.0.0.1:5001:5000" \
  registry:2
slow 'regctl registry set --tls=disabled localhost:5001'
regctl registry set --tls=disabled localhost:5001

# setup a zot registry, OCI v1.1
slow 'docker run -d --rm --label demo=referrers \
  -p "127.0.0.1:5002:5000" \
  ghcr.io/project-zot/zot-linux-amd64:latest'
docker run -d --rm --label demo=referrers \
  -p "127.0.0.1:5002:5000" \
  ghcr.io/project-zot/zot-linux-amd64:latest
slow 'regctl registry set --tls=disabled localhost:5002'
regctl registry set --tls=disabled localhost:5002

# copy and show the image, only copy a single platform for simplicity
slow 'digest=$(regctl image digest --platform linux/amd64 regclient/regctl:edge)'
digest=$(regctl image digest --platform linux/amd64 regclient/regctl:edge)
slow 'echo $digest'
echo $digest
slow 'regctl image copy regclient/regctl@${digest} ${repo1}:app'
regctl image copy regclient/regctl@${digest} ${repo1}:app

slow 'regctl manifest get ${repo1}:app --format body | jq .'
regctl manifest get ${repo1}:app --format body | jq .

slow
clear
slow

# generate and attach two SBOMs
slow 'syft packages -q "${repo1}:app" -o cyclonedx-json \
  | regctl artifact put --subject "${repo1}:app" \
      --artifact-type application/vnd.cyclonedx+json \
      -m application/vnd.cyclonedx+json \
      --annotation "org.opencontainers.artifact.description=CycloneDX JSON SBOM"'
syft packages -q "${repo1}:app" -o cyclonedx-json \
  | regctl artifact put --subject "${repo1}:app" \
      --artifact-type application/vnd.cyclonedx+json \
      -m application/vnd.cyclonedx+json \
      --annotation "org.opencontainers.artifact.description=CycloneDX JSON SBOM"
slow 'syft packages -q "${repo1}:app" -o spdx-json \
  | regctl artifact put --subject "${repo1}:app" \
      --artifact-type application/spdx+json \
      -m application/spdx+json \
      --annotation "org.opencontainers.artifact.description=SPDX JSON SBOM"'
syft packages -q "${repo1}:app" -o spdx-json \
  | regctl artifact put --subject "${repo1}:app" \
      --artifact-type application/spdx+json \
      -m application/spdx+json \
      --annotation "org.opencontainers.artifact.description=SPDX JSON SBOM"

slow
clear
slow

# show artifact list
slow 'regctl artifact list ${repo1}:app --format body | jq .'
regctl artifact list ${repo1}:app --format body | jq .

# show tag list and the digest
slow 'regctl tag list ${repo1}'
regctl tag list ${repo1}
slow 'echo ${digest#sha256:}'
echo ${digest#sha256:}
slow 'regctl manifest get ${repo1}:sha256-${digest#sha256:} --format body | jq .'
regctl manifest get ${repo1}:sha256-${digest#sha256:} --format body | jq .

# pull one sbom
slow 'regctl artifact get --subject ${repo1}:app --filter-artifact-type application/vnd.cyclonedx+json | more'
regctl artifact get --subject ${repo1}:app --filter-artifact-type application/vnd.cyclonedx+json | more

slow
clear
slow

# show curl method
slow 'curl -sS -H "Accept: $mtIndex" ${repourl1}/manifests/sha256-${digest#sha256:} | jq .'
curl -sS -H "Accept: $mtIndex" ${repourl1}/manifests/sha256-${digest#sha256:} | jq .
slow 'amDigest=$(curl -sS -H "Accept: $mtIndex" ${repourl1}/manifests/sha256-${digest#sha256:} | jq -r .manifests[0].digest)'
amDigest=$(curl -sS -H "Accept: $mtIndex" ${repourl1}/manifests/sha256-${digest#sha256:} | jq -r .manifests[0].digest)
slow 'curl -sS -H "Accept: $mtImage" ${repourl1}/manifests/${amDigest} | jq .'
curl -sS -H "Accept: $mtImage" ${repourl1}/manifests/${amDigest} | jq .
slow 'abDigest=$(curl -sS -H "Accept: $mtImage" ${repourl1}/manifests/${amDigest} | jq -r .layers[0].digest)'
abDigest=$(curl -sS -H "Accept: $mtImage" ${repourl1}/manifests/${amDigest} | jq -r .layers[0].digest)
slow 'curl -sS ${repourl1}/blobs/${abDigest} | jq . | more'
curl -sS ${repourl1}/blobs/${abDigest} | jq . | more

slow
clear
slow

# copy to zot
slow 'regctl image copy --referrers ${repo1}:app ${repo2}:app'
regctl image copy --referrers ${repo1}:app ${repo2}:app

# show artifact list
slow 'regctl artifact list ${repo2}:app --format body | jq .'
regctl artifact list ${repo2}:app --format body | jq .

# show tag list, referrers API avoids the need for tags
slow 'regctl tag list ${repo2}'
regctl tag list ${repo2}

# show curl
slow 'curl -sS -H "Accept: $mtIndex" ${repourl2}/manifests/sha256-${digest#sha256:} | jq .'
curl -sS -H "Accept: $mtIndex" ${repourl2}/manifests/sha256-${digest#sha256:} | jq .
slow 'curl -sS -H "Accept: $mtIndex" ${repourl2}/referrers/${digest} | jq .'
curl -sS -H "Accept: $mtIndex" ${repourl2}/referrers/${digest} | jq .

slow
clear
slow

# copy to OCI Layout
slow 'regctl image copy --referrers ${repo2}:app ocidir://oci-demo:app'
regctl image copy --referrers ${repo2}:app ocidir://oci-demo:app

# show artifact list and tag list
slow 'regctl artifact list ocidir://oci-demo:app --format body | jq .'
regctl artifact list ocidir://oci-demo:app --format body | jq .
slow 'regctl tag list ocidir://oci-demo'
regctl tag list ocidir://oci-demo

# show CLI access to files
slow 'cat oci-demo/index.json | jq .'
cat oci-demo/index.json | jq .
slow 'ls oci-demo/blobs/sha256'
ls oci-demo/blobs/sha256

# get referrers using jq to get digest of tag
slow 'tagDigest=$(cat oci-demo/index.json | jq -r .manifests[1].digest)'
tagDigest=$(cat oci-demo/index.json | jq -r .manifests[1].digest)
slow 'cat oci-demo/blobs/sha256/${tagDigest#sha256:} | jq .'
cat oci-demo/blobs/sha256/${tagDigest#sha256:} | jq .
slow 'amDigest=$(cat oci-demo/blobs/sha256/${tagDigest#sha256:} | jq -r .manifests[0].digest)'
amDigest=$(cat oci-demo/blobs/sha256/${tagDigest#sha256:} | jq -r .manifests[0].digest)
slow 'cat oci-demo/blobs/sha256/${amDigest#sha256:} | jq .'
cat oci-demo/blobs/sha256/${amDigest#sha256:} | jq .
slow 'abDigest=$(cat oci-demo/blobs/sha256/${amDigest#sha256:} | jq -r .layers[0].digest)'
abDigest=$(cat oci-demo/blobs/sha256/${amDigest#sha256:} | jq -r .layers[0].digest)
slow 'cat oci-demo/blobs/sha256/${abDigest#sha256:} | jq . | more'
cat oci-demo/blobs/sha256/${abDigest#sha256:} | jq . | more

slow
clear
slow

# show oras client
slow 'oras discover ${repo1}:app'
oras discover ${repo1}:app
slow 'oras discover ${repo2}:app'
oras discover ${repo2}:app

# show artifacts in the wild
slow 'regctl artifact list ghcr.io/regclient/regctl@${digest}'
regctl artifact list ghcr.io/regclient/regctl@${digest}
slow 'oras discover ghcr.io/regclient/regctl:edge --platform linux/amd64'
oras discover ghcr.io/regclient/regctl:edge --platform linux/amd64

slow
clear

# cleanup
slow 'docker stop $(docker ps --filter label=demo=referrers -q)'
docker stop $(docker ps --filter label=demo=referrers -q)
slow 'rm -r oci-demo'
rm -r oci-demo
