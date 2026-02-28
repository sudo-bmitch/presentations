# OCI Image and Distribution Spec 1.1

<div class="container">
<div class="col"><p data-markdown>

KCD DC 2024<br>
Brandon Mitchell<br>
2024-09-24

</p></div>

<div class="col" data-markdown>
<img src="../_shared/img/bmitch.jpg" class="pic-circle-title" alt="Photo"/>
</div>
</div>

Note:

After a long wait, OCI has finally released their 1.1.0 image and distribution specs. Find out what has changed in the spec and how you can leverage these changes today.

------

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

## OCI

- Open Container Initiative
- Under the Linux Foundation
- Defines the specifications for containers

Note:

- T 0:45
- Open Container Initiative
- Under LF: sibling to CNCF and OpenSSF, among others
- We are focused on specifications, with some code

------

## OCI specs

1. runtime-spec
1. image-spec <!-- .element: class="fragment" data-fragment-index="2" -->
1. distribution-spec <!-- .element: class="fragment" data-fragment-index="3" -->

Note:

- runtime-spec executes a container, implemented by runc.
- image-spec defines filesystem layers and the configuration data, implemented by containerd.
- distribution-spec defines the HTTP APIs to ship image content, implemented by registries.
- image and distribution had a 1.1 release in Feb 2024, here's what was included...

---

## Artifacts

- Formally defined in image-spec
- Uses the image manifest
- Added `artifactType` to manifests
- Defined an "empty" blob

Note:

- T 1:15
- Previously artifacts were documented in a separate repo describing how OCI could be used, this is formal support.
- Adding a new manifest would be a breaking change, so we leveraged the image manifest
- The `artifactType` field is a media type, and is used when an artifact doesn't have a separate configuration JSON blob
- Some fields are required in the image manifest, we can't undo that without breaking images, but we did define a stub value artifacts can use

------

## Associating Artifacts

- Artifacts can be associated with another manifest
- Image signing, attestations, and other metadata
- Added a `subject` field to the manifest

Note:

- T 1:30
- The hot trend a few years ago was "secure supply chain", and a cornerstone of that was signing and attestations (e.g. SLSA)
- OCI solved the distribution of that content by letting you push an artifact that references another manifest
- That reference is the `subject` field in your artifact, the signature has a subject field set to the digest of the image it signed
- So, with a given image digest, how do you find the signature artifact...

------

## Query Associations

- Registries added a `referrers` API
- Clients fallback to managing a tag
- Returns an Index listing all manifests matching the `subject`
- Each pointer includes the `artifactType` and annotations

Note:

- This is why image and distribution spec were so tightly coupled with their releases
- Client fallbacks can easily work on existing registries, they manage the response under a special tag (`sha256-...`)
- The response an OCI Index (same manifest type used for multi-platform images)
- Include the `artifactType` and annotations of each descriptor to quickly find the artifact for your tool

---

## Data field

- base64 encoding of content inlined in a manifest
- Used when overhead of another registry round trip is greater than base64 encoding overhead

Note:

- T 2:30
- Allows you to inline small blobs into the image manifest
- Useful when the overhead of API calls is greater than the overhead of base64 encoding

------

## Manifest Maximum Size

- Registries and tooling should support 4MiB manifests
- Don't pack everything in the data field or abuse annotations

Note:

- Some engines and registries already had limits, we just defined an expectation of what everyone should support.

------

## Deprecated Non-distributable Layers

- These were included for Windows images
- No longer needed by Microsoft so their use is discouraged

Note:

- T 3:00
- Microsoft needed these for legal reasons and no longer has that need, so we ask that no one use them in images going forward.

------

## zstd Compression

- Alternative to gzip compression for image layers
- May use less CPU and compress to a smaller size

Note:

- z-standard is an alternative to gzip that may result in smaller images and less CPU overhead, but support isn't universal.

------

## Multiple Matching Platforms

- When an Index has multiple entries that clients cannot differentiate
- Clients pick the first matching entry
- Gives ability to introduce new features while supporting existing runtimes

Note:

- For forward compatibility, when picking from a manifest list, used by multi-platform images, pick the first entry when the tool cannot tell the difference.

---

## Registry API Extensions

- Allows registries to add custom APIs
- Will not conflict with future OCI APIs
- Register to avoid conflicting with other registries

Note:

- T 3:30
- Allows registries to add their APIs under the same namespace without conflicting with OCI or others.

------

## Resumable Chunked Upload

- Allows an interrupted blob push to be resumed
- Needed to push large blobs on flaky networks

Note:

- Lets you recover from a network failure.

------

## Warning Header

- Registries can return a header on requests that client tooling should show
- Deprecation notices, security alerts, any non-fatal notification

Note:

- T 4:00
- This would have been useful for advertising the deprecation of the kubernetes registry.

------

## Anonymous Blob Mounts

- Pushing an image can "mount" layers from another repository
- That blob "mount" no longer requires the source repository

Note:

- Anonymous mounts are useful when multiple images are using base image from another registry.

---

## Summary

<div class="container">
<div class="col"><p data-markdown>

- Artifacts, Subject
- Data Field
- Maximum Size
- Deprecated Non-distributable Layers
- zstd Compression

</p></div>
<div class="col" data-markdown>

- Referrers API
- Registry API Extensions
- Resumable Chunked Uploads
- Warning Header
- Anonymous Blob Mounts

</div></div>

Note:

- T 4:45

---

# Thank You

<div class="container">
<div class="col"><p data-markdown>

![Presentations QR Link](../_shared/img/github-qr.png)

</div>
<div class="col"><p data-markdown>

- Brandon Mitchell
- GitHub: sudo-bmitch
- Mastodon: fosstodon.org/@bmitch
- github.com/opencontainers

</div>
</div>

github.com/sudo-bmitch/presentations

Note:

- Join OCI on their GitHub.
- These slides are also available on my GitHub repo.

<!-- markdownlint-disable-file MD025 -->
<!-- markdownlint-disable-file MD034 -->
<!-- markdownlint-disable-file MD033 -->
<!-- markdownlint-disable-file MD035 -->
