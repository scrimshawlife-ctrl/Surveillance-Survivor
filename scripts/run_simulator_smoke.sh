#!/usr/bin/env bash
set -euo pipefail

# Automated iOS Simulator smoke:
# generate → boot → build → install → launch → settle → screenshot → process check.
# Does not claim physical-device acceptance or full gameplay verification.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_path="$repo_root/SurveillanceSurvivor.xcodeproj"
bundle_identifier="life.zerostate.surveillancesurvivor"
derived_data_path="${DERIVED_DATA_PATH:-/private/tmp/surveillance-survivor-simulator-smoke-derived-data}"
artifact_dir="${SIMULATOR_SMOKE_ARTIFACTS:-$repo_root/.simulator-smoke}"
settle_seconds="${SIMULATOR_SMOKE_SETTLE_SECONDS:-3}"
smoke_scenario="${SIMULATOR_SMOKE_SCENARIO:-}"
smoke_district="${SIMULATOR_SMOKE_DISTRICT:-}"
reduced_presentation="${SIMULATOR_SMOKE_REDUCED_PRESENTATION:-0}"
skip_build="${SIMULATOR_SMOKE_SKIP_BUILD:-0}"
skip_install="${SIMULATOR_SMOKE_SKIP_INSTALL:-0}"
boot_timeout_seconds="${SIMULATOR_SMOKE_BOOT_TIMEOUT:-120}"

mkdir -p "$artifact_dir"
log_file="$artifact_dir/simulator-smoke.log"
screenshot_path="$artifact_dir/launch.png"
landscape_screenshot_path="$artifact_dir/launch-landscape.png"
receipt_path="$artifact_dir/receipt.txt"

exec > >(tee "$log_file") 2>&1

echo "== Surveillance Survivor simulator smoke =="
echo "repo: $repo_root"
echo "artifacts: $artifact_dir"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install with: brew install xcodegen" >&2
  exit 69
fi

cd "$repo_root"
if [[ "$skip_build" != "1" ]]; then
  xcodegen generate
fi

if [[ ! -d "$project_path" ]]; then
  echo "Missing $project_path after xcodegen generate." >&2
  exit 66
fi

simulator_id="${SIMULATOR_UDID:-$(bash "$repo_root/scripts/select_available_iphone_simulator.sh")}"
if [[ -z "$simulator_id" ]]; then
  echo "No available iPhone simulator found." >&2
  exit 70
fi
echo "Using simulator: $simulator_id"

# Boot if needed, wait until ready. Prefer bootstatus (bounded) over probing
# launchctl print system, which can hang on some runtimes.
state="$(xcrun simctl list devices | awk -v id="$simulator_id" '
  $0 ~ id {
    if ($0 ~ /\(Booted\)/) { print "Booted"; exit }
    if ($0 ~ /\(Shutdown\)/) { print "Shutdown"; exit }
  }
')"
if [[ "$state" != "Booted" ]]; then
  echo "Booting simulator..."
  xcrun simctl boot "$simulator_id" 2>/dev/null || true
  # -b blocks until boot completes or the process is interrupted.
  xcrun simctl bootstatus "$simulator_id" -b
else
  echo "Simulator already booted."
fi

if [[ "$skip_build" != "1" ]]; then
  echo "Building for simulator..."
  xcodebuild \
    -project "$project_path" \
    -scheme SurveillanceSurvivor \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath "$derived_data_path" \
    CODE_SIGNING_ALLOWED=NO \
    -quiet \
    build
else
  echo "Reusing simulator build at $derived_data_path"
fi

app_path="$derived_data_path/Build/Products/Debug-iphonesimulator/SurveillanceSurvivor.app"
if [[ ! -d "$app_path" ]]; then
  echo "Expected built app at $app_path" >&2
  exit 70
fi

if [[ "$skip_install" != "1" ]]; then
  echo "Installing $app_path"
  xcrun simctl uninstall "$simulator_id" "$bundle_identifier" 2>/dev/null || true
  xcrun simctl install "$simulator_id" "$app_path"
else
  echo "Reusing installed $bundle_identifier"
fi

echo "Launching $bundle_identifier"
# Terminate any prior instance, then launch. Do not use --console (it attaches
# and blocks the smoke script until the app exits).
xcrun simctl terminate "$simulator_id" "$bundle_identifier" 2>/dev/null || true
launch_args=()
if [[ -n "$smoke_scenario" ]]; then
  launch_args=(--args -UITesting -UITestScenario "$smoke_scenario")
  echo "Scenario: $smoke_scenario"
fi
if [[ -n "$smoke_district" ]]; then
  launch_args+=(-UITestDistrict "$smoke_district")
  echo "District: $smoke_district"
fi
if [[ "$reduced_presentation" == "1" ]]; then
  launch_args+=(-UITestReducedPresentation)
  echo "Reduced presentation: enabled"
fi
launch_output="$(xcrun simctl launch "$simulator_id" "$bundle_identifier" "${launch_args[@]}" 2>&1)"
echo "$launch_output"

# simctl launch prints: <bundle>: <pid>
app_pid="$(printf '%s\n' "$launch_output" | sed -n 's/.*: \([0-9][0-9]*\)$/\1/p' | tail -1 || true)"
if [[ -z "$app_pid" ]]; then
  sleep 1
  app_pid="$(xcrun simctl spawn "$simulator_id" launchctl list 2>/dev/null | awk -v bid="$bundle_identifier" '$3 == bid { print $1; exit }' || true)"
fi

echo "Settling for ${settle_seconds}s..."
sleep "$settle_seconds"

# Confirm the process is still alive after settle (crash detector).
if [[ -n "$app_pid" && "$app_pid" != "-" ]]; then
  if ! xcrun simctl spawn "$simulator_id" launchctl print "pid/$app_pid" >/dev/null 2>&1; then
    # launchctl print may not always work; check list
    if ! xcrun simctl spawn "$simulator_id" launchctl list 2>/dev/null | awk -v bid="$bundle_identifier" '$3 == bid { found=1 } END { exit !found }'; then
      echo "App process exited during settle window (possible launch crash)." >&2
      exit 71
    fi
  fi
else
  if ! xcrun simctl spawn "$simulator_id" launchctl list 2>/dev/null | awk -v bid="$bundle_identifier" '$3 == bid { found=1 } END { exit !found }'; then
    echo "App process not found after launch." >&2
    exit 71
  fi
fi

echo "Capturing screenshot → $screenshot_path"
xcrun simctl io "$simulator_id" screenshot "$screenshot_path"

# Lightweight size check so a blank/failed capture is obvious.
if [[ ! -s "$screenshot_path" ]]; then
  echo "Screenshot was not written." >&2
  exit 72
fi

# simctl may encode a landscape-only app inside a portrait-oriented PNG canvas.
# Preserve the raw capture and also emit a normalized landscape artifact for review.
cp "$screenshot_path" "$landscape_screenshot_path"
pixel_width="$(sips -g pixelWidth "$landscape_screenshot_path" | awk '/pixelWidth/ {print $2}')"
pixel_height="$(sips -g pixelHeight "$landscape_screenshot_path" | awk '/pixelHeight/ {print $2}')"
if [[ -n "$pixel_width" && -n "$pixel_height" && "$pixel_height" -gt "$pixel_width" ]]; then
  echo "Normalizing portrait-encoded simulator capture to landscape."
  sips -r -90 "$landscape_screenshot_path" >/dev/null
fi

{
  echo "status: pass"
  echo "bundle: $bundle_identifier"
  echo "simulator: $simulator_id"
  echo "app_path: $app_path"
  echo "screenshot: $screenshot_path"
  echo "landscape_screenshot: $landscape_screenshot_path"
  echo "pid: ${app_pid:-unknown}"
  echo "scenario: ${smoke_scenario:-default}"
  echo "district: ${smoke_district:-default}"
  echo "reduced_presentation: $reduced_presentation"
  echo "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "commit: $(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || echo unknown)"
} | tee "$receipt_path"


# Machine-readable smoke receipt (schema 1). Simulator evidence only.
python3 - "$artifact_dir/emulator-receipt.json" <<'PYJSON'
import json, os, subprocess, sys
from pathlib import Path
from datetime import datetime, timezone
path = Path(sys.argv[1])
commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], text=True).strip() if Path(".git").exists() else "unknown"
payload = {
  "schemaVersion": 1,
  "status": "pass",
  "commit": commit,
  "swiftVersion": None,
  "xcodeVersion": None,
  "simulatorId": os.environ.get("SIMULATOR_UDID") or "unknown",
  "startedAt": None,
  "endedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
  "steps": [{"name": "simulator-smoke", "status": "pass", "exitCode": 0}],
  "screenshot": "launch.png" if Path(path.parent / "launch.png").exists() else None,
  "landscapeScreenshot": "launch-landscape.png" if Path(path.parent / "launch-landscape.png").exists() else None,
  "logFile": "simulator-smoke.log",
  "notes": "Smoke-only receipt from run_simulator_smoke.sh; full suite writes richer steps.",
}
# Prefer sim id from receipt.txt if present
receipt_txt = path.parent / "receipt.txt"
if receipt_txt.exists():
  for line in receipt_txt.read_text().splitlines():
    key, separator, value = line.partition(":")
    if not separator:
      continue
    value = value.strip()
    if key == "simulator":
      payload["simulatorId"] = value
    elif key == "scenario":
      payload["scenario"] = value
    elif key == "district":
      payload["district"] = value
    elif key == "reduced_presentation":
      payload["reducedPresentation"] = value == "1"
path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
print(f"Wrote JSON receipt: {path}")
PYJSON

echo "Simulator smoke succeeded."
echo "Receipt: $receipt_path"
echo "Screenshot: $screenshot_path"
echo "Normalized screenshot: $landscape_screenshot_path"
