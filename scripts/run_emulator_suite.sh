#!/usr/bin/env bash
# Full automated emulator suite for local and CI-adjacent runs:
# privacy → assets → package tests → simulator unit/UI tests → launch smoke.
# Physical-device acceptance remains separate (make device-smoke + RELEASE_READINESS).
# Always writes emulator-receipt.json (even on failure) under the artifact dir.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

artifact_dir="${EMULATOR_SUITE_ARTIFACTS:-$repo_root/.simulator-smoke}"
mkdir -p "$artifact_dir"
log_file="$artifact_dir/emulator-suite.log"

# Tee all output to the suite log while still printing to the console.
exec > >(tee "$log_file") 2>&1

started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
swift_version="$(swift --version 2>/dev/null | head -1 | tr '"' "'")"
xcode_version="$(xcodebuild -version 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')"
simulator_id="$(bash scripts/select_available_iphone_simulator.sh 2>/dev/null || true)"
steps_json="[]"
overall_status="pass"
failed_step=""

echo "== Surveillance Survivor emulator suite =="
echo "repo: $repo_root"
echo "log: $log_file"
echo "commit: $commit"
echo "started: $started_at"

append_step() {
  local name="$1"
  local status="$2"
  local exit_code="$3"
  local duration="$4"
  steps_json="$(python3 -c "
import json
steps=json.loads('''$steps_json''')
steps.append({'name': '''$name''', 'status': '''$status''', 'exitCode': int('''$exit_code'''), 'durationSeconds': float('''$duration''')})
print(json.dumps(steps))
")"
}

write_receipt() {
  local ended_at status
  ended_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  status="${1:-$overall_status}"
  local screenshot=""
  if [[ -f "$artifact_dir/launch.png" ]]; then
    screenshot="launch.png"
  fi
  EMULATOR_RECEIPT_STATUS="$status" \
  EMULATOR_RECEIPT_COMMIT="$commit" \
  EMULATOR_RECEIPT_SWIFT="$swift_version" \
  EMULATOR_RECEIPT_XCODE="$xcode_version" \
  EMULATOR_RECEIPT_SIM="${simulator_id:-unknown}" \
  EMULATOR_RECEIPT_STARTED_AT="$started_at" \
  EMULATOR_RECEIPT_ENDED_AT="$ended_at" \
  EMULATOR_RECEIPT_STEPS_JSON="$steps_json" \
  EMULATOR_RECEIPT_SCREENSHOT="$screenshot" \
  python3 - "$artifact_dir/emulator-receipt.json" <<'PY'
import json, os, sys
from pathlib import Path
path = Path(sys.argv[1])
payload = {
    "schemaVersion": 1,
    "status": os.environ.get("EMULATOR_RECEIPT_STATUS", "unknown"),
    "commit": os.environ.get("EMULATOR_RECEIPT_COMMIT", "unknown"),
    "swiftVersion": os.environ.get("EMULATOR_RECEIPT_SWIFT", "unknown"),
    "xcodeVersion": os.environ.get("EMULATOR_RECEIPT_XCODE", "unknown"),
    "simulatorId": os.environ.get("EMULATOR_RECEIPT_SIM", "unknown"),
    "startedAt": os.environ.get("EMULATOR_RECEIPT_STARTED_AT"),
    "endedAt": os.environ.get("EMULATOR_RECEIPT_ENDED_AT"),
    "steps": json.loads(os.environ.get("EMULATOR_RECEIPT_STEPS_JSON", "[]")),
    "screenshot": os.environ.get("EMULATOR_RECEIPT_SCREENSHOT") or None,
    "logFile": "emulator-suite.log",
    "notes": "Simulator evidence only; not physical-device acceptance.",
}
path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
print(f"Wrote receipt: {path}")
PY
}

run_step() {
  local name="$1"
  shift
  local start end duration status exit_code
  echo ""
  echo "---- $name ----"
  start="$(date +%s)"
  set +e
  "$@"
  exit_code=$?
  set -e
  end="$(date +%s)"
  duration=$((end - start))
  if [[ $exit_code -eq 0 ]]; then
    status="pass"
    echo "---- $name OK (${duration}s) ----"
  else
    status="fail"
    overall_status="fail"
    failed_step="$name"
    echo "---- $name FAILED exit=$exit_code (${duration}s) ----"
  fi
  append_step "$name" "$status" "$exit_code" "$duration"
  if [[ $exit_code -ne 0 ]]; then
    write_receipt "fail"
    echo "Emulator suite failed at step: $failed_step"
    echo "Receipt: $artifact_dir/emulator-receipt.json"
    exit "$exit_code"
  fi
}

set -e
run_step "privacy-check" make privacy-check
run_step "assets-check" make assets-check
run_step "package-tests" make test
run_step "simulator-tests" make simulator-test
run_step "simulator-smoke" make simulator-smoke

write_receipt "pass"
echo ""
echo "Emulator suite passed."
echo "Artifacts under: $artifact_dir"
echo "Receipt: $artifact_dir/emulator-receipt.json"
