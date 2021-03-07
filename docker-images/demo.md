# Docker Images Demo Commands

Setup:

```
docker network create registry
docker container run \
  -d --restart=unless-stopped --name registry --net registry \
  -e "REGISTRY_LOG_LEVEL=info" \
  -e "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry" \
  -e "REGISTRY_STORAGE_DELETE_ENABLED=true" \
  -e "REGISTRY_VALIDATION_DISABLED=true" \
  -v "registry-data:/var/lib/registry" \
  -p "127.0.0.1:5000:5000" \
  registry:2
regctl registry set localhost:5000 --tls disabled
regctl image copy debian:buster-slim localhost:5000/library/debian:buster-slim
regctl image copy nginx:latest localhost:5000/library/nginx:latest
```

Manifest:

```
regctl image manifest localhost:5000/library/nginx:latest --list --raw-body
regctl image manifest localhost:5000/library/nginx:latest --list --raw-body | jq .

digest="sha256:b08ecc9f7997452ef24358f3e43b9c66888fadb31f3e5de22fec922975caa75a"
regctl image manifest localhost:5000/library/nginx@$digest --raw-body

regctl image manifest localhost:5000/library/nginx@$digest --raw-body | sha256sum
echo $digest
```

Config:

```
config=$(regctl image manifest localhost:5000/library/nginx@$digest --raw-body | jq -r .config.digest)
regctl layer pull localhost:5000/library/nginx $config | jq .

docker image inspect nginx:latest
docker image history nginx:latest
```

Layers:
```
layer=$(regctl image manifest localhost:5000/library/nginx@$digest --raw-body | jq -r .layers[0].digest)
echo $layer
regctl layer pull localhost:5000/library/nginx $layer | sha256sum

regctl layer pull localhost:5000/library/nginx $config | jq .rootfs.diff_ids
regctl layer pull localhost:5000/library/nginx $layer | gunzip | sha256sum

regctl layer pull localhost:5000/library/nginx $layer | tar -tvzf - | more

regctl image manifest localhost:5000/library/debian:buster-slim
echo $layer
```
