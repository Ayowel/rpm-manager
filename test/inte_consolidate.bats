#!/usr/bin/env bats

setup() {
  manager="${MANAGER:-bash ./rpm-manager.sh}"
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

@test "consolidate - Providing an unsupported mode exits with an error" {
  local out="${target_dir}/out"
  run $manager consolidate unsupported -o "$out"
  [ "$status" -ne 0 ]
  [ ! -e "$out" ]
  echo "$output"
  grep -q 'Invalid consolidation type' <<<"$output"
}

@test "consolidate - Providing unsupported options exits with an error" {
  run $manager consolidate --unsupported
  [ "$status" -ne 0 ]
  grep -q 'Unsupported option' <<<"$output"
}

@test "consolidate group - Consolidating group files produces a valid xml file" {
  # Test dangling parameter and option provisionning
  local consolidation_targets=( test/resources/consolidate_group_comps_A.xml --source test/resources/consolidate_group_comps_B.xml )
  local out_file_awk="${target_dir}/comps_awk.xml"
  local out_file_xmllint="${target_dir}/comps_xmllint.xml"

  run $manager consolidate group --use-awk -o "$out_file_awk" "${consolidation_targets[@]}"
  [ "$status" -eq 0 ]
  [ -s "$out_file_awk" ]

  run $manager consolidate group --use-xmllint -o "$out_file_xmllint" "${consolidation_targets[@]}"
  [ "$status" -eq 0 ]
  [ -s "$out_file_xmllint" ]

  # FIXME: find a way to validate the generated xml files
  skip
}

@test "consolidate module - Consolidating module files produces a valid yaml file" {
  local out_file="${target_dir}/module.yaml"
  local consolidation_targets=( test/resources/consolidate_module_module_A.yaml --source test/resources/consolidate_module_module_B.yaml )

  run $manager consolidate module -o "$out_file" "${consolidation_targets[@]}"
  [ "$status" -eq 0 ]
  [ -s "$out_file" ]
  # Finalize validation if possible
  if ! type yamllint >/dev/null 2>&1; then
    skip
  fi
  yamllint -c test/resources/yamllint.conf "$out_file"
}

@test "consolidate gpgkey - Consolidating key files produces a valid file" {
  local expected_fingerprints=( 88AE1487EEFDE46C45A2EC79B414E7AE852CC57A 907D2B545785D8704691A41644D18EF9C1288B07 )
  local out_file="${target_dir}/gpgkey"
  local consolidation_targets=( test/resources/consolidate_gpgkey_key_A --source test/resources/consolidate_gpgkey_key_B )

  run $manager consolidate gpgkey -o "$out_file" "${consolidation_targets[@]}"
  [ "$status" -eq 0 ]
  [ -s "$out_file" ]

  # Finalize validation if possible
  if ! type gpg >/dev/null 2>&1; then
    skip
  fi
  local key_ids
  local finngerprint
  key_ids="$(LANG=C.utf-8 gpg --no-options --show-keys "$out_file" | grep -vE '^[a-z]')"
  for fingerprint in "${expected_fingerprints[@]}"; do
    grep -q "$fingerprint" <<<"$key_ids"
  done
}

@test "consolidate * - Verbose mode prints out the source consolidated files" {
  local out_file="${target_dir}/module.yaml"
  local consolidation_targets=( test/resources/consolidate_module_module_A.yaml test/resources/consolidate_module_module_B.yaml )
  local source_prefix='USING'

  run $manager consolidate module -v -o "$out_file" "${consolidation_targets[@]}"
  echo "$output"
  [ "$status" -eq 0 ]
  [ -s "$out_file" ]
  local source
  for source in "${consolidation_targets[@]}"; do
    grep -q "${source_prefix} ${source}" <<<"$output"
  done
  # Finalize validation if possible
  if ! type yamllint >/dev/null 2>&1; then
    skip
  fi
  yamllint -c test/resources/yamllint.conf "$out_file"
}

@test "consolidate * - Providing a path to a directory that does not contain valid files returns an error" {
  local out_file="${target_dir}/module.yaml"
  local source_prefix='USING'

  run $manager consolidate module -v -o "$out_file" "${target_dir}"
  [ "$status" -ne 0 ]
  [ ! -e "$out_file" ]
  grep 'No valid consolidation source file found' <<<"$output"
}
