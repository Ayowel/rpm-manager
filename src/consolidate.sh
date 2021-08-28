## @file
## @brief Gather repositories metadata as a single file

## @fn help_consolidate()
## @copydoc help()
help_consolidate() {
  cat - <<EOH
Consolidate commands:
  group GROUP_FILE...      Consolidate a list of source group files
  module MODULE_FILE...    Consolidate a list of source module files
  gpgkey KEY_FILE...       Consolidate a list of gpg key files

Consolidate options:
  --output|-o O   Where the consolidated date should be written
                    (Defaults to the standard output)
  --source S      Path to a source file or directory. May be used more than once
                    If not provided, defaults to the current directory

EOH
}

## @fn init_consolidate()
## @copydoc init()
init_consolidate() {
  # Base variables
  CONSOLIDATE_TARGET_TYPE=
  CONSOLIDATE_SOURCE_PATHS=( )
  CONSOLIDATE_OUTPUT_PATH=
  CONSOLIDATE_SOURCE_PATHS_VALIDATED=( )
  # Validation variables
  CONSOLIDATE_VALID_TARGET_TYPE=( group module gpgkey )
}

## @fn parse_args_consolidate()
## @copydoc parse_args()
parse_args_consolidate() {
  case "$1" in
    --output|-o)
      CONSOLIDATE_OUTPUT_PATH="$2"
      return 2
      ;;
    --source)
      CONSOLIDATE_SOURCE_PATHS+=( "$2" )
      return 2
      ;;
    '')
      if test -z "$CONSOLIDATE_TARGET_TYPE"; then
        CONSOLIDATE_TARGET_TYPE="$2"
        # Premature validation for the mode
        local mode
        for mode in "${CONSOLIDATE_VALID_TARGET_TYPE[@]}"; do
          if test "$mode" == "$2"; then
            return 2
          fi
        done
        set_parse_error "Invalid consolidation type '$mode'"
      else
        CONSOLIDATE_SOURCE_PATHS+=( "$2" )
      fi
      return 2
      ;;
  esac
  return 0
}

## @fn post_parse_consolidate()
## @copydoc post_parse()
post_parse_consolidate() {
  # Set default values
  CONSOLIDATE_OUTPUT_PATH="${CONSOLIDATE_OUTPUT_PATH:--}"
  if test "${#CONSOLIDATE_SOURCE_PATHS[@]}" -eq 0; then
    echo "WARN: No consolidation source paths provided, current directory will be searched for candidates"
    CONSOLIDATE_SOURCE_PATHS=( . )
  fi

  local file_search_keys=( )
  case "$CONSOLIDATE_TARGET_TYPE" in
    group)
      file_search_keys=( -name '*.xml' )
      ;;
    module)
      file_search_keys=( -name '*.yaml' )
      ;;
    gpgkey)
      file_search_keys=( -name 'gpgkey*' -o -name 'RPM-GPG-KEY-*' )
      ;;
    # This should be guarded by the check in parse_args
    *) set_parse_error "Unsupported consolidation type $CONSOLIDATE_TARGET_TYPE. This should not happen"; return 1 ;;
  esac

  local path
  while read -rd '' path; do
    CONSOLIDATE_SOURCE_PATHS_VALIDATED+=( "$path" )
    test "$VERBOSE" -eq 0 && echo "USING $path"
  done \
  < <(
    find -L "${CONSOLIDATE_SOURCE_PATHS[@]}" -maxdepth 0 -type f -readable -print0
    find -L "${CONSOLIDATE_SOURCE_PATHS[@]}" -mindepth 1 -type f -readable "${file_search_keys[@]}" -print0
  )
  if test "${#CONSOLIDATE_SOURCE_PATHS_VALIDATED[@]}" -eq 0; then
    set_parse_error 'No valid consolidation source file found'
  fi
}

## @fn main_consolidate()
## @copydoc main()
main_consolidate() {
  if test -n "$CONSOLIDATE_OUTPUT_PATH" && test "$CONSOLIDATE_OUTPUT_PATH" != '-'; then
    exec 3>"$CONSOLIDATE_OUTPUT_PATH"
  else
    exec 3>&1
  fi
  case "$CONSOLIDATE_TARGET_TYPE" in
    group)
      consolidate_groups "${CONSOLIDATE_SOURCE_PATHS_VALIDATED[@]}" >&3
      ;;
    module)
      consolidate_modules "${CONSOLIDATE_SOURCE_PATHS_VALIDATED[@]}" >&3
      ;;
    gpgkey)
      consolidate_gpgkeys "${CONSOLIDATE_SOURCE_PATHS_VALIDATED[@]}" >&3
      ;;
    # This should be guarded by the check in parse_args
    *) return 1 ;;
  esac
  exec 3>&-
}

## @fn consolidate_modules()
## @brief Prints a consolidated version of all target module files
## @param ... Paths to module files or directories containing .yaml module files
## @return $> The consolidated module file
consolidate_modules() {
  # We use `awk 1` here to guarantee that a newline will be added at the end of each module file
  # Errors may occur after concatenating some module files if this is not done
  find "$@" -type f -name '*.yaml' -print0 | xargs -r0 awk 1
}

## @fn consolidate_gpgkeys()
## @brief Prints a consolidated version of all target key files
## @param ... Paths to key files or directories containing only key files
## @return $> The consolidated key file
consolidate_gpgkeys() {
  # We use `awk 1` here to guarantee that a newline will be added at the end of each module file
  # Errors may occur after concatenating some module files if this is not done
  find "$@" -type f -print0 | xargs -r0 awk 1
}

## @fn consolidate_groups_filter_xmllint()
## @copydoc consolidate_groups_filter()
## @see consolidate_groups_filter
consolidate_groups_filter_xmllint() {
  find "$@" -type f -name '*.xml' -print0 | xargs -r0 xmllint --xpath '//comps/*' "$@"
}

## @fn consolidate_groups_filter_awk()
## @copydoc consolidate_groups_filter()
## @see consolidate_groups_filter
consolidate_groups_filter_awk() {
  local targets='group|category|environment'
  local validator
  # shellcheck disable=SC2016
  validator="$( printf "%s%s%s%s%s" 'BEGIN{d=0} /<(' "$targets" ')>/{d+=1} /<\/(' "$targets" ')>/{d-=1;if(d==0)print$0} {if(d>0)print$0}' )"
  find "$@" -type f -name '*.xml' -print0 | xargs -r0 awk -e "$validator" --
}

## @fn consolidate_groups_filter()
## @brief Utility function for #consolidate_groups
## @param ... Paths to group files or directories containing .xml group files
## @return $> The concatenated group files
## @see consolidate_groups
## @private
consolidate_groups_filter() {
  local used_filter
  
  # If xmllint is available on the system, use the more reliable function
  if test "${USE_XMLLINT:-1}" -eq 0 || { test "${USE_AWK:-1}" -ne 0 && type xmllint >/dev/null 2>&1; }; then
    used_filter=consolidate_groups_filter_xmllint
  else
    used_filter=consolidate_groups_filter_awk
  fi
  
  "$used_filter" "$@"
}

## @fn consolidate_groups()
## @brief Prints a consolidated version of all target group files
## @param ... Paths to group files or directories containing .xml group files
## @return $> The consolidated group file
consolidate_groups() {
  {
    # Build a group file by extracting the content of 'comps' from each group file considered
    cat - <<SOG
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE comps PUBLIC "-//Red Hat, Inc.//DTD Comps info//EN" "comps.dtd">
<comps>
SOG
    consolidate_groups_filter "$@"
    cat - <<EOG
</comps>
EOG
  }
}
