#!/usr/bin/env python3
"""Validate landmark encounter authority (P9)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "landmark_encounters.json"
INTERACTABLES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "interactables.json"
EXPECTED = "surveillance-survivor/landmark_encounters"


def fail(msg: str) -> None:
    print(f"landmark-check: ERROR: {msg}", file=sys.stderr)
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
    inter = load(INTERACTABLES)
    inter_ids = {i["id"]: i for i in inter.get("interactables", []) if isinstance(i, dict) and "id" in i}

    if data.get("schemaVersion") != 1:
        fail("schemaVersion must be 1")
    if data.get("schemaId") != EXPECTED:
        fail("bad schemaId")
    if data.get("forbidHiddenStatScaling") is not True:
        fail("forbidHiddenStatScaling must be true")
    encounters = data.get("encounters")
    if not isinstance(encounters, list) or not encounters:
        fail("encounters non-empty required")
    seen = set()
    for e in encounters:
        eid = e.get("id")
        if not eid or eid in seen:
            fail(f"bad/duplicate id {eid}")
        seen.add(eid)
        if e.get("districtId") != "wichita" and e.get("districtId") is None:
            pass
        if not (40 < float(e.get("radius", 0)) <= 600):
            fail(f"{eid} radius out of band")
        linked = e.get("linkedInteractableIds") or []
        if len(linked) < 2:
            fail(f"{eid} need ≥2 linked interactables")
        for lid in linked:
            if lid not in inter_ids:
                fail(f"{eid} unknown interactable {lid}")
            if inter_ids[lid].get("districtId") != e.get("districtId"):
                fail(f"{eid} interactable district mismatch {lid}")
        if not e.get("hazardSchedule"):
            fail(f"{eid} hazardSchedule required")
        wi = e.get("whileInside") or {}
        if not (0.5 <= float(wi.get("spawnIntervalMultiplier", 0)) <= 1.5):
            fail(f"{eid} spawnIntervalMultiplier out of band")
        for key in ("opportunity", "cost", "topologyGrammar", "audioMotifId", "artPackageId"):
            if not e.get(key):
                fail(f"{eid} missing {key}")
    print(f"landmark-check: OK schema=v1 encounters={len(encounters)} forbid_hidden_scaling=true")


if __name__ == "__main__":
    main()
