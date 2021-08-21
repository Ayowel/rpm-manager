## @file
## @brief Simple utility functions used in other scripts

## @fn get_repo_cache_path(repo_name)
## @brief Returns the path to the local metadata folder for a repository
## @param repo_name Name of the repository whose cache path should be discovered
get_repo_cache_path() {
  local repo_name="$1"

  # Use 16 '?' as placeholder for the generated hash
  # TODO: find out how the hash is generated and generate it internally for deterministic resolution
  find "/var/tmp/dnf-$(whoami)-"???????? /var/cache/dnf -mindepth 1 -maxdepth 1 -type d -name "${repo_name}-????????????????" ! -name "${repo_name}-*-*" 2>/dev/null | head -1
}

## @fn get_repo_list()
## @brief Prints a list of enabled repositories on the system
## @return > A list of enabled repositories
get_repo_list() {
  # Use awk to drop the header line and only print repo names
  dnf -q repolist | awk -e '{if(NR>1)print$1}'
}

## @fn get_repodata_data_relative_location(types)
## @brief Extract the location of a repodata file
## @param types Repodata attributes whose locations should be extracted
## @note
##   * $< The input file's content
##   * $> The extracted locations
get_repodata_data_relative_location() {
  local used_filter

  # If xmllint is available on the system, use it
  if test "${USE_XMLLINT:-1}" -eq 0 || { test "${USE_AWK:-1}" -ne 0 && type xmllint >/dev/null 2>&1; }; then
    used_filter=get_repodata_data_relative_location_xmllint
  else
    used_filter=get_repodata_data_relative_location_awk
  fi

  "$used_filter" "$@"
}

## @fn get_repodata_data_relative_location_awk(types)
## @copydoc get_repodata_data_relative_location(types)
## @see get_repodata_data_relative_location()
## @private
get_repodata_data_relative_location_awk() {
  local target_types="$1"
  while test "$#" -gt 1; do
    shift
    target_types+="|${1}"
  done
  # shellcheck disable=SC2016
  local group_search_awk_exp='/<data type="'"${target_types}"'">/{module=1} /<location/{if(module==1){print$2;module=0}}'
  awk -F \" -e "$group_search_awk_exp"
}

## @fn get_repodata_data_relative_location_xmllint(types)
## @copydoc get_repodata_data_relative_location(types)
## @see get_repodata_data_relative_location()
## @private
get_repodata_data_relative_location_xmllint() {
  # Drop namespaces from input files
  local repomd_content
  repomd_content="$(sed -Ee 's/\sxmlns(:[^=]*)?="[^"]*"//g')"
  for target_item in "$@"; do
    <<<"$repomd_content" xmllint --xpath "string(/repomd/data[@type=\"${target_item}\"]/location/@href)" -
    # Add newline after match
    echo
  done
}
