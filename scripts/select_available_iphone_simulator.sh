#!/usr/bin/env bash
set -euo pipefail

# Prints one bootable iPhone Simulator UDID. Keep simulator selection outside
# the project files so local Make targets and CI behave identically as Xcode
# runner device names change.

if ! available_devices="$(xcrun simctl list devices available --json)"; then
  echo "Unable to query the iOS Simulator service. Start Xcode once, then retry." >&2
  exit 69
fi

if ! simulator_id="$(printf '%s' "$available_devices" | python3 -c '
import json
import sys

devices = [
    device
    for runtime in json.load(sys.stdin)["devices"].values()
    for device in runtime
    if device.get("isAvailable") and device["name"].startswith("iPhone")
]
print(devices[0]["udid"] if devices else "")
')"; then
  echo "Unable to parse the installed iOS Simulator devices." >&2
  exit 69
fi

if [[ -z "$simulator_id" ]]; then
  echo "No available iPhone simulator found. Install an iOS Simulator runtime in Xcode." >&2
  exit 70
fi

printf '%s\n' "$simulator_id"
