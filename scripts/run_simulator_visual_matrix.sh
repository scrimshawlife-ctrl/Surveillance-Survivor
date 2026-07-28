#!/usr/bin/env bash
set -euo pipefail

# Ten-city deterministic visual matrix. Simulator evidence only.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
artifact_root="${SIMULATOR_VISUAL_MATRIX_ARTIFACTS:-$repo_root/.simulator-visual-matrix}"
districts=(wichita louisville tulsa dayton oakland sanFrancisco columbus newYorkCity losAngeles atlanta)

rm -rf "$artifact_root"
mkdir -p "$artifact_root"
cd "$repo_root"

echo "== Surveillance Survivor ten-city visual matrix =="
echo "artifacts: $artifact_root"

for index in "${!districts[@]}"; do
  district="${districts[$index]}"
  city_dir="$artifact_root/$district"
  echo "[$((index + 1))/${#districts[@]}] $district"
  skip=0
  if [[ "$index" -gt 0 ]]; then skip=1; fi
  SIMULATOR_SMOKE_SCENARIO=density \
  SIMULATOR_SMOKE_DISTRICT="$district" \
  SIMULATOR_SMOKE_SKIP_BUILD="$skip" \
  SIMULATOR_SMOKE_ARTIFACTS="$city_dir" \
    bash scripts/run_simulator_smoke.sh
done

python3 - "$artifact_root" "${districts[@]}" <<'PY'
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(sys.argv[1])
districts = sys.argv[2:]
rows = []
errors = []
for district in districts:
    directory = root / district
    receipt_path = directory / "emulator-receipt.json"
    image_path = directory / "launch-landscape.png"
    if not receipt_path.exists() or not image_path.exists():
        errors.append(f"{district}: missing receipt or screenshot")
        continue
    receipt = json.loads(receipt_path.read_text())
    probe = subprocess.check_output(
        ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(image_path)],
        text=True,
    )
    values = {}
    for line in probe.splitlines():
        if ":" in line:
            key, value = line.strip().split(":", 1)
            if key in {"pixelWidth", "pixelHeight"}:
                values[key] = int(value.strip())
    width = values.get("pixelWidth", 0)
    height = values.get("pixelHeight", 0)
    if width <= height or width < 1000 or height < 500:
        errors.append(f"{district}: invalid landscape dimensions {width}x{height}")
    if image_path.stat().st_size < 100_000:
        errors.append(f"{district}: suspiciously small screenshot")
    if receipt.get("status") != "pass":
        errors.append(f"{district}: smoke status is not pass")
    if receipt.get("district") != district:
        errors.append(f"{district}: receipt district is {receipt.get('district')!r}")
    if receipt.get("scenario") != "density":
        errors.append(f"{district}: receipt scenario is {receipt.get('scenario')!r}")
    rows.append({
        "district": district,
        "status": receipt.get("status"),
        "seedContract": f"9000 + campaign level",
        "width": width,
        "height": height,
        "screenshot": f"{district}/launch-landscape.png",
        "receipt": f"{district}/emulator-receipt.json",
    })

payload = {
    "schemaVersion": 1,
    "status": "fail" if errors else "pass",
    "commit": subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], text=True).strip(),
    "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "scenario": "density",
    "expectedDistrictCount": 10,
    "districts": rows,
    "errors": errors,
    "limitations": "Simulator-only; not physical-device ART, thermal, touch, haptic, or audio-route evidence.",
}
(root / "matrix-receipt.json").write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
if errors or len(rows) != 10:
    raise SystemExit("visual matrix failed: " + "; ".join(errors or [f"only {len(rows)} rows"]))
print("visual matrix: PASS (10/10 cities)")
PY

echo "Matrix receipt: $artifact_root/matrix-receipt.json"
