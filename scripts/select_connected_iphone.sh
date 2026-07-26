#!/usr/bin/env bash
# Prints one connected physical iPhone hardware UDID for xcodebuild / device-smoke.
# Prefers wired connected devices; fails closed when none are available.
set -euo pipefail

json_path="$(mktemp -t ss-connected-iphone.XXXXXX.json)"
cleanup() { rm -f "$json_path"; }
trap cleanup EXIT

if ! xcrun devicectl list devices --json-output "$json_path" >/dev/null 2>&1; then
  echo "Unable to list CoreDevice devices via devicectl." >&2
  exit 70
fi

python3 - "$json_path" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
devices = (data.get("result") or {}).get("devices") or []
candidates = []
for d in devices:
    hp = d.get("hardwareProperties") or {}
    cp = d.get("connectionProperties") or {}
    if hp.get("deviceType") != "iPhone":
        continue
    if hp.get("reality") not in (None, "physical"):
        # Skip pure simulators if they ever appear here.
        if hp.get("reality") == "virtual":
            continue
    udid = hp.get("udid")
    if not udid:
        continue
    tunnel = (cp.get("tunnelState") or "").lower()
    transport = (cp.get("transportType") or "").lower()
    pairing = (cp.get("pairingState") or "").lower()
    if pairing and pairing != "paired":
        continue
    if tunnel not in ("connected", "available", ""):
        # Prefer live tunnels; skip known-offline.
        if tunnel in ("unavailable", "disconnected", "disconnectedbyhost"):
            continue
    # Rank: wired connected first, then any connected, then the rest.
    rank = 0
    if transport == "wired":
        rank += 20
    if tunnel == "connected":
        rank += 10
    candidates.append((rank, udid, d.get("deviceProperties", {}).get("name") or "iPhone", hp.get("marketingName") or hp.get("productType") or ""))

if not candidates:
    print("No connected physical iPhone found. Plug in a paired device and unlock it.", file=sys.stderr)
    sys.exit(70)

candidates.sort(key=lambda row: (-row[0], row[1]))
udid = candidates[0][1]
# stdout is only the UDID for shell capture; details go to stderr when verbose.
print(udid)
PY
