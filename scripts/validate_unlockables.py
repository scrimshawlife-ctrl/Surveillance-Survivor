#!/usr/bin/env python3
"""Validate P11 unlockables catalog (presentation-only, mastery-gated)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "unlockables.json"
EXPECTED = "surveillance-survivor/unlockables"
ALLOWED_KINDS = {"cosmetic", "radioSet", "weatherPack", "audioMotif"}
BANNED = ("damagescale", "healthscale", "hiddendifficulty", "playerdamage", "enemyhealth")


def fail(msg: str) -> None:
    print(f"unlockables-check: ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def load(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {path.relative_to(ROOT)}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON: {exc}")


def main() -> None:
    data = load(PATH)
    if data.get("schemaVersion") != 1:
        fail("schemaVersion must be 1")
    if data.get("schemaId") != EXPECTED:
        fail("bad schemaId")
    if data.get("forbidHiddenStatScaling") is not True:
        fail("forbidHiddenStatScaling must be true")
    items = data.get("items")
    if not isinstance(items, list) or not items:
        fail("items must be non-empty")
    seen = set()
    kinds = set()
    for item in items:
        iid = item.get("id")
        if not iid or iid in seen:
            fail(f"bad/duplicate id {iid}")
        seen.add(iid)
        kind = item.get("kind")
        if kind not in ALLOWED_KINDS:
            fail(f"{iid} bad kind {kind}")
        kinds.add(kind)
        for key in ("requiresTotalExtractions", "requiresChallengeCompletions", "requiresDailyBestStreak"):
            val = item.get(key, 0)
            if not isinstance(val, int) or val < 0:
                fail(f"{iid} {key} must be int ≥0")
        if not item.get("opportunity") or not item.get("cost"):
            fail(f"{iid} needs opportunity and cost")
        if kind == "cosmetic" and not item.get("presentationId"):
            fail(f"{iid} cosmetic needs presentationId")
        if kind == "radioSet" and not item.get("radioLanguage"):
            fail(f"{iid} radioSet needs radioLanguage")
        if kind == "weatherPack" and not item.get("weatherLightingModifier"):
            fail(f"{iid} weatherPack needs weatherLightingModifier")
        if kind == "audioMotif" and not item.get("audioMotifId"):
            fail(f"{iid} audioMotif needs audioMotifId")
        blob = " ".join(
            str(item.get(k) or "")
            for k in (
                "opportunity",
                "cost",
                "presentationId",
                "radioLanguage",
                "weatherLightingModifier",
                "audioMotifId",
            )
        ).lower()
        for ban in BANNED:
            if ban in blob:
                fail(f"{iid} banned language {ban}")
    print(
        f"unlockables-check: OK schema=v1 items={len(items)} "
        f"kinds={sorted(kinds)} forbid_hidden_scaling=true"
    )


if __name__ == "__main__":
    main()
