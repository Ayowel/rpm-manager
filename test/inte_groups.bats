#!/usr/bin/env bats

setup() {
  manager="${MANAGER:-bash ./main.sh}"
}

@test "group - Attempting to use an unsupported group mode or option returns an error" {
  run $manager group unsupported
  [ "$status" -ne 0 ]

  run $manager group --unsupported
  [ "$status" -ne 0 ]
}

@test "group list - Default behavior is to print all available base groups" {
  run $manager group list
  [ "$status" -eq 0 ]
  # Only test some known-defined groups
  local group_name
  for group_name in core print-client; do
    grep -qE "^${group_name}\$" <<<"$output"
  done
}

@test "group list - It is possible to list group members of a group" {
  local group_name='Minimal Install'
  local group_mandatory_output=core
  local group_all_output="$(printf 'Guest Agents\ncore\nstandard')"

  # Attempt to list all groups in environment with default flag
  run $manager group list "$group_name"
  [ "$status" -eq 0 ]
  [ "$output" = "$group_all_output" ]

  # Attempt to list all groups in environment with all flag
  run $manager group list -G all "$group_name"
  [ "$status" -eq 0 ]
  [ "$output" = "$group_all_output" ]

  # Attempt to list all mandatory groups in environment
  run $manager group list -G mandatory "$group_name"
  [ "$status" -eq 0 ]
  [ "$output" = "$group_mandatory_output" ]
}

@test "group list - Only base groups should match the self filter" {
  # Ensure that we can't list the group itself as it is an environment
  run $manager group list -G self 'Minimal Install'
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]

  # Ensure that we can list the Core group itself as it is a group
  run $manager group list -G self "core"
  [ "$status" -eq 0 ]
  [ "$output" = "core" ]
}

@test "group list - Invalid groups filters are detected and return an error" {
  # Ensure that using an unsupported flag throws an error
  run $manager group list -G unsupported "core"
  [ "$status" -ne 0 ]
}

@test "group packages - It is possible to list package members of a group" {
  local group_name='core'
  local group_default_output_file='test/resources/groups_group_packages_Core_default'
  local group_all_output_file='test/resources/groups_group_packages_Core_all'

  # Attempt to list all packages in group with default flags
  run $manager group packages "$group_name"
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat "$group_all_output_file")" ]

  # Attempt to list all packages in group with all flag
  run $manager group packages -P all "$group_name"
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat "$group_all_output_file")" ]

  # Attempt to list all default packages in group
  run $manager group packages -P default "$group_name"
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat "$group_default_output_file")" ]
}
