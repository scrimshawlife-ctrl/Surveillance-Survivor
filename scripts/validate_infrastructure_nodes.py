#!/usr/bin/env python3
"""Validate Dynamic City State infrastructure graph authority (P8)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / "Sources" / "SurveillanceCore" / "Resources" / "Content" / "infrastructure_nodes.json"

EXPECTED_SCHEMA_ID = "surveillance-survivor/infrastructure_nodes"
EXPECTED_FAMILIES = {
    "surveillanceSensors",
    "electricalPower",
    "communicationsFiber",
    "trafficControl",
    "accessControl",
    "transitSystems",
    "civilianReporting",
    "emergencyResponse",
}
EXPECTED_RELATIONS = {
    "powers",
    "carriesSignal",
    "routesThrough",
    "reportsTo",
    "reinforces",
}


def fail(message: str) -> None:
    print(f"city-state-check: ERROR: {message}", file=sys.stderr)
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

    families = data.get("nodeFamilies")
    if not isinstance(families, list) or set(families) != EXPECTED_FAMILIES:
        fail(f"nodeFamilies must equal {sorted(EXPECTED_FAMILIES)}")
    relations = data.get("relationKinds")
    if not isinstance(relations, list) or set(relations) != EXPECTED_RELATIONS:
        fail(f"relationKinds must equal {sorted(EXPECTED_RELATIONS)}")

    degraded = data.get("degradedThreshold")
    offline = data.get("offlineThreshold")
    if not isinstance(degraded, (int, float)) or not isinstance(offline, (int, float)):
        fail("thresholds must be numbers")
    if not (0 <= offline < degraded <= 1):
        fail("require 0 <= offlineThreshold < degradedThreshold <= 1")

    hit = data.get("sensorDestroyIntegrityHit")
    if not isinstance(hit, (int, float)) or not (0 < hit <= 1):
        fail("sensorDestroyIntegrityHit must be in (0...1]")

    depth = data.get("maxPropagationDepth")
    if not isinstance(depth, int) or not (1 <= depth <= 8):
        fail("maxPropagationDepth must be int 1...8")

    graphs = data.get("districtGraphs")
    if not isinstance(graphs, list) or not graphs:
        fail("districtGraphs must be non-empty")

    seen_districts: set[str] = set()
    for g_index, graph in enumerate(graphs):
        if not isinstance(graph, dict):
            fail(f"districtGraphs[{g_index}] must be an object")
        did = graph.get("districtId")
        if not isinstance(did, str) or not did:
            fail(f"districtGraphs[{g_index}].districtId required")
        if did in seen_districts:
            fail(f"duplicate districtId {did}")
        seen_districts.add(did)
        if not isinstance(graph.get("displayName"), str) or not graph["displayName"]:
            fail(f"{did}: displayName required")

        nodes = graph.get("nodes")
        if not isinstance(nodes, list) or len(nodes) < 3:
            fail(f"{did}: need ≥3 nodes")
        node_ids: set[str] = set()
        fams: set[str] = set()
        for n_index, node in enumerate(nodes):
            if not isinstance(node, dict):
                fail(f"{did} nodes[{n_index}] invalid")
            nid = node.get("id")
            if not isinstance(nid, str) or not nid:
                fail(f"{did} nodes[{n_index}].id required")
            if nid in node_ids:
                fail(f"{did} duplicate node {nid}")
            node_ids.add(nid)
            fam = node.get("family")
            if fam not in EXPECTED_FAMILIES:
                fail(f"{did} node {nid} unknown family {fam}")
            fams.add(fam)
            integ = node.get("integrity")
            if not isinstance(integ, (int, float)) or not (0 <= integ <= 1):
                fail(f"{did} node {nid} integrity out of band")
            for key in ("label", "opportunityOnOffline", "costOnOffline"):
                if not isinstance(node.get(key), str) or not node[key]:
                    fail(f"{did} node {nid} missing {key}")
        if len(fams) < 3:
            fail(f"{did}: need ≥3 distinct families")

        edges = graph.get("edges")
        if not isinstance(edges, list) or not edges:
            fail(f"{did}: need ≥1 edge")
        for e_index, edge in enumerate(edges):
            if not isinstance(edge, dict):
                fail(f"{did} edges[{e_index}] invalid")
            frm, to = edge.get("from"), edge.get("to")
            if frm not in node_ids or to not in node_ids:
                fail(f"{did} edges[{e_index}] unknown endpoint")
            if frm == to:
                fail(f"{did} edges[{e_index}] self-edge forbidden")
            if edge.get("relation") not in EXPECTED_RELATIONS:
                fail(f"{did} edges[{e_index}] bad relation")
            weight = edge.get("propagationWeight")
            if not isinstance(weight, (int, float)) or not (0 <= weight <= 1):
                fail(f"{did} edges[{e_index}] weight out of band")

    print(
        f"city-state-check: OK schema=v{data['schemaVersion']} "
        f"districts={len(graphs)} families={len(EXPECTED_FAMILIES)} forbid_hidden_scaling=true"
    )


if __name__ == "__main__":
    main()
