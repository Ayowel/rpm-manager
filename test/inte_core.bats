#!/usr/bin/env bats

setup() {
  manager="${MANAGER:-bash ./main.sh}"
}

@test "main - A help is provided without error when requested" {
  run $manager --help
  [ "$status" -eq 0 ]
  <<<"$output" grep -qE '^usage:'
}

@test "main - An error occurs when attempting to use a module that does not exist" {
  run $manager this_command_does_not_exist
  [ "$status" -ne 0 ]
  <<<"$output" grep -qE '^No valid mode used'
}

@test "main - No error occurs when getting help with an invalid command" {
  run $manager this_command_does_not_exist --help
  [ "$status" -eq 0 ]
}

@test "main - The version is provided without error when requested" {
  run $manager --version
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  <<<"$output" grep -qE '^v([0-9]+\.){2}[0-9]+$'
}

@test "main - An error is returned when an invalid option is provided" {
  run $manager --versino
  [ "$status" -ne 0 ]
  <<<"$output" grep -qE '^Unsupported option or parameter'
}
