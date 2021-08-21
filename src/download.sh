## @file
## @brief Manage repositories data download interactions

## @fn help_download()
## @copydoc help()
help_download() {
  cat - <<EOH
Download options:
  --package      Name of a package to download
  --package-file FILE
                 Path to a file containing a list of desired packages
  --group        Name of a group whose packages should be downloaded
  --history NUM  How many versions of a package should be downloaded if more
                   than one is available (defaults to 1)
  --[no-](modules|gpgkeys|groups|rpms)
                 Whether a specific repository data type should be loaded or
                   not (defaults to true)
  --[no-]resolve Whether RPM dependencies should be resolved or ignored
  --download-repos REPOS
                 Comma/space-separated list of repositories to download
                   packages from (resolution is always against all enabled
                   repositories)
  --repo-subdirectory REPO_DIR
                 Path to move to when downloading data of a repository
                   (defaults to the repository's name) 
  --rpm-subdirectory DIR
                 Directory where downloaded RPMs should be stored (from REPO_DIR)
  --(gpg|module|group)-subfile FILE
                 Filepath to store the corresponding repository data to
		   (from the repository's directory)
  --resolved-rpms-file FILE
                 Where the list of resolved RPMs versions should be stored
  -k|--keep      Keep resolve RPMs dependencies file

EOH
}

## @fn init_download()
## @copydoc init()
init_download() {
  DOWNLOAD_MODULES=0
  DOWNLOAD_GPGKEYS=0
  DOWNLOAD_GROUPS=0
  DOWNLOAD_RESOLVE=0
  DOWNLOAD_RPMS=0
  
  DOWNLOAD_INTERMEDIATE_RESOLUTION_FILE=
  DOWNLOAD_KEEP_INTERMEDIATE_RESOLUTION_FILE=1

  DOWNLOAD_REPOS=( )
  DOWNLOAD_REPO_SUBDIRECTORY_DEFAULT="%{REPO}"
  DOWNLOAD_REPO_SUBDIRECTORY=
  DOWNLOAD_RPM_SUBDIRECTORY_DEFAULT="rpms"
  DOWNLOAD_RPM_SUBDIRECTORY=
  DOWNLOAD_MODULES_FILE_DEFAULT="modules.yaml"
  DOWNLOAD_MODULES_FILE=
  DOWNLOAD_GPG_FILE_DEFAULT='gpgkey'
  DOWNLOAD_GPG_FILE=
  DOWNLOAD_GROUPS_FILE_DEFAULT="comps.xml"
  DOWNLOAD_GROUPS_FILE=
  DOWNLOAD_OLD_VERSION_LIMIT=1
  
  DOWNLOAD_PACKAGE_LIST_FILES=( )
  DOWNLOAD_PACKAGE_LIST=( )
  DOWNLOAD_GROUP_LIST=( )
}

## @fn parse_args_download()
## @copydoc parse_args()
parse_args_download() {
  case "$1" in
    --modules)
      DOWNLOAD_MODULES=0
      return 1
      ;;
    --no-modules)
      DOWNLOAD_MODULES=1
      return 1
      ;;
    --gpgkeys)
      DOWNLOAD_GPGKEYS=0
      return 1
      ;;
    --no-gpgkeys)
      DOWNLOAD_GPGKEYS=1
      return 1
      ;;
    --groups)
      DOWNLOAD_GROUPS=0
      return 1
      ;;
    --no-groups)
      DOWNLOAD_GROUPS=1
      return 1
      ;;
    --resolve)
      DOWNLOAD_RESOLVE=0
      return 1
      ;;
    --no-resolve)
      DOWNLOAD_RESOLVE=1
      return 1
      ;;
    --rpms)
      DOWNLOAD_RPMS=0
      return 1
      ;;
    --no-rpms)
      DOWNLOAD_RPMS=1
      return 1
      ;;
    --download-repos)
      local download_repo_buffer
      IFS=' ' read -r -a download_repo_buffer <<<"${2//,/ }"
      DOWNLOAD_REPOS+=( "${download_repo_buffer[@]}" )
      return 2
      ;;
    --repo-subdirectory)
      DOWNLOAD_REPO_SUBDIRECTORY="${2:-.}"
      return 2
      ;;
    --rpm-subdirectory)
      DOWNLOAD_RPM_SUBDIRECTORY="${2:-.}"
      return 2
      ;;
    --gpg-subfile)
      DOWNLOAD_GPG_FILE="${2:-DOWNLOAD_GPG_FILE_DEFAULT}"
      return 2
      ;;
    --module-subfile)
      DOWNLOAD_MODULES_FILE="${2:-DOWNLOAD_MODULES_FILE_DEFAULT}"
      return 2
      ;;
    --group-subfile)
      DOWNLOAD_GROUPS_FILE="${2:-DOWNLOAD_GROUPS_FILE_DEFAULT}"
      return 2
      ;;
    -k|--keep)
      DOWNLOAD_KEEP_INTERMEDIATE_RESOLUTION_FILE=0
      return 1
      ;;
    --resolved-rpms-file)
      DOWNLOAD_INTERMEDIATE_RESOLUTION_FILE="$2"
      return 2
      ;;
    --package-file)
      DOWNLOAD_PACKAGE_LIST_FILES+=( "$2" )
      return 2
      ;;
    --package)
      DOWNLOAD_PACKAGE_LIST+=( "$2" )
      return 2
      ;;
    --group)
      DOWNLOAD_GROUP_LIST+=( "$2" )
      return 2
      ;;
    --history)
      DOWNLOAD_OLD_VERSION_LIMIT="$2"
      return 2
      ;;
  esac
  if test -z "$1" && test -n "$2"; then
    DOWNLOAD_PACKAGE_LIST+=( "$2" )
    return 2
  fi
  return 0
}

## @fn post_parse_download()
## @copydoc post_parse()
post_parse_download() {
  DOWNLOAD_RPM_SUBDIRECTORY="${DOWNLOAD_RPM_SUBDIRECTORY:-${DOWNLOAD_RPM_SUBDIRECTORY_DEFAULT}}"
  DOWNLOAD_REPO_SUBDIRECTORY="${DOWNLOAD_REPO_SUBDIRECTORY:-${DOWNLOAD_REPO_SUBDIRECTORY_DEFAULT}}"
  DOWNLOAD_MODULES_FILE="${DOWNLOAD_MODULES_FILE:-$DOWNLOAD_MODULES_FILE_DEFAULT}"
  DOWNLOAD_GROUPS_FILE="${DOWNLOAD_GROUPS_FILE:-$DOWNLOAD_GROUPS_FILE_DEFAULT}"
  DOWNLOAD_GPG_FILE="${DOWNLOAD_GPG_FILE:-$DOWNLOAD_GPG_FILE_DEFAULT}"

  if ! test "$DOWNLOAD_OLD_VERSION_LIMIT" -gt 0; then
    set_parse_error "The old version limit must be a positive number (received ${DOWNLOAD_OLD_VERSION_LIMIT})"
  fi

  local f
  local packages
  for f in "${DOWNLOAD_PACKAGE_LIST_FILES[@]}"; do
    read -ra packages <"$f"
    DOWNLOAD_PACKAGE_LIST+=( "${packages[@]}" )
  done
  # Ensure that we're going to keep an output data or raise error
  for var in DOWNLOAD_RPMS DOWNLOAD_MODULES DOWNLOAD_GROUPS DOWNLOAD_GPGKEYS DOWNLOAD_KEEP_INTERMEDIATE_RESOLUTION_FILE; do
    if test "${!var}" -eq 0; then
      return
    fi
  done
  set_parse_error "Attempting to use the download command but all valid command targets are disabled"
}

## @fn main_download()
## @copydoc main()
main_download() {
  local repolist
  local tmp_file

  repolist=( "${DOWNLOAD_REPOS[@]}" )
  if test "${#repolist[@]}" -eq 0; then
    echo "Listing locally enabled repositories"
    read -r -d '\n' -a repolist <<<"$(get_repo_list)"
  fi

  # Build the list of RPMs we want to download (if any)
  if test "$DOWNLOAD_RPMS" -eq 0 || test "$DOWNLOAD_KEEP_INTERMEDIATE_RESOLUTION_FILE" -eq 0; then
    tmp_file="$(realpath "${DOWNLOAD_INTERMEDIATE_RESOLUTION_FILE:-$(TMPDIR=. mktemp --suffix .downloader)}")"
    echo "Building Packages list into $tmp_file"
    # Print all desired packages in this section so that they are used in the parsed command
    {
      if test "${#DOWNLOAD_PACKAGE_LIST_FILES[@]}" -eq 0 && test "${#DOWNLOAD_PACKAGE_LIST[@]}" -eq 0 && test "${#DOWNLOAD_GROUP_LIST[@]}" -eq 0; then
        # If no package or group was configured, get all available rpms
        echo '*'
      else
        if test "${#DOWNLOAD_PACKAGE_LIST[@]}" -ne 0; then
          printf "%s\n" "${DOWNLOAD_PACKAGE_LIST[@]}"
        fi
        if test "${#DOWNLOAD_GROUP_LIST[@]}" -ne 0; then
          get_dnf_group_packages all all "${DOWNLOAD_GROUP_LIST[@]}"
        fi
      fi
    } | get_packages_list "$DOWNLOAD_RESOLVE" >"$tmp_file"
  fi

  for repo in "${repolist[@]}"; do
    local repo_path
    repo_path="${DOWNLOAD_REPO_SUBDIRECTORY//%\{REPO\}/$repo}"
    test -d "$repo_path" || mkdir -p "$repo_path"
    echo "Download packages for repository ${repo}"
    pushd "$repo_path" >/dev/null || continue
    {
      if test "$DOWNLOAD_RPMS" -eq 0; then
        local rpm_dir
        rpm_dir="${DOWNLOAD_RPM_SUBDIRECTORY//%\{REPO\}/$repo}"
        test -d "$rpm_dir" || mkdir -p "$rpm_dir"
        echo "Start download for repo $repo"
        download_rpms "$rpm_dir" "$repo" <"$tmp_file"
      fi

      if test "$DOWNLOAD_MODULES" -eq 0; then
        local module_path
        local module_dir
        module_path="${DOWNLOAD_MODULES_FILE//%\{REPO\}/$repo}"
        module_dir="$(dirname "$module_path")"
        test -d "$module_dir" || mkdir -p "$module_dir"
        local repo_module_content
        if repo_module_content="$(get_repo_modules "$repo")"; then
          cat - <<<"$repo_module_content" > "$module_path"
        fi
      fi

      if test "$DOWNLOAD_GROUPS" -eq 0; then
        local group_path
        local group_dir
        group_path="${DOWNLOAD_GROUPS_FILE//%\{REPO\}/$repo}"
        group_dir="$(dirname "$group_path")"
        test -d "$group_dir" || mkdir -p "$group_dir"
        local repo_group_content
        if repo_group_content="$(get_repo_groups "$repo")"; then
          cat - <<<"$repo_group_content" > "$group_path"
        fi
      fi

      if test "$DOWNLOAD_GPGKEYS" -eq 0; then
      local key_dir
      local gpg_path="${DOWNLOAD_GPG_FILE//%\{REPO\}/$repo}"
      key_dir="$(dirname "$gpg_path")"
      test -d "$key_dir" || mkdir -p "$key_dir"
      local gpg_keys
      if gpg_keys="$(get_gpg_keys "$repo")"; then
        cat - <<<"$gpg_keys" >"$gpg_path"
      fi
      fi
    }
    popd >/dev/null || fatal "Failed to move out of $(pwd)" 3
  done

  if test "$DOWNLOAD_KEEP_INTERMEDIATE_RESOLUTION_FILE" -ne 0 && { test "$DOWNLOAD_RPMS" -eq 0 || test "$DOWNLOAD_RESOLVE" -eq 0; }; then 
    rm -f "$tmp_file"
  fi
}

## @fn get_packages_list(resolve)
## @brief Prints the resolved names of packages and their dependencies
## @param resolve Whether packages dependencies should be resolved (0) or not
## @note < A list of packages to resolve
## @return > A list of resolved packages and dependencies
get_packages_list() {
  local resolve="${1:-1}"
  local package_list
  package_list="$(xargs -r dnf -q repoquery --latest-limit 1 --)"

  {
    cat - <<<"$package_list"
    if test "$resolve" -eq 0; then
      cat - <<<"$package_list" | xargs -r dnf -q repoquery --requires --resolve --recursive --
    fi
  } | sort -n | uniq
}

## @fn get_repo_list()
## @brief Prints a list of enabled repositories on the system
## @return > A list of enabled repositories
get_repo_list() {
  # Use awk to drop the header line and only print repo names
  dnf -q repolist | awk -e '{if(NR>1)print$1}'
}

## @fn get_gpg_keys(repo_name)
## @brief Print all GPG keys of a repository
## @return > The GPG keys of therepository as well as their comments
get_gpg_keys() {
  local repo_name="$1"

  local repo_file
  local gpg_keys
  repo_file="$(dnf repolist -qv | awk '/^Repo-id/{if($3=="'"${repo_name}"'")a=1;else a=0} /^Repo-filename/{if(a)print$3}')"
  read -ra gpg_keys < <(
    # shellcheck disable=SC2016
    local awk_parameters=(
      -e '/\s*\[.*\]/{a=0} /\s*\['"${repo_name}"'\]/{a=1}' # Search for the target repository's section
      -e '/gpgkey\s*=/{if(a)b=1}'                          # Set flag if at gpgkey attribute's line
      -e '{if(a && b)print $0}'                            # Print-out line content if on gpgkey
      -e '{if(substr($0,length($0),1) != "\\")b=0}'        # Disable gpgkey flag unless line ends with '\'
      "$repo_file"
    )
    # Replace undesired values with spaces for proper array items detection
    awk "${awk_parameters[@]}" | sed -e 's/^gpgkey\s*=\|[,\\\r\n]/ /g'
  )

  if test "${#gpg_keys[@]}" -eq 0; then
    return 1
  else
    local key_path
    for key_path in "${gpg_keys[@]}"; do
      # Filter-out '\'
      if [ "${#key_path}" -gt 2 ]; then
        print_resource_by_path "$key_path"
        echo
      fi
    done
    return 0
  fi
}

## @fn download_rpms()
## @brief Downloads the packages received as an input stream from the repositories received as parameters
## @param destination Directory where RPMs should bs saved (defaults to .)
## @param ... The repositories to download from (all if not provided)
## @note $< A list of packages to download (one per line)
download_rpms() {
  local destdir="${1:-.}"
  shift
  local additionnal_parameters=()
  if test "$#" -gt 0; then
    for repo in "$@"; do
	  additionnal_parameters+=( --repo "$repo" )
	done
  fi
realpath "$destdir"
  xargs -r dnf -q download --destdir "$destdir" -y  "${additionnal_parameters[@]}" --skip-broken -- 2>/dev/null
}

## @fn get_repo_modules(repo_name)
## @brief Prints a repository's module information after loading it from cache
## @param repo_name The name of the repository whose modules should be extracted from cache
## @return
##   $> The module's content
##   $>&2 Any invalid module file found (most likely to be due to an internal error)
##   0 if a module file was found, else 1
get_repo_modules() {
  local repo_name="$1"
  local repo_path
  repo_path="$(get_repo_cache_path "$repo_name")"
  local module_paths=()

  IFS=' ' read -r -a module_paths <<<"$(get_repodata_data_relative_location modules <"${repo_path}/repodata/repomd.xml")"

  local module_file
  for module_file in "${module_paths[@]}"; do
    if print_unpacked_file_content "${repo_path}/${module_file}" '\.xml$'; then
      return 0
    fi
  done
  return 1
}

## @fn get_repodata_data_relative_location_awk()
## @copydoc get_repodata_data_relative_location()
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

## @fn get_repodata_data_relative_location_xmllint()
## @copydoc get_repodata_data_relative_location()
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

## @fn get_repodata_data_relative_location()
## @brief Extract the location of a repodata file
## @param types... Repodata attributes whose locations should be extracted
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

## @fn get_repo_groups()
## @brief Prints a repository's group information after loading it from cache
## @param repo_name The name of the repository whose groups should be extracted from cache
## @return
##   * $> The groups' informations
##   * $>&2 Any invalid group file found (most likely to be due to an internal error)
##   * 0 If a group file was found, else 1
get_repo_groups() {
  local repo_name="$1"
  local repo_path
  repo_path="$(get_repo_cache_path "$repo_name")"
  local group_paths=

  group_paths="$(get_repodata_data_relative_location group group_gz <"${repo_path}/repodata/repomd.xml")"

  local group_file
  for group_file in $group_paths; do # We want the 'in' part to split on spaces
    # Ensure that we appropriatly handle the file found
    if print_unpacked_file_content "${repo_path}/${group_file}" '\.xml$'; then
      return 0
    fi
  done
  return 1
}
