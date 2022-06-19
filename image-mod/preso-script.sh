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

# what's an image?
slow 'repo="localhost:5000/library/debian"'
repo="localhost:5000/library/debian"

slow 'regctl manifest get ${repo}'
regctl manifest get ${repo}

# in this case, it's a manifest list, which contains pointers to platform specific images
# how are digests computed?
slow 'regctl manifest get ${repo} --format body | sha256sum'
regctl manifest get ${repo} --format body | sha256sum

# registries are a CAS: content addressable storage
# the actual manifest is just json when not reformatted
slow 'regctl manifest get ${repo} --format body | jq .'
regctl manifest get ${repo} --format body | jq .

# and since this is a multi-platform image, we can pull up the manifest for a single platform
slow "digest0=\"\$(regctl manifest get \${repo} --format '{{ (index .Manifests 0).Digest }}')\""
digest0="$(regctl manifest get ${repo} --format '{{ (index .Manifests 0).Digest }}')"
slow 'echo $digest0'
echo $digest0
slow 'regctl manifest get ${repo}@${digest0}'
regctl manifest get ${repo}@${digest0}

# it's a config and layers, but what's a config?
slow "config=\"\$(regctl manifest get \${repo}@\${digest0} --format '{{ .Config.Digest }}')\""
config="$(regctl manifest get ${repo}@${digest0} --format '{{ .Config.Digest }}')"

# first, it's a CAS
slow 'echo ${config}'
echo ${config}
slow 'regctl blob get ${repo} ${config} | sha256sum'
regctl blob get ${repo} ${config} | sha256sum

# and it's just json
slow 'regctl blob get ${repo} ${config} | jq .'
regctl blob get ${repo} ${config} | jq .

# compare that to a layer
slow "layer0=\"\$(regctl manifest get \${repo}@\${digest0} --format '{{ (index .Layers 0).Digest }}')\""
layer0="$(regctl manifest get ${repo}@${digest0} --format '{{ (index .Layers 0).Digest }}')"
slow 'regctl blob get ${repo} ${layer0} | tar -tvzf - | head -20'
regctl blob get ${repo} ${layer0} | tar -tvzf - | head -20

# but what if we wanted to change part of it?
# everything is a CAS, you change one digest, and everything above it changes
# some tooling would make this easier
slow 'regctl image mod --help'
regctl image mod --help
slow 'new_tag=bb-all-hands'
new_tag=bb-all-hands

# first, copy to ocidir
slow 'ocidir="ocidir://demorepo"'
ocidir="ocidir://demorepo"
slow 'regctl image copy ${repo} ${ocidir}'
regctl image copy ${repo} ${ocidir}

# now lets change things
slow 'regctl image mod \
  --to-oci \
  --label mod-by=bmitch \
  --time-max 2021-10-31T22:11:33Z \
  --annotation org.opencontainers.image.vendor=Docker \
  --layer-strip-file bin/dmesg \
  --create ${new_tag} \
  ${ocidir}'
regctl image mod \
  --to-oci \
  --label mod-by=bmitch \
  --time-max 2021-10-31T22:11:33Z \
  --annotation org.opencontainers.image.vendor=Docker \
  --layer-strip-file bin/dmesg \
  --create ${new_tag} \
  ${ocidir}

# what changed?
slow 'regctl manifest get ${ocidir}'
regctl manifest get ${ocidir}
slow 'regctl manifest get ${ocidir}:${new_tag}'
regctl manifest get ${ocidir}:${new_tag}
slow 'regctl manifest get ${ocidir} --platform linux/amd64'
regctl manifest get ${ocidir} --platform linux/amd64
slow 'regctl manifest get ${ocidir}:${new_tag} --platform linux/amd64'
regctl manifest get ${ocidir}:${new_tag} --platform linux/amd64
slow 'regctl image config ${ocidir} --platform linux/amd64'
regctl image config ${ocidir} --platform linux/amd64
slow 'regctl image config ${ocidir}:${new_tag} --platform linux/amd64'
regctl image config ${ocidir}:${new_tag} --platform linux/amd64
slow "digestmod0=\"\$(regctl manifest get \${ocidir}:\${new_tag} --format '{{ (index .Manifests 0).Digest }}')\""
digestmod0="$(regctl manifest get ${ocidir}:${new_tag} --format '{{ (index .Manifests 0).Digest }}')"
slow "layermod0=\"\$(regctl manifest get \${ocidir}@\${digestmod0} --format '{{ (index .Layers 0).Digest }}')\""
layermod0="$(regctl manifest get ${ocidir}@${digestmod0} --format '{{ (index .Layers 0).Digest }}')"
slow 'regctl blob get ${ocidir} ${layermod0} | tar -tvzf - | head -20'
regctl blob get ${ocidir} ${layermod0} | tar -tvzf - | head -20

# why?
# - adding/setting annotations
# - reproducible builds (stripping timestamps and files that change)
# - strip a layer like `COPY ... RUN make install`, delete the COPY after build
# - mirroring microsoft images, stripping the nonredistributable flags
# - tweaking settings from upstream images (exposed ports, volumes)