#!/bin/bash

## START shell-utilities code inclusion
## This code is under MIT license
# shellcheck disable=SC1091
source vendors/shell-utilities/src/commons.sh
# shellcheck disable=SC1091
source vendors/shell-utilities/src/argument_parser.sh
## END shell-utilities code inclusion

source src/commons.sh
source src/dnf_commons.sh
source src/groups.sh
source src/consolidate.sh
source src/download.sh
source src/core.sh

if test -z "${BASH_SOURCE[0]}" || test "${BASH_SOURCE[0]}" == "$0"; then
  main "$@"
fi
