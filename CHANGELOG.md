# Changelog

## Release candidate

Add group and consolidate commands for download preparation and post-treatment

### Features

* Add groups instrospection utilities (see `rpm-manager group -h`)
* Add group and module merge commands (see `rpm-manager consolidate -h`)
* Add xmllint support for download (requires --xpath support)
* Add `--use-xmllint` and `--use-awk` commands to enforce new or legacy xml parsing

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
