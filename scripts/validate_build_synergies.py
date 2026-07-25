#!/usr/bin/env python3
"""Validate Emergent Build Engine synergy authority (P8)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "build_synergies.json"
UPGRADES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "upgrades.json"

EXPECTED_SCHEMA_ID = "surveillance-survivor/build_synergies"
EXPECTED_FAMILIES = {
    "signalDisruption",
    "socialCamouflage",
    "bureaucraticWarfare",
    "physicalDisruption",
    "mobilityModification",
    "decoysIdentity",
    "infrastructureParasitism",
    "highSuspicionRisk",
}
ALLOWED_BEHAVIORS = {
    "suspicionRecoveryBoost",
    "observationSoftener",
    "directorBudgetRelief",
}
REQUIRED_FORBIDDEN = {
    "playerDamageScale",
    "enemyHealthScale",
    "playerHealthScale",
    "hiddenDifficulty",
}


def fail(message: str) -> None:
    print(f"build-engine-check: ERROR: {message}", file=sys.stderr)
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
    upgrades_doc = load_json(UPGRADES)
    upgrade_ids = {u["id"] for u in upgrades_doc.get("upgrades", []) if isinstance(u, dict) and "id" in u}
    if not upgrade_ids:
        fail("upgrades.json has no upgrade ids")

    if data.get("schemaVersion") != 1:
        fail("schemaVersion must be 1")
    if data.get("schemaId") != EXPECTED_SCHEMA_ID:
        fail(f"schemaId must be {EXPECTED_SCHEMA_ID}")
    if data.get("forbidHiddenStatScaling") is not True:
        fail("forbidHiddenStatScaling must be true")

    families = data.get("families")
    if not isinstance(families, list) or set(families) != EXPECTED_FAMILIES:
        fail(f"families must equal {sorted(EXPECTED_FAMILIES)}")

    forbidden = data.get("forbiddenBehaviorKinds")
    if not isinstance(forbidden, list) or not REQUIRED_FORBIDDEN.issubset(set(forbidden)):
        fail(f"forbiddenBehaviorKinds must include {sorted(REQUIRED_FORBIDDEN)}")

    tags = data.get("upgradeTags")
    if not isinstance(tags, dict) or set(tags.keys()) != upgrade_ids:
        missing = sorted(upgrade_ids - set(tags.keys() if isinstance(tags, dict) else []))
        extra = sorted(set(tags.keys() if isinstance(tags, dict) else []) - upgrade_ids)
        fail(f"upgradeTags must match upgrades.json exactly; missing={missing} extra={extra}")

    for uid, tag_list in tags.items():
        if not isinstance(tag_list, list) or not tag_list:
            fail(f"upgradeTags[{uid}] must be non-empty list")
        for tag in tag_list:
            if tag not in EXPECTED_FAMILIES:
                fail(f"upgradeTags[{uid}] unknown family {tag}")

    synergies = data.get("synergies")
    if not isinstance(synergies, list) or not synergies:
        fail("synergies must be non-empty")
    seen: set[str] = set()
    for index, synergy in enumerate(synergies):
        if not isinstance(synergy, dict):
            fail(f"synergies[{index}] invalid")
        sid = synergy.get("id")
        if not isinstance(sid, str) or not sid:
            fail(f"synergies[{index}].id required")
        if sid in seen:
            fail(f"duplicate synergy id {sid}")
        seen.add(sid)
        if not isinstance(synergy.get("readableSummary"), str) or not synergy["readableSummary"]:
            fail(f"{sid}: readableSummary required")
        if not isinstance(synergy.get("minimumSelectedUpgrades"), int) or synergy["minimumSelectedUpgrades"] < 1:
            fail(f"{sid}: minimumSelectedUpgrades must be ≥1")
        for key in ("requiredTags", "excludedTags"):
            val = synergy.get(key)
            if not isinstance(val, list):
                fail(f"{sid}: {key} must be list")
            for tag in val:
                if tag not in EXPECTED_FAMILIES:
                    fail(f"{sid}: unknown tag {tag} in {key}")
        mins = synergy.get("minTagCounts")
        if not isinstance(mins, dict):
            fail(f"{sid}: minTagCounts must be object")
        for tag, count in mins.items():
            if tag not in EXPECTED_FAMILIES:
                fail(f"{sid}: unknown minTagCounts key {tag}")
            if not isinstance(count, int) or count < 1:
                fail(f"{sid}: minTagCounts[{tag}] must be int ≥1")
        behavior = synergy.get("behavior")
        if not isinstance(behavior, dict):
            fail(f"{sid}: behavior required")
        kind = behavior.get("kind")
        amount = behavior.get("amount")
        if kind not in ALLOWED_BEHAVIORS:
            fail(f"{sid}: behavior kind {kind} not allowed")
        if kind in REQUIRED_FORBIDDEN or kind in set(forbidden):
            # only fail if kind is in forbidden list and not allowed
            if kind not in ALLOWED_BEHAVIORS:
                fail(f"{sid}: forbidden behavior {kind}")
        if not isinstance(amount, (int, float)) or amount <= 0:
            fail(f"{sid}: amount must be > 0")
        if kind in {"suspicionRecoveryBoost", "observationSoftener"} and amount > 1:
            fail(f"{sid}: amount out of band for {kind}")
        if kind == "directorBudgetRelief" and amount > 3:
            fail(f"{sid}: directorBudgetRelief amount out of band")

    print(
        f"build-engine-check: OK schema=v{data['schemaVersion']} "
        f"upgrades={len(tags)} synergies={len(synergies)} forbid_hidden_scaling=true"
    )


if __name__ == "__main__":
    main()
