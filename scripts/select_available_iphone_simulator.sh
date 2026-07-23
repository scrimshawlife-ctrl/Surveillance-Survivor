#!/usr/bin/env bash
set -euo pipefail

# Prints one bootable iPhone Simulator UDID. Prefer already-booted devices, then
# a stable preferred name, then any available iPhone. Used by Make targets, CI,
# and the simulator smoke script.

if ! available_devices="$(xcrun simctl list devices available --json)"; then
  echo "Unable to query the iOS Simulator service. Start Xcode once, then retry." >&2
  exit 69
fi

if ! simulator_id="$(printf '%s' "$available_devices" | python3 -c '
import json
import sys

preferred_names = (
    "iPhone 17 Pro",
    "iPhone 16 Pro",
    "iPhone 15 Pro",
    "iPhone 17",
    "iPhone 16",
    "iPhone 15",
)

devices = [
    device
    for runtime in json.load(sys.stdin)["devices"].values()
    for device in runtime
    if device.get("isAvailable") and device["name"].startswith("iPhone")
]

if not devices:
    print("")
    raise SystemExit(0)

booted = [d for d in devices if d.get("state") == "Booted"]
if booted:
    print(booted[0]["udid"])
    raise SystemExit(0)

by_name = {d["name"]: d for d in devices}
for name in preferred_names:
    if name in by_name:
        print(by_name[name]["udid"])
        raise SystemExit(0)

# Prefer newer runtimes when falling back (devices list order is runtime order).
print(devices[-1]["udid"])
')"; then
  echo "Unable to parse the installed iOS Simulator devices." >&2
  exit 69
fi

if [[ -z "$simulator_id" ]]; then
  echo "No available iPhone simulator found. Install an iOS Simulator runtime in Xcode." >&2
  exit 70
fi

printf '%s\n' "$simulator_id"
