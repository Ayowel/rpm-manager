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

## @fn print_resource_by_path(path)
## @brief Prints-out the content of a file
## @param path The file's URI or path
print_resource_by_path() {
  local path="$1"

  # Detect if this is a local or remote file
  if test -e "$path"; then
    cat "$path"
  elif grep -qE '^(https?|file)://' <<<"$path"; then
    curl -s "$path"
  else
    return 1
  fi
}

## @fn print_unpacked_file_content(file, raw_pattern)
## @brief Print the content of an archive file
## @param file The file to unpack
## @param raw_pattern If the pattern matches the file's path, consider the file already unpacked
## @return
##    * $> The file's content
##    * 1 if an error occured or the file's format is unsupported, else 0
##    * $>&2 An error message if an error occured
## @note This should only be used on single-file archives
print_unpacked_file_content() {
  local target_file="$1"
  local raw_pattern="$2"

  if [ ! -f "$target_file" ] || [ ! -r "$target_file" ]; then
    echo "Failed to access file '$target_file'" >&2
    return 1
  fi

  if grep -qE "$raw_pattern" <<<"$target_file"; then
    cat "$target_file"
  else
    case "$target_file" in
      *.gz)
        gunzip -kc "$target_file"
        ;;
      *.xz)
        xz -kcd "$target_file"
        ;;
      *)
        echo "Unsupported file format for '$target_file'" >&2
        return 1
        ;;
    esac
  fi
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
