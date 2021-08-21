#!/usr/bin/env bats

setup() {
  if ! type dnf >/dev/null 2>&1; then
    skip
  fi
  tmp_paths=( )

  export LANG=C.UTF-8
  source src/dnf_commons.sh
  dnf -q makecache
}

teardown() {
  local d
  for d in "${tmp_paths[@]}"; do
    if [ -e "$d" ]; then
      rm -rf "$d"
    fi
  done
}

@test "get_repo_cache_path returns a path to a valid repository" {
  # Test an existing repository and ensure a repomd file is available
  local repo_sample
  repo_sample="$(dnf repolist -q | tail -1 | cut -d ' ' -f 1)"

  run get_repo_cache_path "$repo_sample"
  [ "${#lines[@]}" -eq 1 ]

  find "$output" -name repomd.xml

  # Test a non-existing repository
  run get_repo_cache_path "0this_repository_does_not_exist"
  [ "${#lines[@]}" -eq 0 ]
}

@test "get_repo_list returns a list of enabled repositories" {
  run get_repo_list

  echo "$output" >&2
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -ge 2 ]
  <<<"$output" grep -q baseos
}

@test "get_repo_data_data_relative_location_* helpers all resolve successfully" {
  local target_repo
  local target_repo_cache_path
  local repomd_content
  
  target_repo="$(get_repo_list | head -1)"
  target_repo_cache_path="$(get_repo_cache_path "$target_repo")"
  repomd_content="$(cat - <"${target_repo_cache_path}/repodata/repomd.xml")"

  run get_repodata_data_relative_location_awk primary <<<"$repomd_content"
  echo "$target_repo_cache_path" >&2
  echo "$output" >&2
  [ "$status" -eq 0 ]
  [ -f "${target_repo_cache_path}/${output}" ]

  run get_repodata_data_relative_location_xmllint primary <<<"$repomd_content"
  echo "$target_repo_cache_path" >&2
  echo "$output" >&2
  [ "$status" -eq 0 ]
  [ -f "${target_repo_cache_path}/${output}" ]
}

@test "get_repo_data_data_relative_location swap helpers as configured" {
  local target_repo
  local target_repo_cache_path
  local repomd_content
  
  target_repo="$(get_repo_list | head -1)"
  target_repo_cache_path="$(get_repo_cache_path "$target_repo")"
  repomd_content="$(cat - <"${target_repo_cache_path}/repodata/repomd.xml")"

  run get_repodata_data_relative_location primary <<<"$repomd_content"
  echo "$target_repo_cache_path" >&2
  echo "$output" >&2
  [ "$status" -eq 0 ]
  [ -f "${target_repo_cache_path}/${output}" ]

  # Run with awk for coverage
  USE_AWK=0 run get_repodata_data_relative_location primary <<<"$repomd_content"
  echo "$target_repo_cache_path" >&2
  echo "$output" >&2
  [ "$status" -eq 0 ]
  [ -f "${target_repo_cache_path}/${output}" ]
}
