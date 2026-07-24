#!/usr/bin/env bash
# Write a bounded machine-readable emulator evidence receipt.
# Usage: write_emulator_receipt.sh <artifact_dir> <overall_status> [json_fields...]
# Extra args are key=value pairs merged into the receipt.
set -euo pipefail

artifact_dir="${1:?artifact dir required}"
overall_status="${2:?status required}"
shift 2

mkdir -p "$artifact_dir"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
swift_version="$(swift --version 2>/dev/null | head -1 | tr '"' "'")"
xcode_version="$(xcodebuild -version 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')"
started="${EMULATOR_RECEIPT_STARTED_AT:-}"
ended="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
sim_id="${SIMULATOR_UDID:-${SIMULATOR_ID:-unknown}}"

# Prefer relative paths for screenshots when under repo.
screenshot=""
if [[ -f "$artifact_dir/launch.png" ]]; then
  screenshot="launch.png"
fi

receipt="$artifact_dir/emulator-receipt.json"

# Build JSON with python for safe escaping.
python3 - "$receipt" <<'PY' "$@"
import json, os, sys
from pathlib import Path

receipt_path = Path(sys.argv[1])
extra = {}
for arg in sys.argv[2:]:
    if "=" in arg:
        k, v = arg.split("=", 1)
        # coerce bools/ints
        if v in ("true", "false"):
            extra[k] = v == "true"
        else:
            try:
                extra[k] = int(v)
            except ValueError:
                try:
                    extra[k] = float(v)
                except ValueError:
                    extra[k] = v

env = os.environ
payload = {
    "schemaVersion": 1,
    "status": env.get("EMULATOR_RECEIPT_STATUS", "unknown"),
    "commit": env.get("EMULATOR_RECEIPT_COMMIT", "unknown"),
    "swiftVersion": env.get("EMULATOR_RECEIPT_SWIFT", "unknown"),
    "xcodeVersion": env.get("EMULATOR_RECEIPT_XCODE", "unknown"),
    "simulatorId": env.get("EMULATOR_RECEIPT_SIM", "unknown"),
    "startedAt": env.get("EMULATOR_RECEIPT_STARTED_AT") or None,
    "endedAt": env.get("EMULATOR_RECEIPT_ENDED_AT") or None,
    "steps": json.loads(env.get("EMULATOR_RECEIPT_STEPS_JSON", "[]")),
    "screenshot": env.get("EMULATOR_RECEIPT_SCREENSHOT") or None,
    "logFile": "emulator-suite.log",
    "notes": "Simulator evidence only; not physical-device acceptance.",
}
payload.update(extra)
receipt_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
print(receipt_path)
PY
