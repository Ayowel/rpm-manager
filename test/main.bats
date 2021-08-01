
@test "A help is provided without error when requested" {
  run bash ./main.sh --help
  [ "$status" -eq 0 ]
  grep -qE '^usage:' <<<"$output"
}

