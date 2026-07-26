#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ARTIFACT_DIR="${AUTOMATION_ARTIFACT_DIR:-$ROOT/.automation-test-results}"
REPEAT_COUNT="${AUTOMATION_REPEAT_COUNT:-3}"
RUN_VALIDATORS="${AUTOMATION_RUN_VALIDATORS:-1}"
mkdir -p "$ARTIFACT_DIR"
rm -f "$ARTIFACT_DIR"/*.log "$ARTIFACT_DIR"/*.json

started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
status="passed"
failed_phase=""

run_logged() {
  local phase="$1"
  shift
  echo "==> $phase"
  if ! "$@" 2>&1 | tee "$ARTIFACT_DIR/$phase.log"; then
    status="failed"
    failed_phase="$phase"
    return 1
  fi
}

write_summary() {
  local exit_code="$1"
  local finished_at
  finished_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  python3 - "$ARTIFACT_DIR/summary.json" "$started_at" "$finished_at" "$status" "$failed_phase" "$REPEAT_COUNT" "$exit_code" <<'PY'
import json
import platform
import subprocess
import sys
from pathlib import Path

output, started, finished, status, failed_phase, repeats, exit_code = sys.argv[1:]

def command_version(command):
    try:
        return subprocess.check_output(command, text=True, stderr=subprocess.STDOUT).strip()
    except Exception as exc:
        return f"unavailable: {exc}"

summary = {
    "schema_version": 1,
    "suite": "surveillance-survivor-automation",
    "status": status,
    "failed_phase": failed_phase or None,
    "exit_code": int(exit_code),
    "started_at_utc": started,
    "finished_at_utc": finished,
    "repeat_count": int(repeats),
    "environment": {
        "platform": platform.platform(),
        "python": platform.python_version(),
        "swift": command_version(["swift", "--version"]),
        "git_head": command_version(["git", "rev-parse", "HEAD"]),
    },
}
Path(output).write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
PY
}

trap 'code=$?; if [[ $code -ne 0 ]]; then status="failed"; fi; write_summary "$code"' EXIT

if [[ "$RUN_VALIDATORS" == "1" ]]; then
  run_logged privacy-manifest python3 -c \
    "import pathlib, plistlib; plistlib.load(pathlib.Path('App/PrivacyInfo.xcprivacy').open('rb'))"
  run_logged validators make \
    version-check audio-check weapon-vfx-check animation-check director-check \
    city-state-check build-engine-check coordination-check story-check interactables-check \
    landmark-check clearing-builds-check city-rules-check challenge-contracts-check \
    unlockables-check art-qa-check launch-gate-check
fi

run_logged swift-test swift test --parallel

for iteration in $(seq 1 "$REPEAT_COUNT"); do
  run_logged "automation-invariants-repeat-$iteration" \
    swift test --filter automation
 done

echo "Automation suite passed. Artifacts: $ARTIFACT_DIR"
