#!/usr/bin/env python3
"""Validate environmental interactables authority (P9)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "interactables.json"
INFRA = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "infrastructure_nodes.json"

EXPECTED_SCHEMA_ID = "surveillance-survivor/interactables"
ALLOWED_FAMILIES = {
    "electrical",
    "communications",
    "access",
    "civilian",
    "response",
    "surveillance",
    "traffic",
    "transit",
    "construction",
}
ALLOWED_ACTIVATION = {"stressInfrastructure"}


def fail(message: str) -> None:
    print(f"interactables-check: ERROR: {message}", file=sys.stderr)
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
    infra = load_json(INFRA)
    nodes_by_district: dict[str, set[str]] = {}
    for graph in infra.get("districtGraphs", []):
        did = graph.get("districtId")
        if not isinstance(did, str):
            continue
        nodes_by_district[did] = {n["id"] for n in graph.get("nodes", []) if isinstance(n, dict) and "id" in n}

    if data.get("schemaVersion") != 1:
        fail("schemaVersion must be 1")
    if data.get("schemaId") != EXPECTED_SCHEMA_ID:
        fail(f"schemaId must be {EXPECTED_SCHEMA_ID}")
    if data.get("forbidHiddenStatScaling") is not True:
        fail("forbidHiddenStatScaling must be true")
    cap = data.get("maxActiveInteractables")
    if not isinstance(cap, int) or not (1 <= cap <= 32):
        fail("maxActiveInteractables out of band")

    items = data.get("interactables")
    if not isinstance(items, list) or not items:
        fail("interactables must be non-empty")
    seen: set[str] = set()
    by_district: dict[str, int] = {}
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            fail(f"interactables[{index}] invalid")
        iid = item.get("id")
        if not isinstance(iid, str) or not iid:
            fail(f"interactables[{index}].id required")
        if iid in seen:
            fail(f"duplicate id {iid}")
        seen.add(iid)
        did = item.get("districtId")
        if not isinstance(did, str) or not did:
            fail(f"{iid}: districtId required")
        by_district[did] = by_district.get(did, 0) + 1
        if item.get("family") not in ALLOWED_FAMILIES:
            fail(f"{iid}: unknown family")
        for key in ("label", "linkedInfrastructureNodeId", "opportunity", "cost"):
            if not isinstance(item.get(key), str) or not item[key]:
                fail(f"{iid}: {key} required")
        pos = item.get("position")
        if not isinstance(pos, dict) or not isinstance(pos.get("x"), (int, float)) or not isinstance(pos.get("y"), (int, float)):
            fail(f"{iid}: position x/y required")
        radius = item.get("radius")
        if not isinstance(radius, (int, float)) or not (0 < radius <= 80):
            fail(f"{iid}: radius out of band")
        tele = item.get("telegraphSeconds")
        cool = item.get("cooldownSeconds")
        if not isinstance(tele, (int, float)) or not (0 <= tele <= 2):
            fail(f"{iid}: telegraphSeconds out of band")
        if not isinstance(cool, (int, float)) or not (0 < cool <= 120):
            fail(f"{iid}: cooldownSeconds out of band")
        act = item.get("activation")
        if not isinstance(act, dict) or act.get("kind") not in ALLOWED_ACTIVATION:
            fail(f"{iid}: activation kind invalid")
        hit = act.get("integrityHit")
        if not isinstance(hit, (int, float)) or not (0.05 <= hit <= 0.5):
            fail(f"{iid}: integrityHit out of band")
        linked = item["linkedInfrastructureNodeId"]
        if did in nodes_by_district and linked not in nodes_by_district[did]:
            fail(f"{iid}: linked node {linked} missing from infrastructure graph for {did}")

    if by_district.get("wichita", 0) < 6:
        fail(f"wichita requires ≥6 interactables, found {by_district.get('wichita', 0)}")

    print(
        f"interactables-check: OK schema=v{data['schemaVersion']} "
        f"count={len(items)} wichita={by_district.get('wichita', 0)} forbid_hidden_scaling=true"
    )


if __name__ == "__main__":
    main()
