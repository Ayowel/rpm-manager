# Changelog

## Release Candidate

### Features

* Packages may now be provided without option to the 'download' command
* Add downloaded file options `--gpg-subfile`, `--module-subfile`, and `--group-subfile
* Download mode's `--package-file` now supports bash pipes usage (`<(my_command)`)

### Breaking changes

* In `download` mode, `--rpm` and `--no-rpm` were renamed to `--rpms` and `--no-rpms`

## Version 0.4.0

### Features

* Add experimental gpgkey download and consolidation support for repositories
* [DEV] Start adding unit tests

### Fixes

* Look for local users directories when trying to fetch data in cache when the main dnf cache is unreadable

## Version 0.3.0

### Breaking changes

* Licensing update from GPLv3 to LGPLv3

## Version 0.2.1

### Fixes

* Fix an error that made using --group in download mode inoperative
* Fix a print issue on fatal errors

## Version 0.2.0

Add group and consolidate commands for download preparation and post-treatment

### Features

* Add groups instrospection utilities (see `rpm-manager group -h`)
* Add group and module merge commands (see `rpm-manager consolidate -h`)
* Add xmllint support for download (requires --xpath support)
* Add `--use-xmllint` and `--use-awk` commands to enforce new or legacy xml parsing
* Add `--version` flag

### Fixes

* DEV: Fix shellcheck linting to validate all internal scripts
* The documentation archive now only contains the html doc

### Breaking changes

* If xmllint is available, the download command WILL use it by default
* Custom download path patterns now require to use `%{REPO}` to use the repository's name instead of `%s`

## O.1.0

First release. This tool should not be considered production-ready.

### Features

* Provide a download command to save repositories rpms and metadata to individual directories
