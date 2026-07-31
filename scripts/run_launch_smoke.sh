#!/usr/bin/env bash
set -euo pipefail

# Non-UITesting launch-shell smoke:
#   splash (or auto-advance) → start menu → BEGIN RUN → play chrome.
# Simulator by default; set DEVICE_UDID + DEVELOPMENT_TEAM for physical iPhone.
# Does not claim ART, extract, thermal, or store readiness.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_path="$repo_root/SurveillanceSurvivor.xcodeproj"
artifact_dir="${LAUNCH_SMOKE_ARTIFACTS:-$repo_root/.launch-smoke}"
skip_generate="${LAUNCH_SMOKE_SKIP_GENERATE:-0}"
only_testing="SurveillanceSurvivorUITests/LaunchShellUITests"

mkdir -p "$artifact_dir"
log_file="$artifact_dir/launch-smoke.log"
result_bundle="$artifact_dir/LaunchShellUITests.xcresult"
started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

exec > >(tee "$log_file") 2>&1

echo "== Surveillance Survivor launch-shell smoke =="
echo "repo: $repo_root"
echo "artifacts: $artifact_dir"
echo "started: $started_at"
echo "note: does NOT pass -UITesting; exercises real splash + start menu"

if [[ ! -d "$project_path" || "$skip_generate" != "1" ]]; then
  if command -v xcodegen >/dev/null 2>&1; then
    (cd "$repo_root" && xcodegen generate)
  fi
fi

if [[ ! -d "$project_path" ]]; then
  echo "Missing $project_path. Run 'make generate'." >&2
  exit 66
fi

rm -rf "$result_bundle"

device_udid="${DEVICE_UDID:-}"
if [[ -n "$device_udid" ]]; then
  team="${DEVELOPMENT_TEAM:-X9M969D8M3}"
  derived_data_path="${DERIVED_DATA_PATH:-/private/tmp/surveillance-survivor-launch-smoke-device-derived-data}"
  echo "destination: physical iOS id=$device_udid team=$team"
  xcodebuild \
    -project "$project_path" \
    -scheme SurveillanceSurvivor \
    -destination "platform=iOS,id=$device_udid" \
    -derivedDataPath "$derived_data_path" \
    -only-testing:"$only_testing" \
    -resultBundlePath "$result_bundle" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="$team" \
    CODE_SIGNING_ALLOWED=YES \
    test
else
  simulator_id="${SIMULATOR_UDID:-$(bash "$repo_root/scripts/select_available_iphone_simulator.sh")}"
  if [[ -z "$simulator_id" ]]; then
    echo "No available iPhone simulator found." >&2
    exit 70
  fi
  derived_data_path="${DERIVED_DATA_PATH:-/private/tmp/surveillance-survivor-launch-smoke-sim-derived-data}"
  echo "destination: iOS Simulator id=$simulator_id"
  xcodebuild \
    -project "$project_path" \
    -scheme SurveillanceSurvivor \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath "$derived_data_path" \
    -only-testing:"$only_testing" \
    -resultBundlePath "$result_bundle" \
    CODE_SIGNING_ALLOWED=NO \
    test
fi

ended_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
commit="$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || echo unknown)"

{
  echo "status: pass"
  echo "kind: launch-shell-smoke"
  echo "only_testing: $only_testing"
  echo "result_bundle: $result_bundle"
  echo "started: $started_at"
  echo "ended: $ended_at"
  echo "commit: $commit"
  echo "notes: Real splash + start menu (no -UITesting). Not ART/extract acceptance."
} | tee "$artifact_dir/receipt.txt"

python3 - "$artifact_dir/launch-smoke-receipt.json" "$commit" "$started_at" "$ended_at" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
payload = {
    "schemaVersion": 1,
    "status": "pass",
    "kind": "launch-shell-smoke",
    "commit": sys.argv[2],
    "startedAt": sys.argv[3],
    "endedAt": sys.argv[4],
    "onlyTesting": "SurveillanceSurvivorUITests/LaunchShellUITests",
    "resultBundle": "LaunchShellUITests.xcresult",
    "logFile": "launch-smoke.log",
    "notes": "No -UITesting. Proves splash → start menu → BEGIN RUN → play chrome.",
}
path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Wrote JSON receipt: {path}")
PY

echo "Launch-shell smoke passed."
echo "Artifacts under: $artifact_dir"
