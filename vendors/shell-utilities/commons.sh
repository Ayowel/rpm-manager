## @file
## @brief Common utility functions

## @fn join_by()
## @brief Merge parameters received with the first parameter
## @internal
## @param merge_key String to insert between each merged item
## @param items... Strings to merge
## @return Merged string
join_by() {
  test "$#" -le 1 && return 0
  local merge_key="$1"
  local out_string="$2"
  shift; shift

  for value in "$@"; do
    out_string="${out_string}${merge_key}${value}"
  done
  echo "$out_string"
}

## @fn fatal()
## @brief Exit script with an error message
## @param message Error message to print
## @param retVal Script exit value (Defaults to 1)
fatal() {
  local message="$1"
  local retVal="${2:-1}"
  
  if test -n "$message"; then
    echo "[FATAL] $message" >&2
  fi
  exit "$retVal"
}

## @fn filelog()
## @brief Log command's output to a file
## @param log_file Output log file to write to
## @param error_file Error log file to output to (If not provided, defaults to \p log_file )
## @param exec_command... Command to execute
## @return Return value of the function called
## @note If \p log_file and \p error_file are identical, all outputted logs will go to stdout
## @note If LOG_STRATEGY is 'add', the output file will be appended to
filelog() {
  local log_file="$1"
  local error_file="${2:-$log_file}"
  shift; shift

  local tee_arg=
  if test "$LOG_STRATEGY" == add; then
    tee_arg=-a
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  mkfifo --mode=600 "${tmp_dir}/log_out"
  mkfifo --mode=600 "${tmp_dir}/log_err"
  tee $tee_arg "$log_file" <"${tmp_dir}/log_out"&
  if test "$log_file" == "$error_file"; then
    tee -a "$log_file" <"${tmp_dir}/log_err" >&2 &
    "$@" >"${tmp_dir}/log_out" 2>"${tmp_dir}/log_err"
  else
    tee $tee_arg "$error_file" <"${tmp_dir}/log_err" >&2 &
    "$@" >"${tmp_dir}/log_out" 2>"${tmp_dir}/log_err"
  fi
  local retval="$?"
  rm -rf "$tmp_dir"
  return "$retval"
}
