#!/bin/sh

set -e

remoteimg="$1"
localimg="$2"
backupext="${3:-$(date +%Y%m%d)}"
datestamp="$(date +%Y%m%d)"
: "${prune_backups:=0}"

# pull both, local first to get shared layers on faster connection
docker image pull -q "$localimg" || true
docker image pull -q "$remoteimg"

# compare image id's, these will match when image is unchanged
localid=$(docker image inspect "$localimg" --format '{{.Id}}' 2>/dev/null || true)
remoteid=$(docker image inspect "$remoteimg" --format '{{.Id}}')
if [ -n "$remoteid" ] && [ "$remoteid" != "$localid" ]; then
  # backup previous local image
  if [ -n "$localid" ]; then
    docker image tag "$localimg" "$localimg.$datestamp"
    docker image push "$localimg.$datestamp"
    echo "Backup name: $localimg.$datestamp" >&2
    [ "$prune_backups" != 0 ] && docker image rm "$localimg.$datestamp"
  fi
  # push new image to local mirror
  docker image tag "$remoteimg" "$localimg"
  docker image push "$localimg"
  echo "Updated: $localimg" >&2
elif [ ! -n "$remoteid" ]; then
  # with "set -e", this is unlikely to be reached, failed pull will happen instead
  echo "Warning: no image ID for remote image $remoteimg" >&2
  exit 1
else
  echo "No change: $localimg" >&2
fi

exit 0

