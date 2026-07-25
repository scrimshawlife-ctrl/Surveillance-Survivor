#!/usr/bin/env python3
"""Validate Run Story Compiler fact rules (P8)."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "story_fact_rules.json"

EXPECTED_SCHEMA_ID = "surveillance-survivor/story_fact_rules"
ALLOWED_EVIDENCE = {
    "extractionCompleted",
    "playerDefeated",
    "eventKindPresent",
    "minDeaths",
    "minSelectedUpgrades",
    "minBuildSynergies",
    "minDirectorDecisions",
    "minCityStateEvents",
    "minCoordinationInterrupted",
    "minCoordinationCompleted",
    "minPeakSuspicion",
}
ALLOWED_PLACEHOLDERS = {"{district}", "{count}", "{peak}", "{synergyList}", "{seed}"}
PLACEHOLDER_RE = re.compile(r"\{[a-zA-Z]+\}")


def fail(message: str) -> None:
    print(f"story-check: ERROR: {message}", file=sys.stderr)
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
    if data.get("forbidInventedNarrative") is not True:
        fail("forbidInventedNarrative must be true")
    max_lines = data.get("maxSummaryLines")
    if not isinstance(max_lines, int) or not (1 <= max_lines <= 12):
        fail("maxSummaryLines must be int 1...12")

    rules = data.get("rules")
    if not isinstance(rules, list) or not rules:
        fail("rules must be non-empty")
    seen: set[str] = set()
    for index, rule in enumerate(rules):
        if not isinstance(rule, dict):
            fail(f"rules[{index}] invalid")
        rid = rule.get("id")
        if not isinstance(rid, str) or not rid:
            fail(f"rules[{index}].id required")
        if rid in seen:
            fail(f"duplicate rule id {rid}")
        seen.add(rid)
        if not isinstance(rule.get("priority"), int):
            fail(f"{rid}: priority must be int")
        if not isinstance(rule.get("template"), str) or not rule["template"]:
            fail(f"{rid}: template required")
        if not isinstance(rule.get("category"), str) or not rule["category"]:
            fail(f"{rid}: category required")
        for ph in PLACEHOLDER_RE.findall(rule["template"]):
            if ph not in ALLOWED_PLACEHOLDERS:
                fail(f"{rid}: unknown placeholder {ph}")
        evidence = rule.get("evidence")
        if not isinstance(evidence, dict):
            fail(f"{rid}: evidence required")
        kind = evidence.get("kind")
        if kind not in ALLOWED_EVIDENCE:
            fail(f"{rid}: unknown evidence kind {kind}")
        if kind in {"extractionCompleted", "playerDefeated"} and not isinstance(evidence.get("equals"), bool):
            fail(f"{rid}: equals bool required")
        if kind == "eventKindPresent" and not evidence.get("eventKind"):
            fail(f"{rid}: eventKind required")
        if kind == "minDeaths" and (not evidence.get("entityKind") or not isinstance(evidence.get("minimum"), (int, float))):
            fail(f"{rid}: entityKind + minimum required")
        if kind.startswith("min") and kind != "minDeaths":
            m = evidence.get("minimum")
            if not isinstance(m, (int, float)) or m < 1:
                fail(f"{rid}: minimum ≥1 required")

    print(
        f"story-check: OK schema=v{data['schemaVersion']} "
        f"rules={len(rules)} forbid_invented_narrative=true"
    )


if __name__ == "__main__":
    main()
