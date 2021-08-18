@test "A help is provided without error when requested" {
  run bash ./main.sh --help
  [ "$status" -eq 0 ]
  <<<"$output" grep -qE '^usage:'
}

@test "An error occurs when attempting to use a module that does not exist" {
  run bash ./main.sh this_command_does_not_exist
  [ "$status" -ne 0 ]
  <<<"$output" grep -qE '^No valid mode used'
}

@test "No error occurs when getting help with an invalid command" {
  run bash ./main.sh this_command_does_not_exist --help
  [ "$status" -eq 0 ]
}

@test "The version is provided without error when requested" {
  run bash ./main.sh --version
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  <<<"$output" grep -qE '^v([0-9]+\.){2}[0-9]+$'
}

@test "An error is returned when an invalid option is provided" {
  run bash ./main.sh --versino
  [ "$status" -ne 0 ]
  <<<"$output" grep -qE '^Unsupported option or parameter'
}

