#!/usr/bin/env bash
set -euo pipefail

# Builds, installs, and dual-launches the signed development build on one
# physical iPhone with process liveness checks + machine receipt.
# Verifies deployment automation only — not full ART / extract acceptance
# (those remain operator-owned in docs/DEVICE_TEST_LOG.md).

usage() {
  echo "Usage: DEVICE_UDID=<udid> make device-smoke" >&2
  echo "   or: bash scripts/run_device_smoke.sh [device-udid]" >&2
  exit 64
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_path="$repo_root/SurveillanceSurvivor.xcodeproj"
# Keep signed build products outside cloud-managed workspace folders. File
# provider metadata on bundles below Documents can invalidate codesign.
derived_data_path="${DERIVED_DATA_PATH:-/private/tmp/surveillance-survivor-device-smoke-derived-data}"
app_path="$derived_data_path/Build/Products/Debug-iphoneos/SurveillanceSurvivor.app"
bundle_identifier="life.zerostate.surveillancesurvivor"
artifact_dir="${DEVICE_SMOKE_ARTIFACTS:-$repo_root/.device-smoke}"
settle_seconds="${DEVICE_SMOKE_SETTLE_SECONDS:-3}"
skip_generate="${DEVICE_SMOKE_SKIP_GENERATE:-0}"

device_udid="${1:-${DEVICE_UDID:-}}"
if [[ -z "$device_udid" ]]; then
  device_udid="$(bash "$repo_root/scripts/select_connected_iphone.sh")"
fi
if [[ -z "$device_udid" ]]; then
  usage
fi

mkdir -p "$artifact_dir"
log_file="$artifact_dir/device-smoke.log"
receipt_txt="$artifact_dir/receipt.txt"
started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

exec > >(tee "$log_file") 2>&1

echo "== Surveillance Survivor device smoke =="
echo "repo: $repo_root"
echo "device: $device_udid"
echo "artifacts: $artifact_dir"
echo "started: $started_at"

if [[ ! -d "$project_path" || "$skip_generate" != "1" ]]; then
  if command -v xcodegen >/dev/null 2>&1; then
    (cd "$repo_root" && xcodegen generate)
  fi
fi

if [[ ! -d "$project_path" ]]; then
  echo "Missing $project_path. Run 'make generate', then select a development team in Xcode once." >&2
  exit 66
fi

if [[ -d "$derived_data_path" ]]; then
  xattr -cr "$derived_data_path" 2>/dev/null || true
fi

xattr -cr "$repo_root/App" "$repo_root/Game" "$repo_root/Sources" 2>/dev/null || true

build_args=(
  -project "$project_path"
  -scheme SurveillanceSurvivor
  -destination "platform=iOS,id=$device_udid"
  -derivedDataPath "$derived_data_path"
  -quiet
  build
)

if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
  build_args+=("DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates)
fi

echo "Building for device..."
xcodebuild "${build_args[@]}"

if [[ ! -d "$app_path" ]]; then
  echo "Expected built app at $app_path, but it was not produced." >&2
  exit 70
fi

find_app_pid() {
  local out_json="$1"
  if ! xcrun devicectl device info processes --device "$device_udid" --json-output "$out_json" >/dev/null; then
    return 1
  fi
  python3 - "$out_json" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
procs = (data.get("result") or {}).get("runningProcesses") or []
needle = "SurveillanceSurvivor"
for p in procs:
    exe = (p.get("executable") or "")
    if needle in exe and "UITests" not in exe and "xctest" not in exe.lower():
        print(p.get("processIdentifier") or "")
        break
PY
}

# Writes pid to $3; logs go to stdout (already teed).
launch_and_assert_alive() {
  local cycle_label="$1"
  local proc_json="$2"
  local pid_file="$3"
  echo "Launching $bundle_identifier ($cycle_label)"
  xcrun devicectl device process launch --device "$device_udid" --terminate-existing "$bundle_identifier"
  echo "Settling for ${settle_seconds}s..."
  sleep "$settle_seconds"
  local pid
  pid="$(find_app_pid "$proc_json" || true)"
  if [[ -z "$pid" ]]; then
    echo "App process not found after settle ($cycle_label) — possible launch crash." >&2
    return 71
  fi
  echo "App process alive ($cycle_label): pid=$pid"
  printf '%s' "$pid" >"$pid_file"
}

echo "Installing $app_path"
xcrun devicectl device install app --device "$device_udid" "$app_path"

pid_file="$artifact_dir/app.pid"
launch_and_assert_alive "cycle-1" "$artifact_dir/processes.json" "$pid_file"
app_pid="$(cat "$pid_file")"

echo "Terminating for relaunch cycle..."
xcrun devicectl device process terminate --device "$device_udid" --pid "$app_pid" 2>/dev/null \
  || xcrun devicectl device process signal --device "$device_udid" --pid "$app_pid" --signal SIGTERM 2>/dev/null \
  || true
sleep 1
launch_and_assert_alive "cycle-2-relaunch" "$artifact_dir/processes-relaunch.json" "$pid_file"
app_pid="$(cat "$pid_file")"

commit="$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || echo unknown)"
ended_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

{
  echo "status: pass"
  echo "kind: device-smoke"
  echo "bundle: $bundle_identifier"
  echo "device: $device_udid"
  echo "app_path: $app_path"
  echo "pid: $app_pid"
  echo "started: $started_at"
  echo "ended: $ended_at"
  echo "commit: $commit"
  echo "notes: Deploy + dual-launch liveness only; not full physical acceptance."
} | tee "$receipt_txt"

python3 - "$artifact_dir/device-receipt.json" <<PY
import json
from pathlib import Path
path = Path("$artifact_dir/device-receipt.json")
payload = {
  "schemaVersion": 1,
  "kind": "device-smoke",
  "status": "pass",
  "commit": "$commit",
  "deviceUdid": "$device_udid",
  "bundleId": "$bundle_identifier",
  "appPid": int("$app_pid") if str("$app_pid").isdigit() else None,
  "startedAt": "$started_at",
  "endedAt": "$ended_at",
  "steps": [
    {"name": "build-install", "status": "pass", "exitCode": 0},
    {"name": "launch-cycle-1", "status": "pass", "exitCode": 0},
    {"name": "launch-cycle-2-relaunch", "status": "pass", "exitCode": 0},
  ],
  "logFile": "device-smoke.log",
  "notes": (
    "Automated device smoke: signed build, install, dual launch+settle+process liveness. "
    "Does NOT claim ART checklist, extract receipt, thermal, haptics, or store readiness."
  ),
}
path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\\n")
print(f"Wrote JSON receipt: {path}")
PY

printf 'Device deployment succeeded: %s (%s) pid=%s\n' "$bundle_identifier" "$device_udid" "$app_pid"
echo "Receipt: $receipt_txt"
echo "JSON: $artifact_dir/device-receipt.json"
