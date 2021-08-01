
source src/commons.sh

teardown() {
  if [ -e "$tmp_dir" ]; then
    rm -rf "$tmp_dir"
  fi
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
  tmp_dir="$(mktemp -d)"

  run run_from_dir "$tmp_dir" pwd
  [ "$status" -eq 0 ]
  [ "$output" = "$tmp_dir" ]
}
