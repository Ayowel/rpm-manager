#!/usr/bin/env bats

setup() {
  tmp_paths=( )
  source src/commons.sh
}

teardown() {
  local d
  for d in "${tmp_paths[@]}"; do
    if [ -e "$d" ]; then
      rm -rf "$d"
    fi
  done
}

@test "get_first_parse_error does not return an error if no exception was set" {
  run get_first_parse_error
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "get_first_parse_error returns an error at lookup after saving an exception" {
  local error_message="Not happy"

  # Ensure that no error is already saved
  run get_first_parse_error
  [ "$status" -eq 0 ]

  set_parse_error "$error_message"

  run get_first_parse_error
  [ "$status" -eq 1 ]
  [ "$output" = "$error_message" ]
}

@test "get_first_parse_error only returns the first at lookup after saving multiple exceptions" {
  local error_message1="Not happy"
  local error_message2="Not allowed"

  # Ensure that no error is already saved
  run get_first_parse_error
  [ "$status" -eq 0 ]

  set_parse_error "$error_message1"
  set_parse_error "$error_message2"

  run get_first_parse_error
  [ "$status" -eq 1 ]
  [ "$output" = "$error_message1" ]
}

@test "run_from_dir executes the function provided as parameter from the target directory" {
  tmp_paths=( "$(mktemp -d)" )
  local tmp_dir="${tmp_paths[0]}"

  run run_from_dir "$tmp_dir" pwd
  [ "$status" -eq 0 ]
  [ "$output" = "$tmp_dir" ]
}

@test "print_resource_by_path prints-out contents of both local and remote resources" {
  tmp_paths=( "$(mktemp)" )
  local test_file="${tmp_paths[0]}"
  local test_file_content
  test_file_content="$(printf 'This is\na multiline\ncontent')"
  local test_website_domain="example.com"
  local test_website_content_reference_string='<title>Example Domain</title>'
  local content_buffer

  echo -n "$test_file_content" >"$test_file"

  # Attempt local file resolution by path
  content_buffer="$(print_resource_by_path "$test_file")"
  [ "$content_buffer" = "$test_file_content" ]

  # Attempt local file resolution by URI
  content_buffer="$(print_resource_by_path "file://${test_file}")"
  [ "$content_buffer" = "$test_file_content" ]

  # Attempt remote file resolution by http URI
  content_buffer="$(print_resource_by_path "http://${test_website_domain}")"
  grep -q "$test_website_content_reference_string" <<<"$content_buffer"

  # Attempt remote file resolution by https URI
  content_buffer="$(print_resource_by_path "https://${test_website_domain}")"
  grep -q "$test_website_content_reference_string" <<<"$content_buffer"
}

@test "print_resource_by_path returns an error when an invalid path or protocol is used" {
  tmp_paths=( "$(mktemp)" "$(mktemp)" )
  unreadable_file="${tmp_paths[0]}"
  unexisting_file="${tmp_paths[1]}"
  unsupported_protocol='ssh://example.com'
  invalid_domain='http://e'

  chmod 200 "$unreadable_file"
  rm -f "$unexisting_file"

  run print_resource_by_path "$unreadable_file"
  [ "$status" -ne 0 ]

  run print_resource_by_path "$unexisting_file"
  [ "$status" -ne 0 ]

  run print_resource_by_path "$unsupported_protocol"
  [ "$status" -ne 0 ]

  run print_resource_by_path "invalid_domain"
  [ "$status" -ne 0 ]
}

@test "print_unpacked_file_content fails on unsupported or unavailable file" {
  tmp_paths=( "$(mktemp -d)" )
  local tmp_dir="${tmp_paths[0]}"

  # File does not exist
  run print_unpacked_file_content "${tmp_dir}/undefined"
  [ "$status" -ne 0 ]
  grep 'Failed to access' <<<"$output"

  # File exists but is not supported
  echo 'Test file' >"${tmp_dir}/my_file.exe"
  run print_unpacked_file_content "${tmp_dir}/my_file.exe"
  [ "$status" -ne 0 ]
  grep 'Unsupported file format' <<<"$output"
}

@test "print_unpacked_file_content supports gz files" {
  if ! type gzip; then
    skip
  fi

  tmp_paths=( "$(mktemp -d)" )
  local target_path="${tmp_paths[0]}/test.gz"
  local content="Test file"
  gzip -c >"$target_path" <<<"$content"

  run print_unpacked_file_content "$target_path"
  [ "$status" -eq 0 ]
  [ "$output" = "$content" ]
}

@test "print_unpacked_file_content supports xz files" {
  if ! type xz; then
    skip
  fi

  tmp_paths=( "$(mktemp -d)" )
  local target_path="${tmp_paths[0]}/test.xz"
  local content="Test file"
  xz -cz >"$target_path" <<<"$content"

  run print_unpacked_file_content "$target_path"
  [ "$status" -eq 0 ]
  [ "$output" = "$content" ]
}

@test "print_unpacked_file_content supports matching raw file paths" {
  tmp_paths=( "$(mktemp -d)" )
  local target_path="${tmp_paths[0]}/test.my_raw"
  local content="Test file"
  cat - >"$target_path" <<<"$content"

  run print_unpacked_file_content "$target_path" 'my_raw$'
  [ "$status" -eq 0 ]
  [ "$output" = "$content" ]
}
