#!/usr/bin/env bash
set -euo pipefail

# Full automated emulator suite for local and CI-adjacent runs:
# privacy → assets → package tests → simulator unit/UI tests → launch smoke.
# Physical-device acceptance remains separate (make device-smoke + RELEASE_READINESS).

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

artifact_dir="${EMULATOR_SUITE_ARTIFACTS:-$repo_root/.simulator-smoke}"
mkdir -p "$artifact_dir"
log_file="$artifact_dir/emulator-suite.log"

exec > >(tee "$log_file") 2>&1

echo "== Surveillance Survivor emulator suite =="
echo "repo: $repo_root"
echo "log: $log_file"

run_step() {
  local name="$1"
  shift
  echo ""
  echo "---- $name ----"
  "$@"
  echo "---- $name OK ----"
}

run_step "privacy-check" make privacy-check
run_step "assets-check" make assets-check
run_step "package-tests" make test
run_step "simulator-tests" make simulator-test
run_step "simulator-smoke" make simulator-smoke

echo ""
echo "Emulator suite passed."
echo "Artifacts under: $artifact_dir"
