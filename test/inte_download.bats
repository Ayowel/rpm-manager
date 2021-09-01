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

  if ! type gpg >/dev/null 2>&1; then
    skip
  fi

  # Ensure that all generated files contain GPG keys
  local key_file
  local key_file_list
  key_file_list=( $(find "$target_dir" -type f -name 'gpgkey_*' -print) )
  [ "${#key_file_list[@]}" -gt 0 ]
  for key_file in "${key_file_list[@]}"; do
    echo "$key_file"
    LANG=C.utf-8 run gpg --no-options --show-keys "$key_file"
    echo "$output"
    [ "$status" -eq 0 ]
    local key_count
    key_count="$(<<<"$output" grep -E '^pub' | wc -l)"
    [ "$key_count" -ge 1 ]
  done
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

@test "download - Downloading more than one version of an RPM should work" {
  # null and negative history should be rejected with an error
  run $manager download "${default_config[@]}" -k --resolved-rpms-file "${target_dir}/rpm_list_0" --package bash --history 0
  [ "${status}" -ne 0 ]
  grep -q 'The old version limit must be a positive number' <<<"$output"

  # Default history is 1
  run $manager download "${default_config[@]}" -k --resolved-rpms-file "${target_dir}/rpm_list_1" --package bash
  [ "${status}" -eq 0 ]
  [ "$(wc -l <"${target_dir}/rpm_list_1")" -eq 1 ]

  # Setting the history explicitly is honored
  run $manager download "${default_config[@]}" -k --resolved-rpms-file "${target_dir}/rpm_list_3" --package bash --history 3
  [ "${status}" -eq 0 ]
  [ "$(wc -l <"${target_dir}/rpm_list_3")" -gt 1 ]
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

@test "download - Group download allows package type selection" {
  run $manager download "${default_config[@]}" -k --resolved-rpms-file "${target_dir}/rpm_list_1" --group Core
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(wc -l <"${target_dir}/rpm_list_1")" -gt 0 ]

  run $manager download "${default_config[@]}" -k --resolved-rpms-file "${target_dir}/rpm_list_2" --group Core --package-type mandatory
  [ "$status" -eq 0 ]
  [ "$(wc -l <"${target_dir}/rpm_list_2")" -gt 0 ]
  ! diff -q "${target_dir}/rpm_list_2" "${target_dir}/rpm_list_1"

  run $manager download "${default_config[@]}" -k --resolved-rpms-file "${target_dir}/rpm_list_3" --group Core --package-type default
  [ "$status" -eq 0 ]
  [ "$(wc -l <"${target_dir}/rpm_list_2")" -gt 0 ]
  ! diff -q "${target_dir}/rpm_list_3" "${target_dir}/rpm_list_1"
  ! diff -q "${target_dir}/rpm_list_3" "${target_dir}/rpm_list_2"
}

@test "download - Group download allows group type selection" {
  run $manager download "${default_config[@]}" -k --resolved-rpms-file "${target_dir}/rpm_list_1" --group 'Minimal Install'
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(wc -l <"${target_dir}/rpm_list_1")" -gt 0 ]

  run $manager download "${default_config[@]}" -k --resolved-rpms-file "${target_dir}/rpm_list_2" --group 'Minimal Install' --group-type mandatory
  [ "$status" -eq 0 ]
  [ "$(wc -l <"${target_dir}/rpm_list_2")" -gt 0 ]
  ! diff -q "${target_dir}/rpm_list_2" "${target_dir}/rpm_list_1"

  run $manager download "${default_config[@]}" -k --resolved-rpms-file "${target_dir}/rpm_list_3" --group 'Minimal Install' --group-type optional
  [ "$status" -eq 0 ]
  [ "$(wc -l <"${target_dir}/rpm_list_2")" -gt 0 ]
  ! diff -q "${target_dir}/rpm_list_3" "${target_dir}/rpm_list_1"
  ! diff -q "${target_dir}/rpm_list_3" "${target_dir}/rpm_list_2"
}

@test "download - Repositories with multiple gpgkeys have all of them downloaded (atomic)" {
  if ! grep -q atomic < <(dnf repolist -q) || ! type gpg >/dev/null 2>&1; then
    skip
  fi

  run $manager download "${default_config[@]}" --gpgkeys --repo-subdirectory . --gpg-subfile "gpgkey_%{REPO}" --download-repos atomic
  [ "$status" -eq 0 ]
  # Ensure that --download-repos is honored
  [ "$(ls "${target_dir}" | wc -l)" -eq 1 ]
  # Atomic repo uses 2 gpg keys
  [ "$(LANG=C.utf-8 gpg --no-options --show-keys "${target_dir}/gpgkey_atomic" | grep -E '^pub' | wc -l)" -eq 2 ]
}
