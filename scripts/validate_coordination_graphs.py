#!/usr/bin/env python3
"""Validate Enemy Coordination Graph authority (P8)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "coordination_graphs.json"

EXPECTED_SCHEMA_ID = "surveillance-survivor/coordination_graphs"
ALLOWED_ADVANCE = {"sensorContact", "timer"}
ALLOWED_INTERRUPT = {"sensorDestroyed", "sensorSpoofed", "sensorDisabled", "guardDisrupted"}
ALLOWED_LEVERS = {"guardTargetDelta", "observationPressureBonus", "spawnIntervalMultiplier"}
REQUIRED_FORBIDDEN = {
    "playerDamageScale",
    "enemyHealthScale",
    "playerHealthScale",
    "hiddenDifficulty",
}


def fail(message: str) -> None:
    print(f"coordination-check: ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {path.relative_to(ROOT)}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path.relative_to(ROOT)}: {exc}")


def main() -> None:
    data = load_json(RULES)
    if data.get("schemaVersion") != 1:
        fail("schemaVersion must be 1")
    if data.get("schemaId") != EXPECTED_SCHEMA_ID:
        fail(f"schemaId must be {EXPECTED_SCHEMA_ID}")
    if data.get("forbidHiddenStatScaling") is not True:
        fail("forbidHiddenStatScaling must be true")
    min_cp = data.get("minimumCounterplayPoints")
    if not isinstance(min_cp, int) or min_cp < 2:
        fail("minimumCounterplayPoints must be int ≥2")
    interval = data.get("evaluationIntervalTicks")
    if not isinstance(interval, int) or interval <= 0:
        fail("evaluationIntervalTicks must be positive int")
    forbidden = data.get("forbiddenLeverKeys")
    if not isinstance(forbidden, list) or not REQUIRED_FORBIDDEN.issubset(set(forbidden)):
        fail(f"forbiddenLeverKeys must include {sorted(REQUIRED_FORBIDDEN)}")

    chains = data.get("chains")
    if not isinstance(chains, list) or not chains:
        fail("chains must be non-empty")
    seen: set[str] = set()
    for c_index, chain in enumerate(chains):
        if not isinstance(chain, dict):
            fail(f"chains[{c_index}] invalid")
        cid = chain.get("id")
        if not isinstance(cid, str) or not cid:
            fail(f"chains[{c_index}].id required")
        if cid in seen:
            fail(f"duplicate chain id {cid}")
        seen.add(cid)
        if not isinstance(chain.get("displayName"), str) or not chain["displayName"]:
            fail(f"{cid}: displayName required")
        if not isinstance(chain.get("districtIds"), list):
            fail(f"{cid}: districtIds must be list")
        links = chain.get("links")
        if not isinstance(links, list) or len(links) < 3:
            fail(f"{cid}: need ≥3 links")
        link_ids: set[str] = set()
        counterplay = 0
        for l_index, link in enumerate(links):
            if not isinstance(link, dict):
                fail(f"{cid} links[{l_index}] invalid")
            lid = link.get("id")
            if not isinstance(lid, str) or not lid:
                fail(f"{cid} links[{l_index}].id required")
            if lid in link_ids:
                fail(f"{cid} duplicate link {lid}")
            link_ids.add(lid)
            for key in ("role", "label"):
                if not isinstance(link.get(key), str) or not link[key]:
                    fail(f"{cid}/{lid} missing {key}")
            advance = link.get("advanceOn")
            interrupt = link.get("interruptOn")
            if not isinstance(advance, list) or not advance:
                fail(f"{cid}/{lid} advanceOn required")
            if not isinstance(interrupt, list):
                fail(f"{cid}/{lid} interruptOn must be list")
            for s in advance:
                if s not in ALLOWED_ADVANCE:
                    fail(f"{cid}/{lid} bad advance {s}")
            for s in interrupt:
                if s not in ALLOWED_INTERRUPT:
                    fail(f"{cid}/{lid} bad interrupt {s}")
            if "timer" in advance:
                t = link.get("timerSeconds")
                if not isinstance(t, (int, float)) or t <= 0:
                    fail(f"{cid}/{lid} timerSeconds required")
            if link.get("counterplay") is True:
                counterplay += 1
            levers = link.get("levers")
            if not isinstance(levers, dict) or set(levers.keys()) != ALLOWED_LEVERS:
                fail(f"{cid}/{lid} levers must be exactly {sorted(ALLOWED_LEVERS)}")
            delta = levers["guardTargetDelta"]
            bonus = levers["observationPressureBonus"]
            mult = levers["spawnIntervalMultiplier"]
            if not isinstance(delta, int) or not (-2 <= delta <= 4):
                fail(f"{cid}/{lid} guardTargetDelta out of band")
            if not isinstance(bonus, (int, float)) or not (0 <= bonus <= 0.5):
                fail(f"{cid}/{lid} observationPressureBonus out of band")
            if not isinstance(mult, (int, float)) or not (0.5 <= mult <= 1.5):
                fail(f"{cid}/{lid} spawnIntervalMultiplier out of band")
        if counterplay < min_cp:
            fail(f"{cid}: need ≥{min_cp} counterplay links, found {counterplay}")

    print(
        f"coordination-check: OK schema=v{data['schemaVersion']} "
        f"chains={len(chains)} min_counterplay={min_cp} forbid_hidden_scaling=true"
    )


if __name__ == "__main__":
    main()
