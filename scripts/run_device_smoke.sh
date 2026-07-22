#!/usr/bin/env bash
set -euo pipefail

# Builds, installs, and foreground-launches the signed development build on one
# physical iPhone. It verifies deployment only; manual acceptance evidence is
# still recorded in docs/DEVICE_TEST_LOG.md.

if [[ $# -ne 1 ]]; then
  echo "Usage: DEVICE_UDID=<connected-iPhone-UDID> make device-smoke" >&2
  exit 64
fi

device_udid="$1"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_path="$repo_root/SurveillanceSurvivor.xcodeproj"
derived_data_path="${DERIVED_DATA_PATH:-$repo_root/.build/device-smoke-derived-data}"
app_path="$derived_data_path/Build/Products/Debug-iphoneos/SurveillanceSurvivor.app"
bundle_identifier="life.zerostate.surveillancesurvivor"

if [[ ! -d "$project_path" ]]; then
  echo "Missing $project_path. Run 'make generate', then select a development team in Xcode once." >&2
  exit 66
fi

# Finder can add extended attributes to a previously built .app. They are not
# source data, but codesign rejects them. The derived-data directory is an
# ephemeral build product, so clearing its metadata is safe and repeatable.
if [[ -d "$derived_data_path" ]]; then
  xattr -cr "$derived_data_path"
fi

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

xcodebuild "${build_args[@]}"

if [[ ! -d "$app_path" ]]; then
  echo "Expected built app at $app_path, but it was not produced." >&2
  exit 70
fi

xcrun devicectl device install app --device "$device_udid" "$app_path"
xcrun devicectl device process launch --device "$device_udid" --terminate-existing "$bundle_identifier"

printf 'Device deployment succeeded: %s (%s)\n' "$bundle_identifier" "$device_udid"
