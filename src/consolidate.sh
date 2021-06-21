## @file
## @brief Gather repositories metadata as a single file

init_consolidate() {
  return 0
}

## @fn consolidate_modules(...)
## @brief Prints a consolidated version of all target module files
## @param ... Paths to module files or directories containing .yaml module files
## @return $> The consolidated module file
consolidate_modules() {
  # We use `awk 1` here to guarantee that a newline will be added at the end of each module file
  # Errors may occur after concatenating some module files if this is not done
  find "$@" -type f -name '*.yaml' -print0 | xargs -r0 awk 1 --
}

## @fn consolidate_groups_filter_xmllint(...)
## @brief Utility function for #consolidate_groups
## @param ... Paths to group files or directories containing .xml group files
## @return $> The concatenated group files
## @see consolidate_groups_filter
## @private
consolidate_groups_filter_xmllint() {
  find "$@" -type f -name '*.xml' -print0 | xargs -r0 xmllint --xpath '//comps/*' "$@"
}

## @fn consolidate_groups_filter_awk(...)
## @brief Utility function for #consolidate_groups
## @param ... Paths to group files or directories containing .xml group files
## @return $> The concatenated group files
## @see consolidate_groups_filter
## @private
consolidate_groups_filter_awk() {
  local targets='group|category|environment'
  local validator
  # shellcheck disable=SC2016
  validator="$( printf "%s%s%s%s%s" 'BEGIN{d=0} /<(' "$targets" ')>/{d+=1} /<\/(' "$targets" ')>/{d-=1;if(d==0)print$0} {if(d>0)print$0}' )"
  find "$@" -type f -name '*.xml' -print0 | xargs -r0 awk -e "$validator" --
}

## @fn consolidate_groups_filter(...)
## @brief Utility function for #consolidate_groups
## @param ... Paths to group files or directories containing .xml group files
## @return $> The concatenated group files
## @see consolidate_groups
## @private
consolidate_groups_filter() {
  local used_filter
  
  # If xmllint is available on the system, use the more reliable function
  if type xmllint >/dev/null 2>&1; then
    used_filter=consolidate_groups_filter_xmllint
  else
    used_filter=consolidate_groups_filter_awk
  fi
  
  "$used_filter" "$@"
}

## @fn consolidate_groups(...)
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
