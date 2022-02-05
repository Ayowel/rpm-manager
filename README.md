# RPM Download Helper tool

[![Release number](https://shields.io/github/v/release/Ayowel/rpm-manager)](https://github.com/Ayowel/rpm-manager/releases/latest) [![Worflow status](https://shields.io/github/workflow/status/Ayowel/rpm-manager/Main)](https://github.com/Ayowel/rpm-manager/actions) [![Coverage status](https://shields.io/codecov/c/github/Ayowel/rpm-manager)](https://codecov.io/github/Ayowel/rpm-manager/)

## Introduction

This tool's aim is to assist in the creation of offline rpm repositories by enabling the download of all or part of the RPMs and other data associated with enabled rpm repositories.

## Should I use this ?

In most cases, no. You should only use-this if all of the following are true:

* One or more of your workstations/servers does not have access to the internet / to remote repositories
* You can't set-up a repository proxy server or a cache server. Some existing solutions:
  * [RedHat Satellite](https://www.redhat.com/en/technologies/management/satellite)
  * [Pulp](http://www.pulpproject.org/)
  * [Nexus](https://fr.sonatype.com/products/repository-oss)
  * [Squid](http://www.squid-cache.org/)
* Yum cache is not enough for your needs. See [yum's caching instructions](http://yum.baseurl.org/wiki/YumMultipleMachineCaching.html) 
* You have limited disk space in-house (otherwise, use `wget -r` on the repositories you need to create full clones)

## Usage

The `dnf-command(download)` package MUST be installed on the system.
`libxml2` SHOULD be installed on the system for maximum reliability.

### Repository download

Download rpms, gpg keys, modules and groups from all enabled repositories.

```bash
# Download all packages from all enabled local repositories
rpm-manager download
# Download package 'bash' and its dependencies in 'rpms' directory
rpm-manager -R rpms download --package bash
```

See `rpm-manager download --help` for more.

### Repository groups introspection

Get subgroups of an environment group.

```bash
# Get mandatory groups of an environment group
rpm-manager group list -G mandatory Server
```

Get packages of a group.

```bash
# Get required packages of mandatory groups of an environment group
rpm-manager group packages -G mandatory,self -P default,mandatory Server
```

See `rpm-manager group --help` for more

### Downloaded data consolidation

Gather saved metadata in cohesive blocks

```bash
# Regroup groups of all directories in a single file
rpm-manager consolidate group -o all_comps.xml */comps.xml
```

See `rpm-manager consolidate --help` for more

## Contribute

We do not yet have contribution guidelines, but instructions on how to set-up a development environment are available [here](DEVELOPER.md).
