@test "A help is provided without error when requested" {
  run bash ./main.sh --help
  [ "$status" -eq 0 ]
  grep -qE '^usage:' <<<"$output"
}

@test "Sourcing the main script cat be done without error" {
  source ./main.sh
}
