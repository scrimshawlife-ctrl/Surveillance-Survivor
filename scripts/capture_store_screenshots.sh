#!/usr/bin/env bash
# Capture truthful gameplay stills for App Store listing prep.
# Uses the iOS Simulator + deterministic -UITestScenario fixtures.
# Physical-device recapture on the ship SHA remains preferred for Connect upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ARTIFACT_DIR="${STORE_SCREENSHOT_DIR:-$ROOT/docs/store_screenshots}"
DERIVED="${STORE_SCREENSHOT_DERIVED:-/tmp/ss-store-screenshots-derived}"
BUNDLE_ID="life.zerostate.surveillancesurvivor"
SETTLE_SECONDS="${SETTLE_SECONDS:-2.5}"
TIP="$(git rev-parse --short HEAD)"

mkdir -p "$ARTIFACT_DIR"
simulator_id="$(bash scripts/select_available_iphone_simulator.sh)"
if [[ -z "$simulator_id" ]]; then
  echo "No iPhone simulator available" >&2
  exit 69
fi

echo "store-screenshots tip=$TIP sim=$simulator_id → $ARTIFACT_DIR"
xcrun simctl boot "$simulator_id" 2>/dev/null || true
xcrun simctl bootstatus "$simulator_id" -b || true

echo "Building Debug-iphonesimulator…"
xcodegen generate >/dev/null
xcodebuild \
  -project SurveillanceSurvivor.xcodeproj \
  -scheme SurveillanceSurvivor \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  build >/tmp/ss-store-shot-build.log 2>&1

app_path="$DERIVED/Build/Products/Debug-iphonesimulator/SurveillanceSurvivor.app"
if [[ ! -d "$app_path" ]]; then
  echo "Build failed; see /tmp/ss-store-shot-build.log" >&2
  exit 70
fi

xcrun simctl uninstall "$simulator_id" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install "$simulator_id" "$app_path"

capture_shot() {
  local name="$1"
  shift
  local out="$ARTIFACT_DIR/${name}.png"
  echo "→ $name ($*)"
  xcrun simctl terminate "$simulator_id" "$BUNDLE_ID" 2>/dev/null || true
  if (( $# > 0 )); then
    xcrun simctl launch "$simulator_id" "$BUNDLE_ID" "$@" >/dev/null
  else
    xcrun simctl launch "$simulator_id" "$BUNDLE_ID" >/dev/null
  fi
  sleep "$SETTLE_SECONDS"
  xcrun simctl io "$simulator_id" screenshot "$out"
  # Normalize to landscape if portrait (same as simulator smoke)
  local w h
  w="$(sips -g pixelWidth "$out" | awk '/pixelWidth/ {print $2}')"
  h="$(sips -g pixelHeight "$out" | awk '/pixelHeight/ {print $2}')"
  if [[ -n "$w" && -n "$h" && "$h" -gt "$w" ]]; then
    sips -r -90 "$out" >/dev/null
  fi
  echo "  wrote $out ($(sips -g pixelWidth "$out" | awk '/pixelWidth/ {print $2}')x$(sips -g pixelHeight "$out" | awk '/pixelHeight/ {print $2}'))"
}

# 1 Title / start menu (real shell, no -UITesting)
capture_shot "01_title_start_menu"

# 2 Mid-run combat (ordinary combat, NYC for city identity)
capture_shot "02_combat_new_york" \
  -UITesting -UITestScenario combat -UITestDistrict newYorkCity

# 3 Upgrade draft
capture_shot "03_upgrade_draft" \
  -UITesting -UITestScenario upgrade

# 4 Distinct city (Atlanta foundation)
capture_shot "04_city_atlanta" \
  -UITesting -UITestScenario combat -UITestDistrict atlanta

# 5 Boss / density pressure
capture_shot "05_boss_density" \
  -UITesting -UITestScenario density -UITestDistrict wichita

# 6 Extraction summary
capture_shot "06_extraction_summary" \
  -UITesting -UITestScenario extraction

python3 - <<PY
import json, hashlib
from pathlib import Path
from datetime import datetime, timezone
root = Path("$ARTIFACT_DIR")
tip = "$TIP"
files = sorted(root.glob("0*.png"))
shots = []
for f in files:
    h = hashlib.sha256(f.read_bytes()).hexdigest()
    shots.append({
        "file": f.name,
        "bytes": f.stat().st_size,
        "sha256": h,
    })
manifest = {
    "schema_version": 1,
    "kind": "app_store_screenshot_candidates",
    "captured_at_utc": datetime.now(timezone.utc).isoformat(),
    "git_tip": tip,
    "platform": "iphonesimulator",
    "bundle_id": "$BUNDLE_ID",
    "configuration": "Debug-iphonesimulator",
    "note": (
        "Truthful gameplay screens from deterministic UITest fixtures / launch shell. "
        "Prefer re-capture on physical iPhone at ship SHA for App Store Connect upload. "
        "Not concept art."
    ),
    "shots": shots,
    "plan": [
        "01_title_start_menu",
        "02_combat_new_york",
        "03_upgrade_draft",
        "04_city_atlanta",
        "05_boss_density",
        "06_extraction_summary",
    ],
}
(root / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(f"manifest: {len(shots)} shots @ {tip}")
PY

echo "Done. Screenshots in $ARTIFACT_DIR"
