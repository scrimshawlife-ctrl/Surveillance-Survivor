#!/usr/bin/env bash
# Pull surveillance.latestRunReceipt from a connected physical iPhone app container.
# Does not invent live-extract status — prints honesty heuristics for the operator/agent.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUNDLE_ID="${BUNDLE_ID:-life.zerostate.surveillancesurvivor}"
DEVICE_UDID="${1:-${DEVICE_UDID:-$(bash scripts/select_connected_iphone.sh)}}"
OUT_DIR="${RECEIPT_PULL_DIR:-/tmp/ss-device-receipt-pull}"
TIP="$(git rev-parse --short HEAD)"

if [[ -z "$DEVICE_UDID" ]]; then
  echo "No connected iPhone (set DEVICE_UDID=…)." >&2
  exit 69
fi

mkdir -p "$OUT_DIR"
plist="$OUT_DIR/prefs.plist"
json_out="$OUT_DIR/latest_run_receipt.json"
summary_out="$OUT_DIR/receipt_summary.json"

xcrun devicectl device copy from \
  --device "$DEVICE_UDID" \
  --domain-type appDataContainer \
  --domain-identifier "$BUNDLE_ID" \
  --source "Library/Preferences/${BUNDLE_ID}.plist" \
  --destination "$plist" \
  --json-output "$OUT_DIR/copy.json" >/dev/null

python3 - "$plist" "$json_out" "$summary_out" "$TIP" "$DEVICE_UDID" <<'PY'
import json, plistlib, sys
from pathlib import Path

plist_path, json_out, summary_out, tip, udid = sys.argv[1:6]
data = plistlib.loads(Path(plist_path).read_bytes())
raw = data.get("surveillance.latestRunReceipt")
if raw is None:
    print("No surveillance.latestRunReceipt in app prefs.", file=sys.stderr)
    sys.exit(70)
if isinstance(raw, bytes):
    envelope = json.loads(raw.decode("utf-8"))
else:
    envelope = json.loads(raw)

Path(json_out).write_text(json.dumps(envelope, indent=2) + "\n", encoding="utf-8")
receipt = envelope.get("receipt") if isinstance(envelope, dict) else None
core = (receipt or envelope).get("core") if isinstance(receipt or envelope, dict) else {}
if not isinstance(core, dict):
    core = {}

elapsed = float(core.get("elapsedSeconds") or 0)
ticks = int(core.get("elapsedTicks") or 0)
extracted = bool(core.get("extractionCompleted"))
damage = float(core.get("damageDealt") or 0)
# Heuristic: force-extract / UITest path is near-instant with no combat.
likely_force = extracted and elapsed < 2.0 and ticks <= 5 and damage <= 0

summary = {
    "schemaVersion": 1,
    "kind": "device-receipt-pull",
    "headTipAtPull": tip,
    "deviceUdid": udid,
    "extractionCompleted": extracted,
    "district": core.get("district"),
    "seed": core.get("seed"),
    "elapsedSeconds": elapsed,
    "elapsedTicks": ticks,
    "damageDealt": damage,
    "damageTaken": core.get("damageTaken"),
    "storySummary": core.get("storySummary"),
    "likelyForceExtractOrFixture": likely_force,
    "honestLiveExtractCandidate": extracted and not likely_force,
    "receiptPath": json_out,
}
Path(summary_out).write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
print(json.dumps(summary, indent=2))
if likely_force:
    print(
        "NOTE: receipt looks like force-extract / fixture (not live play).",
        file=sys.stderr,
    )
elif extracted:
    print("NOTE: receipt looks like a live extract candidate.", file=sys.stderr)
else:
    print("NOTE: extractionCompleted is false.", file=sys.stderr)
PY

echo "Wrote: $json_out"
echo "Summary: $summary_out"
