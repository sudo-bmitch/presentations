# Registry Mirroring Workshop

## Start a Registry

```shell
docker container run -d --restart=unless-stopped --name registry \
  -e "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry" \
  -e "REGISTRY_STORAGE_DELETE_ENABLED=true" \
  -e "REGISTRY_VALIDATION_DISABLED=true" \
  -v "registry-data:/var/lib/registry" \
  -p "127.0.0.1:5000:5000" \
  registry:2
```

## Configure a Policy

Create a `regsync.yml` that looks like the following.
You may substitute your own image names.
This example assumes you want to use your Hub login which helps with rate limits.

```yaml
version: 1
creds:
  - registry: localhost:5000
    tls: disabled
  - registry: docker.io
    # the next two lines pass through the Hub login from an env variable and external file
    # delete these lines to use anonymous logins to Hub
    user: "{{env \"HUB_USER\"}}"
    pass: "{{file \"/home/appuser/.docker/hub_token\"}}"
defaults:
  ratelimit:
    min: 60
    retry: 15m
  parallel: 2
  interval: 60m
  backup: "{{ $t := time.Now }}{{printf \"bkup-%s-%d%02d%02d\" .Ref.Tag $t.Year $t.Month $t.Day}}"
sync:
  - source: busybox:latest
    target: localhost:5000/library/busybox:latest
    type: image
  - source: alpine
    target: localhost:5000/library/alpine
    type: repository
    tags:
      allow:
      - "latest"
      - "3"
      - "3.13"
      - "3.14"
```

## Test the Configuration

To use your Hub login, define your username in the HUB_USER variable, and create a file called `${HOME}/.docker/hub_token` that includes your credentials.
If you have 2FA enabled (recommended), you'll need to specify your access token from <https://hub.docker.com/settings/security>.

```shell
export HUB_USER=your_username
mkdir -p ${HOME}/.docker
echo "your_hub_password" >${HOME}/.docker/hub_token
docker container run -it --rm --net host \
  -v "$(pwd)/regsync.yml:/home/appuser/regsync.yml:ro" \
  -v "${HOME}/.docker/hub_token:/home/appuser/.docker/hub_token:ro" \
  -e "HUB_USER" \
  regclient/regsync:latest -c /home/appuser/regsync.yml once
```

## Automate

If the `once` command above looks good, run this as a background service with the following:

```shell
docker container run -d --restart=unless-stopped --name regsync --net host \
  -v "$(pwd)/regsync.yml:/home/appuser/regsync.yml:ro" \
  -v "$(pwd)/hub_token:/var/run/secrets/hub_token:ro" \
  -e "HUB_USER" \
  regclient/regsync:latest -c /home/appuser/regsync.yml server
```

## Using the Mirror

Create a `Dockerfile` like the below, or update your own `Dockerfile`.

```Dockerfile
ARG REGISTRY=docker.io
FROM ${REGISTRY}/library/alpine:3.14

RUN apk add curl
ENTRYPOINT [ "curl" ]
```

This can be built using your local mirror with:

```shell
docker image build --build-arg REGISTRY=localhost:5000 -t localhost:5000/${HUB_USER}/curl .
docker image push localhost:5000/${HUB_USER}/curl
docker container run -it --rm localhost:5000/${HUB_USER}/curl https://google.com/
```

## Garbage Collection

Several of the below steps use `regctl`.
You can install it from [https://github.com/regclient/regclient/](https://github.com/regclient/regclient/releases) or set the below alias to run it as a container:

```shell
alias regctl='docker container run --rm --net host \
  -u "$(id -u):$(id -g)" -e HOME -v "$HOME:$HOME" -w "$(pwd)" \
  regclient/regctl:latest'
```

Configure `regctl` to access the local registry without TLS:

```shell
regctl registry set localhost:5000 --tls disabled
```

Run the following command to create various backup tags to test the cleanup policy (it may take 10 seconds to finish):

```shell
for day in 20210831 20210901 20210902 20210903 20210904; do
  regctl image copy localhost:5000/library/alpine:3       localhost:5000/library/alpine:bkup-3-${day}
  regctl image copy localhost:5000/library/alpine:latest  localhost:5000/library/alpine:bkup-latest-${day}
  regctl image copy localhost:5000/library/busybox:latest localhost:5000/library/busybox:bkup-latest-${day}
done
```

Verify the tags were created:

```shell
regctl tag ls localhost:5000/library/alpine
regctl tag ls localhost:5000/library/busybox
```

Next, create a `regbot.yml` with the following:

```yml
version: 1
creds:
  - registry: localhost:5000
    tls: disabled
defaults:
  parallel: 1
  interval: 60m
  timeout: 600s
scripts:
  - name: delete old backups
    script: |
      reg = "localhost:5000"
      backupExpr = "^bkup%-(.+)%-(%d+)$"
      backupLimit = 3
      -- list all repos, could replace this with a fixed list
      repos = repo.ls(reg)
      table.sort(repos)
      -- loop over each repo
      for k, r in pairs(repos) do
        -- list all tags in the repo
        tags = tag.ls(reg .. "/" .. r)
        table.sort(tags)
        backupTags = {}
        for k, t in pairs(tags) do
          -- search for tags matching backup expression (e.g. bkup-latest-20210102)
          if string.match(t, backupExpr) then
            tOrig, tVer = string.match(t, backupExpr)
            -- backupTags is a nested table, e.g. backupTags[latest]={.. backup tags for latest ..}
            if not backupTags[tOrig] then
              backupTags[tOrig] = {}
            end
            table.insert(backupTags[tOrig], t)
          end
        end
        for tOrig, tVers in pairs(backupTags) do
          -- if any original tag has too many backups
          if #tVers > backupLimit then
            -- delete the first n tags to get back to the limit, sorted to delete oldest backups first
            table.sort(tVers)
            delVers = {unpack(tVers, 1, #tVers - backupLimit)}
            for k, t in pairs(delVers) do
              -- log("Deleting old backup: " .. reg .. "/" .. r .. ":" .. t)
              tag.delete(reg .. "/" .. r .. ":" .. t)
            end
          end
        end
      end
```

Now test the `regbot` config to be sure it works and only intends to delete the oldest backups:

```shell
docker container run -it --rm --net host \
  -v "$(pwd)/regbot.yml:/home/appuser/regbot.yml" \
  regclient/regbot:latest -c /home/appuser/regbot.yml once --dry-run
```

If that looks good, you can run the delete immediately by removing the `--dry-run` flag:

```shell
docker container run -it --rm --net host \
  -v "$(pwd)/regbot.yml:/home/appuser/regbot.yml" \
  regclient/regbot:latest -c /home/appuser/regbot.yml once
```

To automate the cleanup, use the `server` command and run the container in the background.
It will perform a cleanup every hour (according to the `interval` setting in the script).

```shell
docker container run -d --restart=unless-stopped --name regbot --net host \
  -v "$(pwd)/regbot.yml:/home/appuser/regbot.yml" \
  regclient/regbot:latest -c /home/appuser/regbot.yml server
```

Registries do not delete the underlying layers when manifests and tags are deleted.
If you are running the registry from this workshop, run the following to execute a garbage collection:

```shell
docker exec registry /bin/registry garbage-collect /etc/docker/registry/config.yml --delete-untagged
```

Note the above garbage collection command should not be done when images could be uploaded to the registry.
In production, the registry should be either stopped, placed in read-only mode, or the garbage collection should be scheduled for an idle time.

You can use the `regctl` command to verify the backup tags have been limited to the latest 3 versions:

```shell
regctl tag ls localhost:5000/library/alpine
regctl tag ls localhost:5000/library/busybox
```

## Cleanup

To cleanup from this workshop, you can run the following to stop and delete the containers and volumes:

```shell
docker container stop registry regsync regbot
docker container rm registry regsync regbot
docker volume rm registry-data
```
