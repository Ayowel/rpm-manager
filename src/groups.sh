## @file
## @brief Extract informations from groups

## @fn help_group()
## @copydoc help()
help_group() {
  cat - <<EOH
Group commands:
  list GROUP...        List groups in an environment group
  packages GROUP...    List packages in a group

Group options:
  --package-type|-P P  Desired package classification in the group
                  One of: ${GROUP_VALID_PACKAGE_TYPES[@]}
  --group-type|-G G    Desired group classification in the group
                  One of: ${GROUP_VALID_GROUP_TYPES[@]}
                  Note: self will only match a group if it is not an environment group
EOH
}

## @fn init_group()
## @copydoc init()
init_group() {
  # Base variables
  GROUP_CURRENT_MODE=
  GROUP_PACKAGE_TYPES=( )
  GROUP_GROUP_TYPES=( )
  GROUP_TARGET_LIST=( )
  # Validation variables
  GROUP_VALID_CURRENT_MODE=( list packages )
  GROUP_VALID_PACKAGE_TYPES=( all default mandatory optional )
  GROUP_VALID_GROUP_TYPES=( all self mandatory optional )
}

## @fn parse_args_group()
## @copydoc parse_args()
parse_args_group() {
  case "$1" in
    --package-type|-P)
      local types
      IFS=' ' read -r -a types <<<"${2//,/ }"
      GROUP_PACKAGE_TYPES+=( "${types[@]}" )
      return 2
      ;;
    --group-type|-G)
      local types
      IFS=' ' read -r -a types <<<"${2//,/ }"
      GROUP_GROUP_TYPES+=( "${types[@]}" )
      return 2
      ;;
    '')
      if test -z "$GROUP_CURRENT_MODE"; then
        GROUP_CURRENT_MODE="$2"
        # Premature validation for the mode
        local mode
        for mode in "${GROUP_VALID_CURRENT_MODE[@]}"; do
          if test "$mode" == "$2"; then
            return 2
          fi
        done
        set_parse_error "Invalid group command '$mode'"
      else
        GROUP_TARGET_LIST+=( "$2" )
      fi
      return 2
      ;;
  esac
  return 0
}

## @fn post_parse_group()
## @copydoc post_parse()
post_parse_group() {
  # Set default values
  if test "${#GROUP_PACKAGE_TYPES[@]}" -eq 0; then
    GROUP_PACKAGE_TYPES=( all )
  fi
  if test "${#GROUP_GROUP_TYPES[@]}" -eq 0; then
    GROUP_GROUP_TYPES=( all )
  fi

  # Validate parameters
  if test -z "$GROUP_CURRENT_MODE"; then
    # No command selected, abort
    set_parse_error "A command must be used with group"
  fi

  local type
  for type in "${GROUP_PACKAGE_TYPES[@]}"; do
    local valid_type
    for valid_type in "${GROUP_VALID_PACKAGE_TYPES[@]}"; do
      if test "$valid_type" == "$type"; then
        continue 2
      fi
    done
    set_parse_error "Received invalid package type '$type'"
  done

  local type
  for type in "${GROUP_GROUP_TYPES[@]}"; do
    local valid_type
    for valid_type in "${GROUP_VALID_GROUP_TYPES[@]}"; do
      if test "$valid_type" == "$type"; then
        continue 2
      fi
    done
    set_parse_error "Received invalid group type '$type'"
  done
  return 0
}

## @fn main_group()
## @copydoc main()
main_group() {
  local groups=( "${GROUP_TARGET_LIST[@]}" )
  if test "${#groups[@]}" -eq 0; then
    groups=( '*' )
  fi
  case "$GROUP_CURRENT_MODE" in
    list)
      get_dnf_base_groups "$(echo -n "${GROUP_GROUP_TYPES[@]}")" "${groups[@]}"
      ;;
    packages)
      get_dnf_group_packages "$(echo -n "${GROUP_GROUP_TYPES[@]}")" "$(echo -n "${GROUP_PACKAGE_TYPES[@]}")" "${groups[@]}"
      ;;
    *)
      fatal "This can't be..."
      ;;
  esac
}

## @fn get_dnf_base_groups(expected_types, ...)
## @brief Prints the packages for the groups received as parameters
## @param expected_types A space-separated list of expected group types to print (between all, self, mandatory, and optional)
## @param ... The groups whose packages should be extracted
get_dnf_base_groups() {
  # Note: The extraction is performed by relying on dnf's output
  # Its reliability could be improved by using xmllint/xmlstarlet on cached group files instead
  local expected_types="${1:-all}"
  shift

  # Prepare awk expression string used to filter dnf's output
  local regex_filter_group_component=
  local awk_self_component=
  # shellcheck disable=SC2016
  local awk_self_component_default='/^Group:/{print substr($0,8)}'
  local type
  for type in ${expected_types}; do
    case "$type" in
      all)
        regex_filter_group_component='Mandatory|Optional'
        awk_self_component="$awk_self_component_default"
        break;
        ;;
      self) # If the group is not an environment group, print it
        awk_self_component="$awk_self_component_default"
        ;;
      mandatory|optional)
        test -n "$regex_filter_group_component" && regex_filter_group_component+='|'
        regex_filter_group_component+="${type^[m,o]}"
        ;;
      *)
        fatal "Unsupported group filter type error '$type'" >&2
        ;;
    esac
  done

  local awk_group_extractor
  # shellcheck disable=SC2016
  awk_group_extractor='/^(.[^ ]|$)/{get_groups=0} /^\s('"${regex_filter_group_component}"') Groups:/{get_groups=1} /^\s\s/{if(get_groups)print substr($0,4)} '"${awk_self_component}"
  dnf -q group info "$@" | awk -e "$awk_group_extractor" | sort | uniq
}

## @fn get_dnf_group_packages(group_type, package_type, ...)
## @brief Prints the packages for the groups received as parameters
## @param group_type A space-separated list of expected group types to print (between all, self, mandatory, and optional)
## @param package_type A space-separated list of expected package types to print (between all, default, mandatory, and optional)
## @param ... The groups whose packages should be extracted
get_dnf_group_packages() {
  # Note: The extraction is performed by relying on dnf's output
  # Its reliability could be improved by using xmllint/xmlstarlet on cached group files instead
  local group_type="${1:-all}"
  local package_type="${2:-all}"
  shift; shift

  # Prepare awk expression string used to filter dnf's output
  local regex_filter_package_component=
  local type
  for type in ${package_type}; do
    case "$type" in
      all)
        regex_filter_package_component='Default|Mandatory|Optional'
        break;
        ;;
      default|mandatory|optional)
        test -n "$regex_filter_package_component" && regex_filter_package_component+='|'
        regex_filter_package_component+="${type^[d,m,o]}"
        ;;
      *)
        fatal "Unsupported package filter type error '$type'" >&2
        ;;
    esac
  done

  local awk_package_extractor
  # shellcheck disable=SC2016
  awk_package_extractor='/^\s[^ ]/{get_packages=0} /^\s('"${regex_filter_package_component}"') Packages:/{get_packages=1} /^\s\s/{if(get_packages)print$1}'
  get_dnf_base_groups "$group_type" "$@" | xargs -d '\n' dnf -q group info | awk -e "$awk_package_extractor" | sort -n | uniq
}
