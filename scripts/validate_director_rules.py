#!/usr/bin/env python3
"""Validate Suspicion Director content authority (P8 contract)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "director_rules.json"

EXPECTED_SCHEMA_ID = "surveillance-survivor/director_rules"
FORBIDDEN_DEFAULT = {
    "playerDamageScale",
    "enemyHealthScale",
    "playerHealthScale",
    "hiddenDifficulty",
    "secretStatMultiplier",
}
ALLOWED_LEVER_KEYS = {
    "guardTargetDelta",
    "spawnIntervalMultiplier",
    "sensorCadenceMultiplier",
}


def fail(message: str) -> None:
    print(f"director-check: ERROR: {message}", file=sys.stderr)
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

    interval = data.get("evaluationIntervalTicks")
    if not isinstance(interval, int) or interval <= 0:
        fail("evaluationIntervalTicks must be a positive int")

    max_recent = data.get("maxRecentActions")
    if not isinstance(max_recent, int) or max_recent <= 0:
        fail("maxRecentActions must be a positive int")

    forbidden = data.get("forbiddenLeverKeys")
    if not isinstance(forbidden, list) or not forbidden:
        fail("forbiddenLeverKeys must be a non-empty list")
    forbidden_set = set(forbidden)
    if not FORBIDDEN_DEFAULT.issubset(forbidden_set):
        fail(f"forbiddenLeverKeys must include at least {sorted(FORBIDDEN_DEFAULT)}")

    tiers = data.get("tiers")
    if not isinstance(tiers, list) or len(tiers) != 6:
        fail("tiers must list exactly 6 rows (0...5)")
    tier_ids = []
    for index, tier in enumerate(tiers):
        if not isinstance(tier, dict):
            fail(f"tiers[{index}] must be an object")
        tid = tier.get("tier")
        if not isinstance(tid, int) or tid < 0 or tid > 5:
            fail(f"tiers[{index}].tier must be int 0...5")
        tier_ids.append(tid)
        if not isinstance(tier.get("pressureWindowSeconds"), (int, float)) or tier["pressureWindowSeconds"] <= 0:
            fail(f"tiers[{index}].pressureWindowSeconds must be > 0")
        if not isinstance(tier.get("encounterBudget"), int) or tier["encounterBudget"] < 0:
            fail(f"tiers[{index}].encounterBudget must be int >= 0")
        allowed = tier.get("allowedActionIds")
        if not isinstance(allowed, list) or not allowed:
            fail(f"tiers[{index}].allowedActionIds must be non-empty")
        if not all(isinstance(a, str) and a for a in allowed):
            fail(f"tiers[{index}].allowedActionIds must be non-empty strings")
    if set(tier_ids) != set(range(6)):
        fail(f"tiers must cover 0...5 exactly; found {sorted(tier_ids)}")

    actions = data.get("actions")
    if not isinstance(actions, list) or not actions:
        fail("actions must be a non-empty list")
    action_ids: set[str] = set()
    for index, action in enumerate(actions):
        if not isinstance(action, dict):
            fail(f"actions[{index}] must be an object")
        aid = action.get("id")
        if not isinstance(aid, str) or not aid:
            fail(f"actions[{index}].id must be non-empty")
        if aid in action_ids:
            fail(f"duplicate action id: {aid}")
        action_ids.add(aid)
        if not isinstance(action.get("cooldownSeconds"), (int, float)) or action["cooldownSeconds"] < 0:
            fail(f"actions[{index}].cooldownSeconds must be >= 0")
        if not isinstance(action.get("budgetCost"), int) or action["budgetCost"] < 0:
            fail(f"actions[{index}].budgetCost must be int >= 0")
        if not isinstance(action.get("weight"), int) or action["weight"] <= 0:
            fail(f"actions[{index}].weight must be positive int")
        levers = action.get("levers")
        if not isinstance(levers, dict):
            fail(f"actions[{index}].levers must be an object")
        lever_keys = set(levers.keys())
        unknown = lever_keys - ALLOWED_LEVER_KEYS
        if unknown:
            fail(f"actions[{index}] has unknown lever keys: {sorted(unknown)}")
        collision = lever_keys & forbidden_set
        if collision:
            fail(f"actions[{index}] uses forbidden lever keys: {sorted(collision)}")
        for key in ALLOWED_LEVER_KEYS:
            if key not in levers:
                fail(f"actions[{index}].levers missing {key}")
        delta = levers["guardTargetDelta"]
        spawn_m = levers["spawnIntervalMultiplier"]
        sensor_m = levers["sensorCadenceMultiplier"]
        if not isinstance(delta, int) or not (-4 <= delta <= 6):
            fail(f"actions[{index}].guardTargetDelta out of band")
        if not isinstance(spawn_m, (int, float)) or not (0.25 <= float(spawn_m) <= 2.0):
            fail(f"actions[{index}].spawnIntervalMultiplier out of band")
        if not isinstance(sensor_m, (int, float)) or not (0.25 <= float(sensor_m) <= 2.0):
            fail(f"actions[{index}].sensorCadenceMultiplier out of band")

    for index, tier in enumerate(tiers):
        for aid in tier["allowedActionIds"]:
            if aid not in action_ids:
                fail(f"tiers[{index}] references unknown action {aid}")

    print(
        f"director-check: OK schema=v{data['schemaVersion']} "
        f"tiers={len(tiers)} actions={len(actions)} forbid_hidden_scaling=true"
    )


if __name__ == "__main__":
    main()
