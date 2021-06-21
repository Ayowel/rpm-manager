## @file
## @brief Extract informations from groups

main_groups() {
  get_dnf_group_packages all "$@"
}

init_groups() {
  return 0
}

## @fn get_base_groups(expected_types, ...)
## @brief Prints the packages for the groups received as parameters
## @param expected_types A comma- or space-separated list of expected group types to print (between all, self, mandatory, and optional)
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
  for type in ${expected_types//,/ }; do
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
        echo "Unsupported group filter type error '$type'" >&2
        return 1
        ;;
    esac
  done

  local awk_group_extractor
  # shellcheck disable=SC2016
  awk_group_extractor='/^(.[^ ]|$)/{get_groups=0} /^\s('"${regex_filter_group_component}"') Groups:/{get_groups=1} /^\s\s/{if(get_groups)print substr($0,4)} '"${awk_self_component}"
  dnf -q group info "$@" | awk -e "$awk_group_extractor" | sort | uniq
}

## @fn get_group_packages(expected_types, ...)
## @brief Prints the packages for the groups received as parameters
## @param expected_types A comma- or space-separated list of expected package types to print (between all, default, mandatory, and optional)
## @param ... The groups whose packages should be extracted
get_dnf_group_packages() {
  # Note: The extraction is performed by relying on dnf's output
  # Its reliability could be improved by using xmllint/xmlstarlet on cached group files instead
  local expected_types="${1:-all}"
  shift

  # Prepare awk expression string used to filter dnf's output
  local regex_filter_package_component=
  local type
  for type in ${expected_types//,/ }; do
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
        echo "Unsupported package filter type error '$type'" >&2
        return 1
        ;;
    esac
  done

  local awk_package_extractor
  # shellcheck disable=SC2016
  awk_package_extractor='/^\s[^ ]/{get_packages=0} /^\s('"${regex_filter_package_component}"') Packages:/{get_packages=1} /^\s\s/{if(get_packages)print$1}'
  get_dnf_base_groups all "$@" | xargs -d '\n' dnf -q group info | awk -e "$awk_package_extractor" | sort -n | uniq
}
