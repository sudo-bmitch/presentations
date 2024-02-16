# OCI and regclient

<div class="container">
<div class="col"><p data-markdown>

Cloud Native Luxembourg
Brandon Mitchell
2024-02-13

</p></div>

<div class="col" data-markdown>
<img src="../_shared/img/bmitch.jpg" class="pic-circle-70" alt="Photo"/>
</div>
</div>

---

## whoami

```shell
$ whoami
- Brandon Mitchell
- OSS Developer
- OCI Maintainer, regclient, Docker Captain
- StackOverflow, CNCF, OpenSSF
```

Note:

- Recently retired from consulting but may return for independent contract work once I get bored
- I focus on Open Source development
- Most of my work is in OCI, I'm a maintainer there, on the TOB, and my own side projects like regclient and olareg focus on it
- I'm also a Docker Captain
- And I can be found on Stack Overflow answering questions, or in CNCF and OpenSSF meetings

---

## OCI specs

1. runtime-spec
1. image-spec <!-- .element: class="fragment" data-fragment-index="2" -->
1. distribution-spec <!-- .element: class="fragment" data-fragment-index="3" -->

Note:

- runtime-spec is used to turn a filesystem and configuration into a container.
- image-spec is used to define the filesystem and configuration data structures.
- distribution-spec defines the HTTP APIs to ship image content.

---

## Registries

- Registries implement the distribution-spec
- API and a bit of metadata/management on top of a data store
- Built on Merkle Trees and Content Addressability

Note:

- Registries are often a thin API on top of an S3 data store.
- The API and management leverages content addressability and Merkle trees
- Result is immutability with a simple reference

---

## Blobs

- Lowest level data structure
- Opaque data (json, tar, gif, binary, etc)
- Named by the hash of its content

Note:

- 99% of registry storage is typically blob content, its almost all container image filesystem layers

------

## Blob: Content Addressability

```shell
$ regctl blob get ocidir://output/regctl \
    sha256:a0bbcef6dfea17bb0c9d6753e708f87... \
  | sha256sum
a0bbcef6dfea17bb0c9d6753e708f87...  -
```

------

## Blob: Config

```shell
$ regctl blob get ocidir://output/regctl \
    sha256:a0bbcef6dfea17bb0c9d6753e708f87... \
  | jq .
{
  "created": "2023-11-09T19:36:19Z",
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "User": "appuser",
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin..."
    ],
    "Entrypoint": [
      "/regctl"
    ],
...
```

------

## Blob: Layers

```shell
$ regctl blob get ocidir://output/regctl \
    sha256:8d45cbeb0e9342913c7a1f5212daec96... \
  | tar -tvzf -
drwxr-xr-x 0/0               0 2023-11-09 14:36 etc/
-rw-r--r-- 0/0             720 2023-11-09 14:36 etc/group
-rw-r--r-- 0/0            1229 2023-11-09 14:36 etc/passwd
```

---

## Manifests

- JSON data structures parsed by registries
- Image manifests identify a blob for the config, and a list of blobs for layers
- Index manifests contain a list of manifests
- Each reference to content is a descriptor <!-- .element: class="fragment" data-fragment-index="2" -->
  - JSON structure with: media type, digest, size

Note:

- Manifests are non-opaque, parsed by registries, to understand the relationships
- Every manifest has a media type used by the registry to parse it
- Image manifests are the root data structure of a single image
- Index manifests are often used for multi-platform images, descriptors include the platform
- Descriptors may contain additional fields, but must have mt, digest, size

------

## Image Manifest

```json
{
 "mediaType": "application/vnd.oci.image.manifest.v1+json",
 "config": {
  "mediaType": "application/vnd.oci.image.config.v1+json",
  "digest": "sha256:a0bbcef6dfea17bb0c9d6753e708f87be31...",
  "size": 3101
 },
 "layers": [
  {
   "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
   "digest": "sha256:77cc5d38ae6cd88138627ad233e9701b7...",
   "size": 92
  },
...
 ],
 "annotations": {
  "org.opencontainers.image.created": "2023-11-09T19:36:19Z"
 }
}
```

Note:

- The image manifest has the config and an array of layer descriptors
- Each descriptor is a pointer to another content addressable blob

------

## Index Manifest

```json
{
 "mediaType": "application/vnd.oci.image.index.v1+json",
 "manifests": [
  {
   "mediaType": "application/vnd.oci.image.manifest.v1+json",
   "digest": "sha256:d301bbb0aab4c166de121bf1b999b1cad02...",
   "size": 1298,
   "platform": {
     "architecture": "amd64",
     "os": "linux"
   }
  },
  ...
 ],
 "annotations": {
  "org.opencontainers.image.created": "2023-11-09T19:36:19Z",
  "org.opencontainers.image.revision": "db3e8a434431e7f6998c3e90507e45450398facb",
  "org.opencontainers.image.source": "https://github.com/regclient/regclient.git",
  "org.opencontainers.image.version": "edge"
 }
}

```

Note:

- Index contains an array of descriptors to image manifests
- The platform is used by runtimes to identify their entry without pulling every one

---

## Artifacts

- Manifests that do not package a runnable container image
- Image manifest is overloaded to serve artifacts
- Differentiate with config media type
- Defined an empty JSON blob to fill in required fields <!-- .element: class="fragment" data-fragment-index="2" -->
- Added an "artifactType" field for artifacts without a config blob <!-- .element: class="fragment" data-fragment-index="2" -->

Note:

- Artifacts are just things that are not runnable container images
- Reuse the image manifest
- The image manifest requires the config blob and at least one layer in the spec
  - So we have a media type for an empty JSON blob to indicate a descriptor is unused
  - Allows pushing data without a defining config schema
- Differentiate with the config media type, and added "artifactType"
- Media type of the layers has historically also been used to prevent runtimes from ingesting them

------

## Artifact

```json
{
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "artifactType": "application/spdx+json",
  "config": {
    "mediaType": "application/vnd.oci.empty.v1+json",
    "digest": "sha256:44136fa355b3678a1146ad16f7e8649e9...",
    "size": 2
  },
  "layers": [
    {
      "mediaType": "application/spdx+json",
      "digest": "sha256:0dbd95a7a958019dbdc3c62e423bcc7...",
      "size": 17415
    }
  ],
  "subject": {
    "mediaType": "application/vnd.oci.image.manifest.v1+json",
    "digest": "sha256:d301bbb0aab4c166de121bf1b999b1cad...",
    "size": 1298
  },
  "annotations": {
    "org.opencontainers.image.created": "2023-11-10T14:55:20Z",
    "org.opencontainers.image.description": "SPDX JSON SBOM"
  }
}
```

Note:

- Here's an example artifact without a config
- `artifactType` is specified
- The config is set to our "empty JSON" placeholder
- One layer with the appropriate media type (see IANA for those)

---

## Tags

- Named pointer to a manifest digest in a repository
- Designed to be human readable
- Mutable: "v1" today may be different from last week <!-- .element: class="fragment" data-fragment-index="2" -->
- Non-exclusive: "v1" and "v1.2.3" may point to the same digest <!-- .element: class="fragment" data-fragment-index="2" -->

Note:

- Tags provide a symbolic link to a manifest
- Human readable value so users do not need to memorize digests
- Tags can change over time (`v1` today may be different from yesterday)
- Multiple tags may point to the same manifests (`v1` and `v1.2.3`)
- A tag can point to an index or an image
- Cannot point to multiple manifests simultaneously
- Tags, and descriptors, are all scoped to a repository

---

## Referrers

- New API discovering loose relationships between manifests
- Associate signatures, attestations, SBOMs, etc, with an image
- Subject descriptor in a manifest may reference another manifest <!-- .element: class="fragment" data-fragment-index="2" -->
- Referrers API returns an index of all manifests with a given subject digest <!-- .element: class="fragment" data-fragment-index="3" -->

Note:

- How to associate signatures, SBOMs, etc to an image without changing the image and being discoverable?
- OCI had a working group, looked at how the community was creating different options, and we created a standard solution to improve interoperability.
- This is close to GA now.
- Implemented with a new descriptor in manifests called the "subject"
- Added an API to the registry to query for any manifest containing a subject with a requested digest
- Workflow: pull an image, get the digest for the image, query referrers with that image digest, and get a list of all artifacts that are associated with that image.
- Referrers response is an index, each descriptor includes the artifact type and annotations from the artifact.
  - Similar to the multi-platform index, client can identify which descriptor it is interested in without pulling everything.
- We can push/pull these after the image is created, e.g. company security team may want to ingest and sign an image after scanning it.
- We can ignore content that doesn't match our desired artifact type or annotation.

------

## Referrers Fallback

- Image and Index manifests are extended
  - Added the "subject" and "artifactType" fields
  - New fields should be ignored by old tools
- Client tooling falls back to managing a Tag <!-- .element: class="fragment" data-fragment-index="2" -->
  - Tag is formatted `sha256-1234...`
  - Response is an Index manifest

Note:

- The changes to the manifests are supported because new fields are allowed.
  - Clients parsing JSON should ignore unknown fields if they are OCI conformant.
- Tags are already used today by the sigstore project, we named ours slightly differently to avoid collisions.
- Client management is less ideal, bad clients and race conditions.
- Necessary because it will take time for registry support to roll out, particularly in self hosted environments.

---

## Data Structure

![OCI Diagram](./oci-diagram.svg) <!-- .element: class="pic-rounded-10" -->

Note:

- Here's a resulting image
- There's an index that points to two platform specific images
- Those images each have a config and layers
- And image B has two images with a subject field referencing it
- Each of those artifact images happens to have an empty config and single layer
- The referrers response for digest B returns an array of the two artifact images

---

## OCI Layout

- Filesystem definition for a repository
- Uses and index to reference the manifests/tags
- Filenames for content addressability
- Useful for air-gap, CI pipelines, and scanners

---

## OCI Ecosystem

- Build tooling: buildkit, buildah, kaniko, buildpacks
- Runtimes: containerd/runc, podman, crun, wasm <!-- .element: class="fragment" data-fragment-index="2" -->
- Applications: Helm, Flux, sigstore/cosign, notation <!-- .element: class="fragment" data-fragment-index="3" -->
- Clients: crane, ORAS, regclient, skopeo <!-- .element: class="fragment" data-fragment-index="4" -->

Note:

- OCI has a healthy ecosystem of tools built around it
- There's a variety of build tools designed to output OCI images
- Multiple runtimes consume those images
- Various applications are using OCI as their persistent storage
- I spend most of my time with client tooling to query, copy, and manage data in OCI registries

---

## regclient

- Go client library
- regctl: CLI for regclient <!-- .element: class="fragment" data-fragment-index="2" -->
- regsync: tool for maintaining mirrors<!-- .element: class="fragment" data-fragment-index="3" -->
- regbot: Lua based scripting <!-- .element: class="fragment" data-fragment-index="4" -->

Note:

- The client tooling that I've written is called regclient
- It's a Go library with 3 commands included
- The first command I made was `regctl` which is very similar to `crane` and `skopeo`, providing a CLI to common registry actions, imperative.
- For managing mirrors, I made `regsync` which copies images based on a yaml config.
- Once you manage a local mirror, `regbot` was originally created to manage retention policies. It uses Lua scripting because everyone has a different policy.

---

## regctl: Query

```shell [1|2-3|4-5|6-7|8-9]
regctl tag ls
regctl image digest
regctl manifest get
regctl image config
regctl blob get
regctl artifact list
regctl artifact get
regctl image get-file
regctl blob get-file
```

Note:

- There's a variety of subcommands to query a registry.

------

## regctl: Copy

```shell [1|2-3]
regctl image copy
regctl image import
regctl image export
```

Note:

- Copying images is the main power tool in regctl
- Copy is better than docker pull/push because only the changed layers are transferred, multi-platform images are supported, and the digest does not change
- Same command to retag, efficient with blob copies, only changed layers
- Source or destination may be an OCI Layout (air-gap)
- Import/Export are only useful to output to a tar for docker save/load

------

## regctl: Create

```shell [1-3|4|5-6]
regctl index create
regctl index add
regctl index rm
regctl artifact put
regctl manifest put
regctl blob put
```

Note:

- Creating content has different commands based on the content type
- `index create` makes a manifest list, can also add or remove entries from an index, useful to extract specific platforms from a multi-platform list.
- `artifact put` is very useful for pushing your own content to registries.
- `manifest put` and `blob put` allow you to manually create your own image. I almost never use this.

------

## regctl: Delete

```shell
regctl manifest rm
regctl tag rm
```

Note:

- Registries must support delete operations for these commands to work
- Deleting an image manifest deletes both the manifest and every tag that points to the manifest
- Deleting a tag removes a single pointer and the manifest could be later garbage collected
- Deleting a blob is on my short list to add for completeness, but registries should manage this for you

------

## regctl: Compare

```shell [1|2-3]
regctl manifest diff
regctl blob diff-config
regctl blob diff-layer
```

Note:

- The compare commands were created to debug reproducible build issues
- The manifest diff will highlight which digest changed
- The layer diff commands will show which files changed

------

## regctl: Modify

```shell
regctl image mod
```

Note:

- This is a bit more experimental, but useful for changing an image that's already been built.
- I do this for reproducibility: changing timestamps, deleting layers and files, adding annotations.
- It's also useful to convert to the OCI media types.
- Others want to modify config options: exposed ports, volumes.
- It can rebase an image
- It can convert external to local layers (air-gapped windows images)

---

## regsync

- Managed with a yaml config
- Schedule updates by cron or frequency
- Concurrency
- Backup before overwriting
- Filtering tags (in or out)
- Monitoring rate limits (Docker Hub)

Note:

- `regsync` is designed to be put in a container and left to run along side a mirror
- It was created as Docker Hub was announcing their rate limits and people realized they should maintain their own copy
- Scheduling enables organizations to decide when they want to update their local mirror (not 4pm on a Friday)
- Backups lets you easily rollback after an issue is encountered

------

```yaml
sync:
  - source: busybox:latest
    target: registry:5000/library/busybox:latest
    type: image
    backup: "bkup-{{.Ref.Tag}}"
  - source: alpine
    target: registry:5000/library/alpine
    type: repository
    tags:
      allow:
      - "latest"
      - "3"
      - "3.\\d+"
```

Note:

- Here's an example to sync two repositories
- One copies a single image and keeps a backup
- The other copies all tags matching the regexp

---

## regbot

- Lua interface to various regclient APIs
- Allows scripting for retention policies
- Can also be used for more complex image copy commands

Note:

- `regbot` was created for implementing retention policies
- Everyone has a different retention policy (by number of tags, date stamp, sprint number, etc)
- Since it wraps regclient APIs, it can be used for other scripting tasks, e.g. converting semver v1.2.3 to v1.2 and v1 tags

------

```yaml
scripts:
  - script: |
      ref = reference.new("registry:5000/regclient/example")
      tagExp = "^ci%-%d+$"
      imageLabel = "org.opencontainers.image.created"
      cutoff = os.date("!%Y-%m-%d", os.time() - (86400*30))
      tags = table.sort(tag.ls(ref))
      for k, t in pairs(tags) do
        if string.match(t, tagExp) then
          ref:tag(t)
          ic = image.config(ref)
          if ic.Config.Labels[imageLabel] < cutoff then
            tag.delete(ref)
          end ...
```

Note:

- Here's a stripped down retention policy
- It deletes all tags matching an expression with a label before the cutoff

---

# Demo

---

## Useful Links

- github.com/opencontainers/image-spec
- github.com/opencontainers/distribution-spec
- github.com/regclient/regclient/
- github.com/olareg/olareg <!-- .element: class="fragment" data-fragment-index="2" -->

Note:

- OCI does their spec work in GitHub
- regclient is my own project on GitHub
- And one more thing:
  - I've been working on an OCI Layout based Registry
  - Very early stages, no auth, no docs, no release yet
  - Useful for the edge, CI pipelines, and unit tests
  - Intentionally minimized dependencies (go-digest and cobra)

---

# Thank You

<div class="container">
<div class="col"><p data-markdown>

![Presentations QR Link](../_shared/img/github-qr.png)

</div>
<div class="col"><p data-markdown>

- Brandon Mitchell
- GitHub: sudo-bmitch
- Mastodon: @bmitch@fosstodon.org
- Twitter: @sudo_bmitch

</div>
</div>

github.com/sudo-bmitch/presentations

<!-- markdownlint-disable-file MD025 -->
<!-- markdownlint-disable-file MD034 -->
<!-- markdownlint-disable-file MD033 -->
<!-- markdownlint-disable-file MD035 -->
