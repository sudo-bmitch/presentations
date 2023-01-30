# Presentations from Brandon Mitchell

These slides are made with RemarkJS and should be viewable in any browser. From
the desktop, you can press "P" to see presenter notes. PDF's have also been
included when possible. For the slides with a live terminal, use "W" and "E" to
pause/play the recording.

Note: if you have cloned the repo locally, and are viewing the presentations by double clicking the html files, some embedded content may not display. There are several possible solutions:

1. View the content online, everything should be available from the links to GitHub pages.
2. If you have docker, run `local/run-nginx.sh` to start a web server on port 5080.
3. For Firefox, go to `about:config` and try setting `privacy.file_unique_origin` to `false`.  See [CVE-2019-11730](https://www.mozilla.org/en-US/security/advisories/mfsa2019-21/#CVE-2019-11730) for more details.

## Modifying the Immutable: Attaching Artifacts to OCI Images

This is a walk-through and demonstration of the OCI reference type working group result.
It shows how artifacts like SBOMs and signatures can be associated with images in an OCI registry.

- [Presentation](https://sudo-bmitch.github.io/presentations/oci-referrers/presentation.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/oci-referrers/presentation.pdf)]

## OCI Layout - Stop Putting Everything in Registries

How to use OCI Layout in CI pipelines to work with images before pushing them.
This also covers SBOMs, vulnerability scanning, and image signing, before the image is publicly available.

- [Presentation](https://sudo-bmitch.github.io/presentations/oci-layout/presentation.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/oci-layout/presentation.pdf)]

## Secure Supply Chain - 2021

This is an overview of what it takes to build a secure software supply chain, to tooling available, and where development is still in progress.
This also covers the value of reproducible builds.

- [Presentation](https://sudo-bmitch.github.io/presentations/secure-supply-chain-2021/presentation.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/secure-supply-chain-2021/presentation.pdf)]

## Docker Registry Mirroring - 2021

This is a workshop on setting up your own local registry mirror, including the process to garbage collect stale images.

- [Presentation](https://sudo-bmitch.github.io/presentations/reg-mirror-2021/presentation.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/reg-mirror-2021/presentation.pdf)]

## Docker Intro

Covering containers, images, networks, volumes, security, and building images.
These slides are still under development.

- [Presentation](https://sudo-bmitch.github.io/presentations/docker-intro/presentation.html)

## Docker Images

Images as they are saved on a registry, covering manifests, configs, and layers.

- [Presentation](https://sudo-bmitch.github.io/presentations/docker-images/presentation.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/docker-images/presentation.pdf)]

## Regclient

Shows how to use regctl, regsync, and regbot from the regclient projects.

- [Presentation](https://sudo-bmitch.github.io/presentations/regclient/presentation.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/regclient/presentation.pdf)]

## DockerCon 2020 - Docker Registry Mirroring and Caching

How to use registry mirroring and caching to optimize your image registry,
reducing time to build and deploy, while also saving bandwidth.

- [Presentation](https://sudo-bmitch.github.io/presentations/registry/presentation.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/registry/presentation.pdf)]
- [Extended presentation](https://sudo-bmitch.github.io/presentations/registry/presentation-extended.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/registry/presentation-extended.pdf)]

## Docker Build

Covering multi-stage, buildkit, buildx, and multi-architecture images from the
perspective of a Go user.

- [Presentation](https://sudo-bmitch.github.io/presentations/docker-build/presentation.html)

## DockerCon 2019 - Tips and Tricks From The Docker Captains

- [Original presentation](https://sudo-bmitch.github.io/presentations/dc2019/tips-and-tricks-of-the-captains.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/dc2019/tips-and-tricks-of-the-captains.pdf)]

- [Extended presentation](https://sudo-bmitch.github.io/presentations/dc2019/tips-and-tricks-of-the-captains-extended.html)

## BSides NoVA - Containing Security Vulnerabilities with Containers

- [Presentation](https://sudo-bmitch.github.io/presentations/bsides-nova/presentation.html)

## DockerCon 2018 EU - Tips and Tricks From A Docker Captain

- [Original presentation](https://sudo-bmitch.github.io/presentations/dc2018eu/tips-and-tricks-of-the-captains.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/dc2018eu/tips-and-tricks-of-the-captains.pdf)]

- [Extended presentation](https://sudo-bmitch.github.io/presentations/dc2018eu/tips-and-tricks-of-the-captains-extended.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/dc2018eu/tips-and-tricks-of-the-captains-extended.pdf)]

Note, this talk is from DockerCon 2018 EU and is a continuation on the
"Tips and Tricks of the Docker Captains" theme that was first started by
Captain [Adrian Mouat](https://twitter.com/adrianmouat). Check out [his talk
from DockerCon 2018 in San Francisco](https://drive.google.com/file/d/1RBAl2PfTnn-IZWzQEoiISaXh4GQOpjxL/view).

There was also a webinar given based on the above talk. Slides are almost identical to those above:

- [Webinar presentation](https://sudo-bmitch.github.io/presentations-webinar-20181212/dc2018eu/tips-and-tricks-of-the-captains.html)

## DockerCon 2018 - Frequently Asked Queries from StackOverflow

- [Full presentation](https://sudo-bmitch.github.io/presentations/dc2018/faq-stackoverflow.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/dc2018/faq-stackoverflow.pdf)]

- [Lightning talk](https://sudo-bmitch.github.io/presentations/dc2018/faq-stackoverflow-lightning.html)
  [[Download pdf](https://sudo-bmitch.github.io/presentations/dc2018/faq-stackoverflow-lightning.pdf)]

## Asciinema

- I use the player from: <https://github.com/asciinema/asciinema-player>
- The following commands are used to build a recording:

  ```shell
  # Install asciinema:
  apt-get install asciinema
  # Setup a window:
  printf '\e[8;26;100t' # set window size to 100x26
  tmux new-session -s preso
  PS1='\n\$ ' # minimal prompt
  # After windows are setup, detach from tmux (Ctrl-B D)
  # Create a recording:
  asciinema rec name.cast -i 3 -c "tmux attach -t preso"
  # Stop the recording by detaching (Ctrl-B D)
  # Tip: Edit the recording to remove the last few milliseconds of the detach
  # Replay the recording:
  asciinema play name.cast
  ```

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International Public
License](LICENSE)
