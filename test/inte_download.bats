#!/usr/bin/env bats

setup() {
  if ! type dnf >/dev/null 2>&1; then
    skip
  fi

  manager="${MANAGER:-bash ./main.sh}"
  tmp_paths=( "$(mktemp -d)" )
  target_dir="${tmp_paths[0]}"

  default_config=( -R "$target_dir" --no-modules --no-gpgkeys --no-groups --no-rpms --no-resolve )
}

teardown() {
  for p in "${tmp_paths[@]}"; do
    if [ -e "$p" ]; then
      rm -rf "$p"
    fi
  done
}

# Check that only specified files were downloaded and that they are not empty
test_exclusive_download_check() {
  local base_dir="$1"
  local expected_file_pattern="$2"

  # Validate generated files
  local find_output_string
  local found_files
  local matching_files
  find_output_string="$(find "$base_dir" -mindepth 1 -type f)"
  read -ra found_files <<<"$find_output_string"
  matching_files="$(grep -E "$expected_file_pattern" <<<"$find_output_string")"

  [ "${#found_files[@]}" -gt 0 ]
  [ "$find_output_string" = "$matching_files" ]
  # no file should be created if there is nothing to put inside
  for f in "${found_files[@]}"; do
    [ -s "$f" ]
  done

}
@test "download - Disabling all download options and not keeping the generated package list returns an error" {
  run $manager download "${default_config[@]}"
  [ "$status" -ne 0 ]
}


@test "download - Downloading gpg keys works" {
  run $manager download "${default_config[@]}" --gpgkeys --repo-subdirectory . --gpg-subfile "gpgkey_%{REPO}"
  [ "$status" -eq 0 ]

  test_exclusive_download_check "$target_dir" '/gpgkey_[^/]*$'

  # Options make it so that there should be no subdirectory
  local dir_count
  dir_count="$(find "$target_dir" -mindepth 1 ! -type f | wc -l)"
  [ "$dir_count" -eq 0 ]
}

@test "download - Downloading module files works" {
  run $manager download "${default_config[@]}" --modules --repo-subdirectory . --module-subfile "module_%{REPO}.yaml"
  [ "$status" -eq 0 ]

  test_exclusive_download_check "$target_dir" '/module_[^/]*\.yaml$'

  # Options make it so that there should be no subdirectory
  local dir_count
  dir_count="$(find "$target_dir" -mindepth 1 ! -type f | wc -l)"
  [ "$dir_count" -eq 0 ]
}

@test "download - Downloading group files works" {
  run $manager download "${default_config[@]}" --groups --repo-subdirectory . --group-subfile "comps_%{REPO}.xml"
  [ "$status" -eq 0 ]

  test_exclusive_download_check "$target_dir" '/comps_[^/]*\.xml$'

  # Options make it so that there should be no subdirectory
  local dir_count
  dir_count="$(find "$target_dir" -mindepth 1 ! -type f | wc -l)"
  [ "$dir_count" -eq 0 ]
}

@test "download - Downloading a single RPM with resolve disabled should only download one rpm file" {
  run $manager download "${default_config[@]}" --rpms . --repo-subdirectory . --rpm-subdirectory . --package bash
  [ "$status" -eq 0 ]

  test_exclusive_download_check "$target_dir" '/[^/]*\.rpm$'

  # We should only have downloaded one matching RPM
  local rpm_count
  rpm_count="$(find "$target_dir" -mindepth 1 -type f | wc -l)"
  [ "$rpm_count" -eq 1 ]

  # Options make it so that there should be no subdirectory
  local dir_count
  dir_count="$(find "$target_dir" -mindepth 1 ! -type f | wc -l)"
  [ "$dir_count" -eq 0 ]
}

@test "download - Downloading RPM files from a list in a file should work" {
  run $manager download "${default_config[@]}" --rpms . --repo-subdirectory . --rpm-subdirectory . --package-file <(cat - <<EOF
git  httpd
telnet gawk # bash
sed
EOF
  )
  [ "$status" -eq 0 ]

  test_exclusive_download_check "$target_dir" '/[^/]*\.rpm$'

  # We should have downloaded all RPMs taht are not commented-out
  local rpm_count
  rpm_count="$(find "$target_dir" -mindepth 1 -type f | wc -l)"
  find "$target_dir" -mindepth 1 -type f
  [ "$rpm_count" -eq 5 ]
}

@test "download - Generating a list of target RPMs should be supported" {
  local resolved_items

  run $manager download "${default_config[@]}" --repo-subdirectory . -k --resolved-rpms-file "${target_dir}/rpm_list" git telnet
  [ "$status" -eq 0 ]
  resolved_items="$(wc -l <"${target_dir}/rpm_list")"
  [ "$resolved_items" -eq 2 ]

  run $manager download "${default_config[@]}" --repo-subdirectory . --resolve -k --resolved-rpms-file "${target_dir}/rpm_list" git telnet
  [ "$status" -eq 0 ]
  resolved_items="$(wc -l <"${target_dir}/rpm_list")"
  [ "$resolved_items" -gt 2 ]
}

@test "download - Downloading RPMs with resolve enabled should download all required rpm files" {
  run $manager download "${default_config[@]}" --rpms . --repo-subdirectory . --rpm-subdirectory . --package bash --resolve
  [ "$status" -eq 0 ]

  test_exclusive_download_check "$target_dir" '/[^/]*\.rpm$'

  # We should have downloaded one RPM
  # If more than one is found, assume we have them all
  local rpm_count
  rpm_count="$(find "$target_dir" -mindepth 1 -type f | wc -l)"
  [ "$rpm_count" -gt 1 ]
}
