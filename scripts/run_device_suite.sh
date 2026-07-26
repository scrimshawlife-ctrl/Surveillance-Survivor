#!/usr/bin/env bash
# Automated physical-device suite:
#   select iPhone → generate → device-smoke → (optional) XCUITests → receipt.
# Complements (does not replace) operator ART / extract acceptance in
# docs/LAUNCH_OPERATOR_PACKET.md and docs/DEVICE_TEST_LOG.md.
#
# Env:
#   DEVICE_SUITE_SKIP_UI=1     — smoke only (still exit 0 on smoke pass)
#   DEVICE_SUITE_UI_SOFT=1     — UI fail → status partial, exit 0 (smoke still required)
#   DEVICE_SUITE_UI_RETRIES=2  — retries for "automation mode" timeouts (default 2)
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

artifact_dir="${DEVICE_SUITE_ARTIFACTS:-$repo_root/.device-smoke}"
mkdir -p "$artifact_dir"
log_file="$artifact_dir/device-suite.log"
result_bundle="$artifact_dir/DeviceUITests.xcresult"
derived_data_path="${DERIVED_DATA_PATH:-/private/tmp/surveillance-survivor-device-suite-derived-data}"
ui_retries="${DEVICE_SUITE_UI_RETRIES:-2}"
skip_ui="${DEVICE_SUITE_SKIP_UI:-0}"
ui_soft="${DEVICE_SUITE_UI_SOFT:-0}"

exec > >(tee "$log_file") 2>&1

started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
xcode_version="$(xcodebuild -version 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')"
steps_json="[]"
overall_status="pass"
failed_step=""
ui_note=""

device_udid="${DEVICE_UDID:-}"
if [[ -z "$device_udid" ]]; then
  device_udid="$(bash scripts/select_connected_iphone.sh)"
fi

echo "== Surveillance Survivor device suite =="
echo "repo: $repo_root"
echo "commit: $commit"
echo "device: $device_udid"
echo "artifacts: $artifact_dir"
echo "started: $started_at"
echo "xcode: $xcode_version"
echo "skip_ui=$skip_ui ui_soft=$ui_soft ui_retries=$ui_retries"

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  export DEVELOPMENT_TEAM="X9M969D8M3"
  echo "DEVELOPMENT_TEAM defaulted to $DEVELOPMENT_TEAM (override if needed)"
fi

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
  local ended_at status notes
  ended_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  status="${1:-$overall_status}"
  notes="Automated physical-device suite: deploy smoke (+ optional XCUITests). Does NOT claim ART_DEVICE_QA_CHECKLIST, extract COPY RECEIPT, thermal/haptics/audio-route, or ART_SHIP_APPROVED."
  if [[ -n "$ui_note" ]]; then
    notes="$notes $ui_note"
  fi
  DEVICE_RECEIPT_STATUS="$status" \
  DEVICE_RECEIPT_COMMIT="$commit" \
  DEVICE_RECEIPT_XCODE="$xcode_version" \
  DEVICE_RECEIPT_UDID="$device_udid" \
  DEVICE_RECEIPT_STARTED_AT="$started_at" \
  DEVICE_RECEIPT_ENDED_AT="$ended_at" \
  DEVICE_RECEIPT_STEPS_JSON="$steps_json" \
  DEVICE_RECEIPT_RESULT_BUNDLE="$(basename "$result_bundle")" \
  DEVICE_RECEIPT_NOTES="$notes" \
  python3 - "$artifact_dir/device-receipt.json" <<'PY'
import json, os, sys
from pathlib import Path
path = Path(sys.argv[1])
payload = {
    "schemaVersion": 1,
    "kind": "device-suite",
    "status": os.environ.get("DEVICE_RECEIPT_STATUS", "unknown"),
    "commit": os.environ.get("DEVICE_RECEIPT_COMMIT", "unknown"),
    "xcodeVersion": os.environ.get("DEVICE_RECEIPT_XCODE", "unknown"),
    "deviceUdid": os.environ.get("DEVICE_RECEIPT_UDID", "unknown"),
    "startedAt": os.environ.get("DEVICE_RECEIPT_STARTED_AT"),
    "endedAt": os.environ.get("DEVICE_RECEIPT_ENDED_AT"),
    "steps": json.loads(os.environ.get("DEVICE_RECEIPT_STEPS_JSON", "[]")),
    "resultBundle": os.environ.get("DEVICE_RECEIPT_RESULT_BUNDLE") or None,
    "logFile": "device-suite.log",
    "notes": os.environ.get("DEVICE_RECEIPT_NOTES", ""),
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
    echo "Device suite failed at step: $failed_step"
    echo "Receipt: $artifact_dir/device-receipt.json"
    exit "$exit_code"
  fi
}

check_unlocked() {
  local lock_json="$artifact_dir/lock-state.json"
  if ! xcrun devicectl device info lockState --device "$device_udid" --json-output "$lock_json" >/dev/null; then
    echo "Could not read lock state; continuing (UI tests may fail if locked)." >&2
    return 0
  fi
  python3 - "$lock_json" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
result = data.get("result") or {}
unlocked = result.get("unlockedSinceBoot")
print(f"lockState: unlockedSinceBoot={unlocked} passcodeRequired={result.get('passcodeRequired')}")
if unlocked is False:
    print("Device appears locked since boot. Unlock the iPhone and trust this Mac.", file=sys.stderr)
    sys.exit(73)
PY
}

print_ui_automation_help() {
  cat <<'EOF' >&2

UI Automation timed out. On the iPhone:

  1. Unlock and keep the screen awake.
  2. Trust this computer if prompted.
  3. Settings → Privacy & Security → Developer Mode = ON (reboot if just enabled).
  4. When XCTest first runs, accept any "Enable UI Automation" / trust dialog.
  5. Retry: DEVELOPMENT_TEAM=… make device-ui-test

Smoke-only (no UI Automation): DEVICE_SUITE_SKIP_UI=1 make device-test
Soft UI (smoke pass + partial receipt): DEVICE_SUITE_UI_SOFT=1 make device-test

EOF
}

run_ui_tests_once() {
  local attempt="$1"
  local attempt_bundle="${result_bundle%.xcresult}-attempt${attempt}.xcresult"
  rm -rf "$attempt_bundle"
  echo "UI test attempt $attempt → $attempt_bundle"
  local args=(
    -project SurveillanceSurvivor.xcodeproj
    -scheme SurveillanceSurvivor
    -destination "platform=iOS,id=$device_udid"
    -derivedDataPath "$derived_data_path"
    -only-testing:SurveillanceSurvivorUITests
    -resultBundlePath "$attempt_bundle"
    -allowProvisioningUpdates
    -parallel-testing-enabled NO
    CODE_SIGN_STYLE=Automatic
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
    CODE_SIGNING_ALLOWED=YES
    test
  )
  set +e
  xcodebuild "${args[@]}"
  local ec=$?
  set -e
  # Keep last attempt as the canonical result bundle path.
  rm -rf "$result_bundle"
  if [[ -d "$attempt_bundle" ]]; then
    mv "$attempt_bundle" "$result_bundle"
  fi
  return "$ec"
}

run_ui_tests_with_retries() {
  local attempt=1
  local ec=1
  while [[ $attempt -le $ui_retries ]]; do
    set +e
    run_ui_tests_once "$attempt"
    ec=$?
    set -e
    if [[ $ec -eq 0 ]]; then
      return 0
    fi
    # Detect automation-mode timeout in log/xcresult name heuristically via suite log tail.
    if grep -q "enabling automation mode" "$log_file" 2>/dev/null \
      || grep -q "Timed out while enabling automation mode" "$log_file" 2>/dev/null; then
      echo "Automation mode timeout on attempt $attempt/$ui_retries"
      print_ui_automation_help
      if [[ $attempt -lt $ui_retries ]]; then
        echo "Waiting 15s for operator to accept UI Automation trust dialog on device..."
        sleep 15
      fi
    else
      echo "UI tests failed (exit=$ec) on attempt $attempt/$ui_retries"
      if [[ $attempt -lt $ui_retries ]]; then
        sleep 5
      fi
    fi
    attempt=$((attempt + 1))
  done
  return "$ec"
}

run_ui_step() {
  if [[ "$skip_ui" == "1" ]]; then
    echo "DEVICE_SUITE_SKIP_UI=1 — skipping XCUITests"
    append_step "device-ui-tests" "skipped" 0 0
    ui_note="UI tests skipped via DEVICE_SUITE_SKIP_UI."
    return 0
  fi
  local start end duration ec
  echo ""
  echo "---- device-ui-tests ----"
  start="$(date +%s)"
  set +e
  run_ui_tests_with_retries
  ec=$?
  set -e
  end="$(date +%s)"
  duration=$((end - start))
  if [[ $ec -eq 0 ]]; then
    echo "---- device-ui-tests OK (${duration}s) ----"
    append_step "device-ui-tests" "pass" 0 "$duration"
    return 0
  fi
  echo "---- device-ui-tests FAILED exit=$ec (${duration}s) ----"
  append_step "device-ui-tests" "fail" "$ec" "$duration"
  if [[ "$ui_soft" == "1" ]]; then
    overall_status="partial"
    ui_note="UI tests failed (often automation mode trust); smoke still pass. Set DEVICE_SUITE_UI_SOFT=0 to fail-closed."
    echo "DEVICE_SUITE_UI_SOFT=1 — treating UI failure as partial (smoke still green)."
    print_ui_automation_help
    return 0
  fi
  overall_status="fail"
  failed_step="device-ui-tests"
  write_receipt "fail"
  print_ui_automation_help
  echo "Device suite failed at step: device-ui-tests"
  echo "Receipt: $artifact_dir/device-receipt.json"
  exit "$ec"
}

set -e

run_step "lock-check" check_unlocked
run_step "generate" make generate
export DEVICE_UDID="$device_udid"
export DEVICE_SMOKE_ARTIFACTS="$artifact_dir"
export DEVICE_SMOKE_SKIP_GENERATE=1
export DERIVED_DATA_PATH="$derived_data_path"
run_step "device-smoke" bash scripts/run_device_smoke.sh "$device_udid"
run_ui_step

write_receipt "$overall_status"
echo ""
if [[ "$overall_status" == "pass" ]]; then
  echo "Device suite passed."
elif [[ "$overall_status" == "partial" ]]; then
  echo "Device suite partial (smoke pass; UI incomplete)."
else
  echo "Device suite finished with status=$overall_status"
fi
echo "Artifacts under: $artifact_dir"
echo "Receipt: $artifact_dir/device-receipt.json"
if [[ -d "$result_bundle" ]]; then
  echo "xcresult: $result_bundle"
fi
echo ""
echo "NOTE: Automated deploy (+ optional chrome XCUITests) only."
echo "Operator still owns ART checklist + extract receipt for ship_gate."
