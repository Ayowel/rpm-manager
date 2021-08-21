# RPM Download Helper tool

[![Release number](https://shields.io/github/v/release/Ayowel/rpm-manager)](https://github.com/Ayowel/rpm-manager/releases/latest) [![Worflow status](https://shields.io/github/workflow/status/Ayowel/rpm-manager/Main)](https://github.com/Ayowel/rpm-manager/actions) [![Coverage status](https://shields.io/codecov/c/github/Ayowel/rpm-manager)](https://codecov.io/github/Ayowel/rpm-manager/)

## Introduction

This tool enables the full or partial download of enabled repositories' content while keeping track of the original repository's source.

If you can afford to make a full repository clone and do not care about knowing which repository provides what feature, you should probably try to use wget or `dnf repoquery '*' | xargs dnf download` instead.

## Usage

### From a repository checkout

```bash
# Download all packages from all enabled local repositories
./main.sh download
# Download package 'bash' and its dependencies in 'rpms' directory
./main.sh -R rpms download --package bash
```

### From a release

After downloading the release package and unpacking it in the path, you may start to use `rpm-manager` from anywhere on your system.

```bash
# Download all packages from all enabled local repositories
rpm-manager download
# Download package 'bash' and its dependencies in 'rpms' directory
rpm-manager -R rpms download --package bash
```

## Set-up an environment

* An environment with dnf support and the ability to install the `download` command

### Setting-up a Fedora/CentOS container

* Start the container with a mount to this project (use only one of these commands)

```bash
# On linux
docker run --rm -itv "$(pwd):/mnt" fedora /bin/bash
docker run --rm -itv "$(pwd):/mnt" centos /bin/bash
# On windows
docker run --rm -itv "%cd%:/mnt" fedora /bin/bash
docker run --rm -itv "%cd%:/mnt" fedora /bin/bash
```

* Install runtime dependencies

```bash
dnf install -y  'dnf-command(download)' libxml2
```

### Setting-up a RedHat container

If you do not have a registered RedHat host system, we recommend setting-up a redhat container:

* Start a RedHat container and register it

```bash
# Download a base RedHat 8 image
docker image pull registry.access.redhat.com/ubi8/ubi
# Run a container and register with a valid RedHat account USERNAME & PASSWORD
docker run --name registered_redhat -it registry.access.redhat.com/ubi8/ubi subscription-manager register --auto-attach --username USERNAME
docker exec
# Save the registered container
docker commit registered_redhat registered_redhat_ubi
# Cleanup
docker container rm registered_redhat
```

* Run the new image

```bash
# On linux
docker run --rm -itv "$(pwd):/mnt" registered_redhat_ubi /bin/bash
# On windows
docker run --rm -itv "%cd%:/mnt" registered_redhat_ubi /bin/bash
```

* Install runtime dependencies

```bash
dnf install -y  'dnf-command(download)' libxml2
```

*WARNING:* if you ever wish to permanently delete the image, run `docker run --rm -it registered_redhat_ubi subscription-manager unregister` first to ensure that the subscription for the container is removed from the associated account's redhat subscription list.
