## @file
## @brief Help to parse arguments written free-flow by a user

## @fn argument_parsing_assistant()
## @brief Argument parsing intemediate function to ease the handling of multiple ways to input parameters
## @param callback The name of a function that honors #argument_parsing_assistant_virtual_callback's contract
## @param params... The parameters to parse
## @return 0 If parsing finished without error, else the first error code returned by \p callback
## @note
##   Other attributes that may have an effect on this function's processing include
##   #ARGPARSE_SHORT_OPTION_PREFIX, #ARGPARSE_LONG_OPTION_PREFIX,
##   #ARGPARSE_SHORT_OPTION_ENABLE, #ARGPARSE_LONG_OPTION_ENABLE,
##   #ARGPARSE_SHORT_OPTION_NORMALIZED_PREFIX, #ARGPARSE_LONG_OPTION_NORMALIZED_PREFIX, and
##   #ARGPARSE_LONG_OPTION_FIELD_SEPARATOR
argument_parsing_assistant() {
  local callback_function="$1"
  if test "$#" -eq 0; then
    echo 'argument_parsing_assistant should never be called without providing a callback function' >&2
    return 1
  fi
  shift

  # Set default environment parameters values if not set
  if test "${#ARGPARSE_SHORT_OPTION_PREFIX[@]}" -eq 0; then
    ARGPARSE_SHORT_OPTION_PREFIX=( - )
  fi
  ARGPARSE_SHORT_OPTION_ENABLE="${ARGPARSE_SHORT_OPTION_ENABLE:-0}"
  #ARGPARSE_SHORT_OPTION_NORMALIZED_PREFIX="$ARGPARSE_SHORT_OPTION_NORMALIZED_PREFIX"
  if test "${#ARGPARSE_LONG_OPTION_PREFIX[@]}" -eq 0; then
    ARGPARSE_LONG_OPTION_PREFIX=( -- )
  fi
  ARGPARSE_LONG_OPTION_ENABLE="${ARGPARSE_LONG_OPTION_ENABLE:-0}"
  #ARGPARSE_LONG_OPTION_NORMALIZED_PREFIX="$ARGPARSE_LONG_OPTION_NORMALIZED_PREFIX"
  ARGPARSE_LONG_OPTION_FIELD_SEPARATOR="${ARGPARSE_LONG_OPTION_FIELD_SEPARATOR:-=}"

  local current_option
  local current_parameter
  local current_option_prefix
  local dangling_option_string=
  while test "$#" -gt 0 || test -n "$dangling_option_string"; do
    local option_prefix_iterator=
    local option_candidate
    local is_option_found=1
    local is_option_long=1
    local is_option_short=1
    local is_parameter_merged=1
    current_option=
    current_parameter=

    # Handle leftovers of short options
    if test -n "$dangling_option_string"; then
      is_option_found=0
      is_option_short=0
      current_option="${current_option_prefix}${dangling_option_string:0:1}"
      if test "${#dangling_option_string}" -gt 1; then
        is_parameter_merged=0
        current_parameter="${dangling_option_string:1}"
      else
        current_parameter="$1"
      fi
    else
      current_option_prefix=
      option_candidate="$1"
      shift
    fi
    local parameter_candidate="$1"
    dangling_option_string=

    # Test if last loop was a short option and still contains options to unravel
    # Test for long options
    if test "$ARGPARSE_LONG_OPTION_ENABLE" -eq 0 && test "$is_option_found" -ne 0; then
      for option_prefix_iterator in "${ARGPARSE_LONG_OPTION_PREFIX[@]}"; do
        if test "$option_prefix_iterator" == "${option_candidate:0:${#option_prefix_iterator}}"; then
          is_option_found=0
          is_option_long=0
          current_option_prefix="$option_prefix_iterator"

          if test -n "$ARGPARSE_LONG_OPTION_FIELD_SEPARATOR"; then
            if test "$option_candidate" != "${option_candidate#*$ARGPARSE_LONG_OPTION_FIELD_SEPARATOR}"; then
              is_parameter_merged=0
              current_option="${option_candidate%%${ARGPARSE_LONG_OPTION_FIELD_SEPARATOR}*}"
              current_parameter="${option_candidate#*${ARGPARSE_LONG_OPTION_FIELD_SEPARATOR}}"
            fi
          fi
          if test -z "$current_option"; then
            current_option="$option_candidate"
            current_parameter="$parameter_candidate"
          fi
          break
        fi
      done
    fi
    # Test for short options
    if test "$ARGPARSE_SHORT_OPTION_ENABLE" -eq 0 && test "$is_option_found" -ne 0; then
      for option_prefix_iterator in "${ARGPARSE_SHORT_OPTION_PREFIX[@]}"; do
        if test "$option_prefix_iterator" == "${option_candidate:0:${#option_prefix_iterator}}"; then
          is_option_found=0
          is_option_short=0
          current_option_prefix="$option_prefix_iterator"

          if test "${#option_candidate}" -gt "$(( ${#current_option_prefix} + 1 ))"; then
            is_parameter_merged=0
            current_option="${option_candidate:0:$(( ${#current_option_prefix} + 1 ))}"
            current_parameter="${option_candidate:$(( ${#current_option_prefix} + 1 ))}"
          else
            current_option="$option_candidate"
            current_parameter="$parameter_candidate"
          fi
        fi
      done
    fi
    
    # No option found, set parameter
    if test "$is_option_found" -ne 0; then
      current_parameter="$option_candidate"
    fi

    # Normalize option prefix if any detected
    if test -n "$current_option"; then
      if test "$is_option_short" -eq 0; then
        if test -n "$ARGPARSE_SHORT_OPTION_NORMALIZED_PREFIX"; then
          current_option="${ARGPARSE_SHORT_OPTION_NORMALIZED_PREFIX}${current_option:${#current_option_prefix}}"
        fi
      elif test "$is_option_long" -eq 0; then
        if test -n "$ARGPARSE_LONG_OPTION_NORMALIZED_PREFIX"; then
          current_option="${ARGPARSE_LONG_OPTION_NORMALIZED_PREFIX}${current_option:${#current_option_prefix}}"
        fi
      fi
    fi
    
    "$callback_function" "$current_option" "$current_parameter" "$is_parameter_merged"
    local retval="$?"
    
    case "$retval" in
      1)
        # Only the option was consumed
        if test "$is_parameter_merged" -eq 0; then
          if test "$is_option_short" -eq 0; then
            dangling_option_string="$current_parameter"
          fi
        fi          
        ;;
      0|2)
        # Both option and parameter (or only the parameter if no option was provided) were consumed
        if test "$is_option_found" -eq 0 && test "$is_parameter_merged" -ne 0; then
          shift
        fi
        ;;
      *)
        # early abort with error code
        return "$retval"
    esac
  done
  return 0
}
