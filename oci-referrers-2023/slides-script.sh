#!/bin/sh

reg="localhost:5000"
repo="demo-referrers-2023"
fullrepo="${reg}/${repo}"

regctl image copy alpine "${fullrepo}:alpine"

echo "contains electrons" \
  | regctl artifact put \
    --config-type application/vnd.example.ebom.config \
    -m application/vnd.example.ebom.data \
    --annotation "org.opencontainers.artifact.created=2023-02-01T09:10:11Z" \
    "${fullrepo}:ebom"

echo "contains electrons" \
  | regctl artifact put \
    --artifact-type application/vnd.example.ebom \
    -m application/vnd.example.ebom \
    --annotation "org.opencontainers.artifact.created=2023-02-01T09:10:11Z" \
    --subject "${fullrepo}:alpine"
    