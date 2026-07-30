#!/usr/bin/env bash
set -euo pipefail

# Deterministic all-city visual matrix. Simulator evidence only.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
artifact_root="${SIMULATOR_VISUAL_MATRIX_ARTIFACTS:-$repo_root/.simulator-visual-matrix}"
derived_data_path="${DERIVED_DATA_PATH:-/private/tmp/surveillance-survivor-simulator-smoke-derived-data}"
worker_count="${SIMULATOR_VISUAL_MATRIX_WORKERS:-1}"
matrix_settle_seconds="${SIMULATOR_VISUAL_MATRIX_SETTLE_SECONDS:-1}"
districts=(wichita louisville tulsa dayton oakland sanFrancisco columbus newYorkCity losAngeles atlanta)
variants=(combat reduced)

if ! [[ "$worker_count" =~ ^[1-4]$ ]]; then
  echo "SIMULATOR_VISUAL_MATRIX_WORKERS must be between 1 and 4" >&2
  exit 64
fi
if ! [[ "$matrix_settle_seconds" =~ ^[1-9][0-9]*$ ]]; then
  echo "SIMULATOR_VISUAL_MATRIX_SETTLE_SECONDS must be a positive integer" >&2
  exit 64
fi

rm -rf "$artifact_root"
mkdir -p "$artifact_root"
cd "$repo_root"

echo "== Surveillance Survivor all-city visual matrix =="
echo "artifacts: $artifact_root"
echo "workers: $worker_count"
echo "settle seconds: $matrix_settle_seconds"

base_simulator_id="${SIMULATOR_UDID:-$(bash scripts/select_available_iphone_simulator.sh)}"
echo "base simulator: $base_simulator_id"
xcodegen generate
xcrun simctl boot "$base_simulator_id" 2>/dev/null || true
worker_ids=("$base_simulator_id")
created_ids=()
worker_pids=()
cleanup_workers() {
  local id pid
  # Bash 3.2 (the macOS system shell) raises "unbound variable" for an empty
  # declared array under `set -u`. The `+` form expands to zero arguments when
  # empty while preserving every element once workers exist.
  for pid in "${worker_pids[@]+"${worker_pids[@]}"}"; do
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
  for id in "${created_ids[@]+"${created_ids[@]}"}"; do
    xcrun simctl shutdown "$id" 2>/dev/null || true
    xcrun simctl delete "$id" 2>/dev/null || true
  done
}
trap cleanup_workers EXIT
trap 'exit 130' INT TERM

if [[ "$worker_count" -gt 1 ]]; then
  # Create clean replicas with the exact runtime/device type of the base. This
  # preserves viewport identity without copying several GiB of simulator data.
  worker_metadata="$(xcrun simctl list devices available --json | python3 -c '
import json, sys
base = sys.argv[1]
data = json.load(sys.stdin)["devices"]
for runtime, devices in data.items():
    for device in devices:
        if device["udid"] == base:
            print(device["deviceTypeIdentifier"] + "\t" + runtime)
            raise SystemExit(0)
raise SystemExit(f"base simulator not found: {base}")
' "$base_simulator_id")"
  IFS=$'\t' read -r worker_device_type worker_runtime <<< "$worker_metadata"
  clone_index=1
  while [[ "$clone_index" -lt "$worker_count" ]]; do
    clone_name="Surveillance Visual Worker ${clone_index} $$"
    clone_id="$(xcrun simctl create "$clone_name" "$worker_device_type" "$worker_runtime")"
    created_ids+=("$clone_id")
    worker_ids+=("$clone_id")
    xcrun simctl boot "$clone_id" 2>/dev/null || true
    clone_index=$((clone_index + 1))
  done
fi

xcrun simctl bootstatus "$base_simulator_id" -b
echo "Building shared simulator app while replica workers boot..."
xcodebuild \
  -project "$repo_root/SurveillanceSurvivor.xcodeproj" \
  -scheme SurveillanceSurvivor \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$base_simulator_id" \
  -derivedDataPath "$derived_data_path" \
  CODE_SIGNING_ALLOWED=NO \
  -quiet \
  build

for simulator_id in "${worker_ids[@]}"; do
  xcrun simctl bootstatus "$simulator_id" -b
done

task_variants=()
task_districts=()
for variant in "${variants[@]}"; do
  for district in "${districts[@]}"; do
    task_variants+=("$variant")
    task_districts+=("$district")
  done
done

run_worker() {
  local worker_index="$1" simulator_id="$2" task_index variant district reduced skip_install city_dir
  skip_install=0
  task_index="$worker_index"
  while [[ "$task_index" -lt "${#task_variants[@]}" ]]; do
    variant="${task_variants[$task_index]}"
    district="${task_districts[$task_index]}"
    city_dir="$artifact_root/$variant/$district"
    reduced=0
    if [[ "$variant" == "reduced" ]]; then reduced=1; fi
    echo "[$((task_index + 1))/20 worker=$((worker_index + 1))] $variant/$district"
    SIMULATOR_UDID="$simulator_id" \
    DERIVED_DATA_PATH="$derived_data_path" \
    SIMULATOR_SMOKE_SCENARIO="$variant" \
    SIMULATOR_SMOKE_DISTRICT="$district" \
    SIMULATOR_SMOKE_REDUCED_PRESENTATION="$reduced" \
    SIMULATOR_SMOKE_SETTLE_SECONDS="$matrix_settle_seconds" \
    SIMULATOR_SMOKE_SKIP_BUILD=1 \
    SIMULATOR_SMOKE_SKIP_INSTALL="$skip_install" \
    SIMULATOR_SMOKE_ARTIFACTS="$city_dir" \
      bash scripts/run_simulator_smoke.sh
    skip_install=1
    task_index=$((task_index + worker_count))
  done
}

worker_index=0
while [[ "$worker_index" -lt "$worker_count" ]]; do
  run_worker "$worker_index" "${worker_ids[$worker_index]}" &
  worker_pids+=("$!")
  worker_index=$((worker_index + 1))
done
worker_failed=0
for worker_pid in "${worker_pids[@]+"${worker_pids[@]}"}"; do
  if ! wait "$worker_pid"; then worker_failed=1; fi
done
worker_pids=()
if [[ "$worker_failed" -ne 0 ]]; then
  echo "One or more visual matrix workers failed" >&2
  exit 75
fi

python3 - "$artifact_root" "$repo_root/Sources/SurveillanceCore/Resources/Content/districts.json" "$worker_count" "$matrix_settle_seconds" "${districts[@]}" <<'PY'
import json, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

root, catalog_path = Path(sys.argv[1]), Path(sys.argv[2])
worker_count, settle_seconds = int(sys.argv[3]), int(sys.argv[4])
districts = sys.argv[5:]
variants = ("combat", "reduced")
catalog = json.loads(catalog_path.read_text())
definitions = {row["id"]: row for row in catalog["districts"]}
rows, errors = [], []
expected_ids = set(districts)
if set(definitions) != expected_ids:
    errors.append("district catalog IDs do not match the ten-city matrix")
if len({definitions[d]["cityName"] for d in districts}) != 10:
    errors.append("city names are not unique")
if len({definitions[d]["title"] for d in districts}) != 10:
    errors.append("city titles are not unique")

for variant in variants:
    for district in districts:
        directory = root / variant / district
        receipt_path = directory / "emulator-receipt.json"
        image_path = directory / "launch-landscape.png"
        if not receipt_path.exists() or not image_path.exists():
            errors.append(f"{variant}/{district}: missing receipt or screenshot")
            continue
        receipt = json.loads(receipt_path.read_text())
        probe = subprocess.check_output(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(image_path)], text=True)
        values = {line.strip().split(":", 1)[0]: line.strip().split(":", 1)[1].strip() for line in probe.splitlines() if ":" in line}
        width, height = int(values.get("pixelWidth", 0)), int(values.get("pixelHeight", 0))
        if width <= height or width < 1000 or height < 500:
            errors.append(f"{variant}/{district}: invalid landscape dimensions {width}x{height}")
        if image_path.stat().st_size < 100_000:
            errors.append(f"{variant}/{district}: suspiciously small screenshot")
        expected_reduced = variant == "reduced"
        checks = {
            "status": receipt.get("status") == "pass",
            "district": receipt.get("district") == district,
            "scenario": receipt.get("scenario") == variant,
            "reducedPresentation": receipt.get("reducedPresentation") is expected_reduced,
        }
        for name, passed in checks.items():
            if not passed: errors.append(f"{variant}/{district}: {name} mismatch")
        definition = definitions[district]
        rows.append({
            "variant": variant, "district": district,
            "cityName": definition["cityName"], "title": definition["title"],
            "signatureMechanic": definition["signatureMechanic"], "bossName": definition["bossName"],
            "seedContract": "8000 + campaign level", "reducedMotion": expected_reduced,
            "reducedFlash": expected_reduced, "width": width, "height": height,
            "screenshot": f"{variant}/{district}/launch-landscape.png",
            "receipt": f"{variant}/{district}/emulator-receipt.json",
        })

payload = {
    "schemaVersion": 2, "status": "fail" if errors else "pass",
    "commit": subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], text=True).strip(),
    "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "variants": list(variants), "expectedDistrictCount": 10, "expectedPanelCount": 20,
    "execution": {"workerCount": worker_count, "settleSeconds": settle_seconds,
                  "sharedBuild": True, "installCount": worker_count},
    "panels": rows, "errors": errors,
    "limitations": "Simulator-only; not physical-device ART, thermal, touch, haptic, or audio-route evidence.",
}
(root / "matrix-receipt.json").write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
if errors or len(rows) != 20:
    raise SystemExit("visual matrix failed: " + "; ".join(errors or [f"only {len(rows)} panels"]))
print("visual matrix semantic checks: PASS (20/20 panels)")
PY

contact_args=("$artifact_root/contact-sheet.jpg")
for variant in "${variants[@]}"; do
  for district in "${districts[@]}"; do
    contact_args+=("$variant · $district" "$artifact_root/$variant/$district/launch-landscape.png")
  done
done
swift scripts/generate_visual_contact_sheet.swift "${contact_args[@]}"
[[ -s "$artifact_root/contact-sheet.jpg" ]] || { echo "Missing contact sheet" >&2; exit 72; }
python3 scripts/qa_artifact_schemas.py matrix "$artifact_root/matrix-receipt.json"
swift scripts/analyze_visual_matrix.swift --self-test
triage_args=("$artifact_root")
# CI always exports VISUAL_HISTORY_BASELINE, but the file only exists once a prior
# run has cached one. Requiring it whenever the variable is merely *set* self-locks
# the gate: a failed run saves no cache, so the next run fails on the missing
# baseline and can never recover. The analyzer already treats an absent baseline as
# "no-baseline", so match that and only validate a file that is actually there.
if [[ -n "${VISUAL_HISTORY_BASELINE:-}" && -f "${VISUAL_HISTORY_BASELINE}" ]]; then
  python3 scripts/qa_artifact_schemas.py history "$VISUAL_HISTORY_BASELINE"
  triage_args+=("$VISUAL_HISTORY_BASELINE")
elif [[ -n "${VISUAL_HISTORY_BASELINE:-}" ]]; then
  echo "No prior visual history at $VISUAL_HISTORY_BASELINE; establishing a new baseline."
fi
swift scripts/analyze_visual_matrix.swift "${triage_args[@]}"
[[ -s "$artifact_root/visual-triage.json" && -s "$artifact_root/visual-triage.md" && -s "$artifact_root/visual-trend.json" && -s "$artifact_root/visual-trend.md" && -s "$artifact_root/anomaly-review.json" && -s "$artifact_root/anomaly-review.md" && -s "$artifact_root/anomaly-review.html" ]] || {
  echo "Missing visual triage summaries" >&2
  exit 73
}
python3 scripts/generate_qa_evidence_index.py "$artifact_root" qa/non-device-baseline.json "$repo_root"
[[ -s "$artifact_root/qa-index.json" && -s "$artifact_root/qa-index.md" && -s "$artifact_root/qa-index.html" ]] || {
  echo "Missing unified QA evidence index" >&2
  exit 74
}
python3 scripts/validate_qa_artifacts.py "$artifact_root" --baseline qa/non-device-baseline.json
echo "Matrix receipt: $artifact_root/matrix-receipt.json"
