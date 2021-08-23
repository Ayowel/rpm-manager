## @file
## @brief Main functions used to handle the script's lifecycle

## @fn help()
## @brief Prints a help message
help() {
  cat - <<EOH
usage: $0 download
       $0 group list GROUP...
       $0 group packages GROUP...
       $0 consolidate group -o group.xml GROUP_PATH...
       $0 consolidate module -o module.yaml MODULE_PATH...

Core options:
  -h|--help      Display this help message
  -R|--root-directory ROOT  Run from ROOT directory
  -v|--verbose   Enable verbose logging

EOH
  if test -n "$SELECTED_MODE"; then
    if type "help_${SELECTED_MODE}" >/dev/null 2>&1; then
      "help_${SELECTED_MODE}"
    fi
  else
    local mode
    for mode in "${MODE_SOURCES[@]}"; do
      if type "help_${mode}" >/dev/null 2>&1; then
        "help_${mode}"
      fi
    done
  fi
}

## @fn version()
## @brief Prints the version number
version() {
  echo "v${VERSION_NUMBER}"
}

## @fn init()
## @brief Initialize the execution environments and global variables defaults
init() {
  PRINT_HELP=1
  PRINT_VERSION=1
  VERBOSE=1
  VERSION_NUMBER=0.5.0

  MODE_SOURCES=( group download consolidate )
  SELECTED_MODE=
  TARGET_DIRECTORY=

  # Which parser to use when extracting information from xml files
  USE_XMLLINT=
  USE_AWK=

  for init_sources in "${MODE_SOURCES[@]}"; do
    "init_${init_sources}"
  done

  ## Stabilize dnf's output by explicitly setting its locale
  export LANG=C.UTF-8
}

## @fn parse_args(option, parameter, flag)
## @brief Parses received parameters
## @param option An option string (such as '-h')
## @param parameter A parameter value
## @param flag Whether a parameter value was actually set
parse_args() {
  case "$1" in
    -R|--root-directory)
      TARGET_DIRECTORY="$2"
      return 2
      ;;
    -h|--help)
      PRINT_HELP=0
      return 1
      ;;
    --version)
      PRINT_VERSION=0
      return 1
      ;;
    -v|--verbose)
      VERBOSE=0
      return 1
      ;;
    --use-awk)
      # Set globally for valorisation in dependant scripts 
      # shellcheck disable=SC2034
      USE_AWK=0
      return 1
      ;;
    --use-xmllint)
      # Set globally for valorisation in dependant scripts 
      # shellcheck disable=SC2034
      USE_XMLLINT=0
      return 1
      ;;
    '')
      if test -z "$SELECTED_MODE"; then
        SELECTED_MODE="$2"
        return 2
      fi
      ;;
  esac
  local retVal=0
  case "$SELECTED_MODE" in
    group|download|consolidate)
      "parse_args_${SELECTED_MODE}" "$@"
      retVal=$?
      ;;
    '')
      # Do nothing if no mode has been set
      ;;
    *)
      set_parse_error "Unsupported mode '${SELECTED_MODE}'"
      ;;
  esac
  if test "$retVal" -eq 0; then
    # Failed to handle/parse arguments
    set_parse_error "Unsupported option or parameter $1 $2"
    return 3
  fi
  return $retVal
}

## @fn post_parse()
## @brief Finish setting environment and validate inputs after argument parsing completes
post_parse() {
  TARGET_DIRECTORY="${TARGET_DIRECTORY:-.}"
  if ! test -d "$TARGET_DIRECTORY"; then
    set_parse_error "Received invalid execution directory path '$TARGET_DIRECTORY'"
  fi

  # Ensure that the mode received from the user is valid and run the associated post_parse function
  local mode
  local valid_mode=1
  for mode in "${MODE_SOURCES[@]}"; do
    if test "$SELECTED_MODE" == "$mode"; then
      valid_mode=0
      "post_parse_${SELECTED_MODE}"
    fi
  done
  if test "$valid_mode" -ne 0; then
    set_parse_error "No valid mode used: $SELECTED_MODE"
  fi
}

## @fn main(target_directory)
## @brief Download rpms into a directory (note that subdirectories will be created)
## @param target_directory The directory RPM files should be downloaded to (defaults to .)
## @param $< A newline-separated list of rpms to download
function main() {
  init
  argument_parsing_assistant parse_args "$@"
  post_parse

  if test "$PRINT_HELP" -eq 0; then
    help
    return 0
  fi
  if test "$PRINT_VERSION" -eq 0; then
    version
    return 0
  fi
  get_first_parse_error >&1
  if test "$?" -ne 0; then
    return 1
  fi

  test "$VERBOSE" -eq 0 && echo "Running in mode '$SELECTED_MODE'"
  # This is garded by checks performed in post_parse
  run_from_dir "$TARGET_DIRECTORY" "main_${SELECTED_MODE}"
}
