## @file
## @brief Simple utility functions used in other scripts

## @fn set_parse_error()
## @brief Record that an error occured
## @param message Error message to print later
set_parse_error() {
  FIRST_PARSE_ERROR="${FIRST_PARSE_ERROR:-$1}"
}

## @fn get_first_parse_error()
## @brief Print the first error that occured
## @return
##   * > The error message
##   * 1 if a message was printed, else 0
get_first_parse_error() {
  if test -n "$FIRST_PARSE_ERROR"; then
    echo "$FIRST_PARSE_ERROR"
    return 1
  fi
  return 0
}

## @fn get_repo_cache_path()
## @brief Returns the path to the local metadata folder for a repository
## @param repo_name Name of the repository whose cache path should be discovered
get_repo_cache_path() {
  local repo_name="$1"
  
  # Use 16 '?' as placeholder for the generated hash
  # TODO: find out how the hash is generated and generate it internally for deterministic resolution
  find /var/cache/dnf /var/tmp/dnf-* -mindepth 1 -maxdepth 1 -type d -name "${repo_name}-????????????????" ! -name "${repo_name}-*-*" 2>/dev/null | head -1
}

## @fn run_from_dir()
## @brief Run a command from a directory
## @param directory The directory to run from
## @param command... The command to execute
## @return 0 If no error occured
run_from_dir() {
  local target="$1"
  shift
  local retval
  pushd "$target" >/dev/null || return 1
  {
    "$@"
    retval="$?"
  }
  popd >/dev/null || return 1
  return "$retval"
}
