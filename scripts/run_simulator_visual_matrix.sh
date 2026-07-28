#!/usr/bin/env bash
set -euo pipefail

# Deterministic all-city visual matrix. Simulator evidence only.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
artifact_root="${SIMULATOR_VISUAL_MATRIX_ARTIFACTS:-$repo_root/.simulator-visual-matrix}"
districts=(wichita louisville tulsa dayton oakland sanFrancisco columbus newYorkCity losAngeles atlanta)
variants=(combat reduced)

rm -rf "$artifact_root"
mkdir -p "$artifact_root"
cd "$repo_root"

echo "== Surveillance Survivor all-city visual matrix =="
echo "artifacts: $artifact_root"

run_index=0
for variant in "${variants[@]}"; do
  for district in "${districts[@]}"; do
    run_index=$((run_index + 1))
    city_dir="$artifact_root/$variant/$district"
    echo "[$run_index/20] $variant/$district"
    skip=1
    if [[ "$run_index" -eq 1 ]]; then skip=0; fi
    reduced=0
    if [[ "$variant" == "reduced" ]]; then reduced=1; fi
    SIMULATOR_SMOKE_SCENARIO="$variant" \
    SIMULATOR_SMOKE_DISTRICT="$district" \
    SIMULATOR_SMOKE_REDUCED_PRESENTATION="$reduced" \
    SIMULATOR_SMOKE_SKIP_BUILD="$skip" \
    SIMULATOR_SMOKE_ARTIFACTS="$city_dir" \
      bash scripts/run_simulator_smoke.sh
  done
done

python3 - "$artifact_root" "$repo_root/Sources/SurveillanceCore/Resources/Content/districts.json" "${districts[@]}" <<'PY'
import json, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

root, catalog_path = Path(sys.argv[1]), Path(sys.argv[2])
districts = sys.argv[3:]
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
swift scripts/analyze_visual_matrix.swift --self-test
triage_args=("$artifact_root")
if [[ -n "${VISUAL_HISTORY_BASELINE:-}" ]]; then
  triage_args+=("$VISUAL_HISTORY_BASELINE")
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
echo "Matrix receipt: $artifact_root/matrix-receipt.json"
