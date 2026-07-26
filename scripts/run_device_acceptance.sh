#!/usr/bin/env bash
# Automated mechanical device acceptance:
#   lock → generate → device-smoke → DeviceAcceptanceUITests (force extract) → receipt.
#
# Does NOT claim ART checklist, owner ship note, thermal/haptics, or ART_SHIP_APPROVED.
# Env: DEVICE_UDID (optional), DEVELOPMENT_TEAM (default X9M969D8M3),
#      DEVICE_SUITE_UI_SOFT=1 (partial on UI fail), DEVICE_SUITE_UI_RETRIES.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

export DEVICE_SUITE_ARTIFACTS="${DEVICE_SUITE_ARTIFACTS:-$repo_root/.device-smoke}"
export DEVICE_SUITE_SKIP_UI=0
export DEVICE_ACCEPTANCE_ONLY=1
export DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-X9M969D8M3}"

echo "== Surveillance Survivor device acceptance automation =="
echo "NOTE: Mechanical extract + deploy only. Operator still owns ART sign-off."
exec bash scripts/run_device_suite.sh
