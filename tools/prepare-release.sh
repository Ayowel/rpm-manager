#!/bin/bash
# This script updates the files thatcontain a version number
if test "$#" -ne 1 || ! [[ "$1" =~ [0-9]+\.[0-9]+\.[0-9]+[-a-z]* ]]; then
  echo 'This script takes a single version number as argument' >&2
  exit 1
fi

version_number="$1"

sed -i -e "s/^\\(PROJECT_NUMBER\\s*=\\s*\\).*\$/\\1${version_number}/" tools/Doxyfile
sed -i -e "0,/^## .*$/s//## Version ${version_number}/" CHANGELOG.md 
sed -i -e "s/\\(VERSION_NUMBER=\\).*$/\\1${version_number}/g" src/core.sh
