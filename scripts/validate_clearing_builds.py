#!/usr/bin/env python3
"""Validate P9 clearing-build proof fixtures."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "clearing_builds.json"
UPGRADES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "upgrades.json"
SYNERGIES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "build_synergies.json"
EXPECTED = "surveillance-survivor/clearing_builds"


def fail(msg: str) -> None:
    print(f"clearing-builds-check: ERROR: {msg}", file=sys.stderr)
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
    upgrades = {u["id"] for u in load(UPGRADES).get("upgrades", []) if "id" in u}
    synergies = {s["id"] for s in load(SYNERGIES).get("synergies", []) if "id" in s}
    if data.get("schemaVersion") != 1:
        fail("schemaVersion must be 1")
    if data.get("schemaId") != EXPECTED:
        fail("bad schemaId")
    if data.get("forbidHiddenStatScaling") is not True:
        fail("forbidHiddenStatScaling must be true")
    builds = data.get("builds")
    if not isinstance(builds, list) or len(builds) < 3:
        fail("need ≥3 builds")
    seen = set()
    strategies = set()
    for b in builds:
        bid = b.get("id")
        if not bid or bid in seen:
            fail(f"bad/duplicate build id {bid}")
        seen.add(bid)
        strat = b.get("strategy")
        if not strat or strat in strategies:
            fail(f"{bid} strategy must be unique")
        strategies.add(strat)
        req = b.get("requiredUpgrades") or []
        if len(req) < 2:
            fail(f"{bid} needs ≥2 upgrades")
        for u in req:
            if u not in upgrades:
                fail(f"{bid} unknown upgrade {u}")
        exp = b.get("expectedSynergies") or []
        if not exp:
            fail(f"{bid} expectedSynergies required")
        for s in exp + (b.get("forbiddenSynergies") or []):
            if s not in synergies:
                fail(f"{bid} unknown synergy {s}")
        if not b.get("readableSummary"):
            fail(f"{bid} readableSummary required")
    print(f"clearing-builds-check: OK schema=v1 builds={len(builds)} forbid_hidden_scaling=true")


if __name__ == "__main__":
    main()
