#!/usr/bin/env python3
"""Validate P11 challenge contracts (explicit mutators only, no hidden stat scaling)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "challenge_contracts.json"
SYNERGIES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "build_synergies.json"
EXPECTED = "surveillance-survivor/challenge_contracts"
ALLOWED_KINDS = {
    "observationPressureBonus",
    "spawnIntervalMultiplier",
    "guardTargetDelta",
    "extraUpgradeWeightingTag",
}
FORBIDDEN = {
    "playerDamageScale",
    "enemyHealthScale",
    "playerHealthScale",
    "hiddenDifficulty",
    "damageScale",
    "healthScale",
}


def fail(msg: str) -> None:
    print(f"challenge-contracts-check: ERROR: {msg}", file=sys.stderr)
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
    families = set(load(SYNERGIES).get("families", []))
    if data.get("schemaVersion") != 1:
        fail("schemaVersion must be 1")
    if data.get("schemaId") != EXPECTED:
        fail("bad schemaId")
    if data.get("forbidHiddenStatScaling") is not True:
        fail("forbidHiddenStatScaling must be true")
    contracts = data.get("contracts")
    if not isinstance(contracts, list) or len(contracts) < 3:
        fail("need ≥3 contracts")
    seen = set()
    kinds = set()
    for c in contracts:
        cid = c.get("id")
        if not cid or cid in seen:
            fail(f"bad/duplicate contract id {cid}")
        seen.add(cid)
        kind = c.get("kind")
        if kind not in {"daily", "weekly"}:
            fail(f"{cid} kind must be daily|weekly")
        kinds.add(kind)
        mutators = c.get("mutators") or []
        if not mutators:
            fail(f"{cid} needs mutators")
        mids = set()
        for m in mutators:
            mid = m.get("id")
            if not mid or mid in mids:
                fail(f"{cid} bad mutator id {mid}")
            mids.add(mid)
            mk = m.get("kind")
            if mk in FORBIDDEN:
                fail(f"{cid} forbidden mutator {mk}")
            if mk not in ALLOWED_KINDS:
                fail(f"{cid} unknown mutator {mk}")
            if mk == "extraUpgradeWeightingTag":
                tag = m.get("tag")
                if tag not in families:
                    fail(f"{cid} tag {tag} not a build family")
            if mk == "observationPressureBonus":
                amt = m.get("amount")
                if not isinstance(amt, (int, float)) or not (0 <= amt <= 0.25):
                    fail(f"{cid} observation out of band")
            if mk == "spawnIntervalMultiplier":
                amt = m.get("amount")
                if not isinstance(amt, (int, float)) or not (0.5 <= amt <= 1.5):
                    fail(f"{cid} spawn multiplier out of band")
            if mk == "guardTargetDelta":
                amt = m.get("amount")
                if not isinstance(amt, (int, float)) or not (-2 <= amt <= 3):
                    fail(f"{cid} guard delta out of band")
        if not c.get("opportunity") or not c.get("cost"):
            fail(f"{cid} needs opportunity and cost")
    if "daily" not in kinds or "weekly" not in kinds:
        fail("need at least one daily and one weekly contract")
    print(
        f"challenge-contracts-check: OK schema=v1 contracts={len(contracts)} "
        f"kinds={sorted(kinds)} forbid_hidden_scaling=true"
    )


if __name__ == "__main__":
    main()
