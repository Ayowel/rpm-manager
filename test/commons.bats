
source src/commons.sh

teardown() {
  local d
  for d in "${tmp_paths[@]}"; do
    if [ -e "$d" ]; then
      rm -rf "$d"
    fi
  done
}

@test "Looking for thrown errors without setting any does not return an error" {
  run get_first_parse_error
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "Saving an exception returns an error at lookup" {
  local error_message="Not happy"

  # Ensure that no error is already saved
  run get_first_parse_error
  [ "$status" -eq 0 ]

  set_parse_error "$error_message"

  run get_first_parse_error
  [ "$status" -eq 1 ]
  [ "$output" = "$error_message" ]
}

@test "Saving multiple exceptions only return the first at lookup" {
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

@test "print_resource_by_path prints-out paths to both local and remote resources" {
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
