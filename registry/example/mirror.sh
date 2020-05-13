#!/bin/sh

set -e

remoteimg="$1"
localimg="$2"
datestamp="$(date +%Y%m%d)"

# pull both, local first to get shared layers on faster connection
docker image pull "$localimg" || true
docker image pull "$remoteimg"

# compare image id's, these will match when image is unchanged
remoteid=$(docker image inspect "$remoteimg" --format '{.Id}')
localid=$(docker image inspect "$localimg" --format '{.Id}' 2>/dev/null || true)
if [ -n "$remoteid" ] && [ "$remoteid" != "$localid" ]; then
  # backup previous local image if old version exists
  if [ -n "$localid" ]; then
    docker image tag "$localimg" "$localimg.$datestamp"
    docker image push "$localimg.$datestamp"
    echo "Backup name: $localimg.$datestamp" >&2
  fi
  docker image tag "$remoteimg" "$localimg"
  docker image push "$localimg"
  echo "Updated: $localimg" >&2
else
  echo "No change: $localimg" >&2
fi

