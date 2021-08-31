# Changelog

## Release Candidate

### Features

* The download command now support filtering groups/packages with `--group-type` and `--package-type`

### Fixes

* Using `--history` to set a number of rpms versions to download now works as intended (was silently ignored)

## Version 0.5.1

### Features

* The file provided with `--package-list` now supports writing comments with `#`

### Fixes

* Fix issue with multi-line package list files in download mode
* Fix issue with the consolidation of GPG key files

## Version 0.5.0

This release is focused on ramping up unit tests and fixing issues discovered while doing so.

### Features

* Packages may now be provided without option to the 'download' command
* Add downloaded file options `--gpg-subfile`, `--module-subfile`, and `--group-subfile`
* Download mode's `--package-file` now supports bash pipes usage (`<(my_command)`)
* Huge performance improvement to download mode when not downloading RPM files
* Update shell-utilities dependency to `0.1.0`

### Fixes

* Download mode's `--no-resolve` is now properly honored if it is set

### Breaking changes

* In `download` mode, `--rpm` and `--no-rpm` were renamed to `--rpms` and `--no-rpms`
* When resolving cached datas, we now prioritize the current user's cache instead of the global cache

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
