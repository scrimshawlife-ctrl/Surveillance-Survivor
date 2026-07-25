#!/usr/bin/env python3
"""Validate P10 city systemic rules (rule-level identity, no hidden stat scaling)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "city_systemic_rules.json"
DISTRICTS = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "districts.json"
LANDMARKS = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "landmark_encounters.json"
SYNERGIES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "build_synergies.json"
EXPECTED = "surveillance-survivor/city_systemic_rules"
ALLOWED_STATUS = {"rules_only", "slice_a_projected", "full_p9_proof"}


def fail(msg: str) -> None:
    print(f"city-rules-check: ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def load(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {path.relative_to(ROOT)}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON: {exc}")


def main() -> None:
    data = load(RULES)
    district_ids = {d["id"] for d in load(DISTRICTS).get("districts", [])}
    landmark_ids = {e["id"] for e in load(LANDMARKS).get("encounters", []) if "id" in e}
    families = set(load(SYNERGIES).get("families", []))

    if data.get("schemaVersion") != 1:
        fail("schemaVersion must be 1")
    if data.get("schemaId") != EXPECTED:
        fail("bad schemaId")
    if data.get("forbidHiddenStatScaling") is not True:
        fail("forbidHiddenStatScaling must be true")

    cities = data.get("cities")
    if not isinstance(cities, list) or len(cities) != len(district_ids):
        fail(f"need rules for all {len(district_ids)} districts")
    seen = set()
    for c in cities:
        did = c.get("districtId")
        if not did or did in seen:
            fail(f"bad/duplicate districtId {did}")
        seen.add(did)
        if did not in district_ids:
            fail(f"unknown district {did}")
        for key in (
            "topologyGrammar",
            "infrastructureProfile",
            "weatherLightingModifier",
            "civilianReportingBias",
            "enemyFactionWeighting",
            "radioLanguage",
            "audioMotifId",
            "satiricalPolicyModifier",
            "projectionStatus",
        ):
            if not c.get(key):
                fail(f"{did} missing {key}")
        if c.get("projectionStatus") not in ALLOWED_STATUS:
            fail(f"{did} bad projectionStatus")
        tags = c.get("upgradeWeightingTags") or []
        if not tags:
            fail(f"{did} needs upgradeWeightingTags")
        for t in tags:
            if t not in families:
                fail(f"{did} unknown tag {t}")
        hook = c.get("landmarkHookId")
        if hook and hook not in landmark_ids:
            fail(f"{did} landmarkHookId {hook} missing")
        blob = " ".join(str(c.get(k, "")) for k in c)
        for ban in ("damageScale", "healthScale", "hiddenDifficulty", "hpScale"):
            if ban.lower() in blob.lower():
                fail(f"{did} banned lever language {ban}")
    if seen != district_ids:
        fail(f"coverage mismatch missing={sorted(district_ids - seen)}")

    projected = sum(1 for c in cities if c.get("projectionStatus") != "rules_only")
    print(
        f"city-rules-check: OK schema=v1 cities={len(cities)} "
        f"projected={projected} forbid_hidden_scaling=true"
    )


if __name__ == "__main__":
    main()
