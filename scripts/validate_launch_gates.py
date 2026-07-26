#!/usr/bin/env python3
"""Validate docs/launch/launch_gates.json honesty. See design 2026-07-26.

Exit 0 means the file is honest (schema + evidence rules hold). overall may still
be LAUNCH_BLOCKED. Exit 1 means lying or malformed data.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any

REQUIRED_GATE_IDS = [
    "device_acceptance",
    "art_ship",
    "store_metadata",
    "audio_product",
    "testflight_rc",
]
# Alias expected by task interface / callers.
REQUIRED_GATES = REQUIRED_GATE_IDS

STATUSES = {"BLOCKED", "EVIDENCE_INSUFFICIENT", "READY", "N_A"}
OWNERS = {"operator", "owner", "shared"}

ART_APPROVED = {
    "ART_SHIP_APPROVED",
    "ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES",
}
ART_BLOCKING = {
    "ART_EVIDENCE_INSUFFICIENT",
    "ART_SHIP_BLOCKED",
}


def derive_overall(data: dict[str, Any]) -> str:
    """LAUNCH_READY only when every required gate is READY or N_A."""
    gates = data.get("gates") or {}
    if not isinstance(gates, dict):
        return "LAUNCH_BLOCKED"
    for gid in REQUIRED_GATE_IDS:
        gate = gates.get(gid)
        if not isinstance(gate, dict):
            return "LAUNCH_BLOCKED"
        status = gate.get("status")
        if status not in ("READY", "N_A"):
            return "LAUNCH_BLOCKED"
    return "LAUNCH_READY"


def _schema_errors(data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    version = data.get("schema_version")
    if not isinstance(version, int) or version < 1:
        errors.append(
            f"SCHEMA: schema_version must be int >= 1, got {version!r}"
        )

    gates = data.get("gates")
    if not isinstance(gates, dict):
        errors.append("SCHEMA: gates must be an object")
        return errors

    for gid in REQUIRED_GATE_IDS:
        if gid not in gates:
            errors.append(f"SCHEMA: missing required gate {gid}")

    for gid, gate in gates.items():
        if not isinstance(gate, dict):
            errors.append(f"SCHEMA: gate={gid} must be an object")
            continue
        status = gate.get("status")
        if status not in STATUSES:
            errors.append(
                f"SCHEMA: gate={gid} status must be one of {sorted(STATUSES)}, "
                f"got {status!r}"
            )
        owner = gate.get("owner")
        if owner not in OWNERS:
            errors.append(
                f"SCHEMA: gate={gid} owner must be one of {sorted(OWNERS)}, "
                f"got {owner!r}"
            )
        depends_on = gate.get("depends_on")
        if not isinstance(depends_on, list) or not all(
            isinstance(d, str) for d in depends_on
        ):
            errors.append(f"SCHEMA: gate={gid} depends_on must be list of strings")
        evidence_paths = gate.get("evidence_paths")
        if not isinstance(evidence_paths, list) or not all(
            isinstance(p, str) for p in evidence_paths
        ):
            errors.append(
                f"SCHEMA: gate={gid} evidence_paths must be list of strings"
            )
        reason = gate.get("reason")
        if not isinstance(reason, str):
            errors.append(f"SCHEMA: gate={gid} reason must be a string")
    return errors


def _check_art_consistency(
    gates: dict[str, Any], root: Path, errors: list[str]
) -> None:
    art_gate = gates.get("art_ship")
    if not isinstance(art_gate, dict):
        return
    if art_gate.get("status") != "READY":
        return

    art_path = root / "docs" / "art_qa" / "art_qa_audit.json"
    if not art_path.is_file():
        errors.append(
            "ART_INCONSISTENT: art_ship READY but docs/art_qa/art_qa_audit.json "
            "missing"
        )
        return

    try:
        art = json.loads(art_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(
            f"ART_INCONSISTENT: art_ship READY but art_qa_audit unreadable: {exc}"
        )
        return

    ship_gate = art.get("ship_gate")
    if ship_gate in ART_BLOCKING:
        errors.append(
            f"ART_INCONSISTENT: art_ship READY while art_qa ship_gate={ship_gate}"
        )
        return

    if ship_gate in ART_APPROVED:
        evidence = art.get("device_evidence_paths") or []
        if not isinstance(evidence, list) or not evidence:
            errors.append(
                "ART_INCONSISTENT: art_ship READY with approved art ship_gate "
                f"{ship_gate} but device_evidence_paths empty"
            )
            return
        for rel in evidence:
            if not isinstance(rel, str) or not (root / rel).exists():
                errors.append(
                    "ART_INCONSISTENT: art_ship READY but art device evidence "
                    f"path missing: {rel!r}"
                )
        return

    # Unknown or unexpected ship_gate while claiming art_ship READY.
    errors.append(
        f"ART_INCONSISTENT: art_ship READY with unexpected art ship_gate={ship_gate!r}"
    )


def validate_data(
    data: dict[str, Any], root: Path, tip_short: str
) -> list[str]:
    """Return honesty errors; empty list means the file is honest."""
    errors = _schema_errors(data)
    # Continue path/dependency checks even with schema issues when gates is usable.
    gates = data.get("gates")
    if not isinstance(gates, dict):
        return errors

    for gid, gate in gates.items():
        if not isinstance(gate, dict):
            continue

        evidence_paths = gate.get("evidence_paths")
        if isinstance(evidence_paths, list):
            for rel in evidence_paths:
                if not isinstance(rel, str):
                    continue
                if not (root / rel).exists():
                    errors.append(f"MISSING_PATH: gate={gid} path={rel}")

        status = gate.get("status")
        if status == "READY":
            if not isinstance(evidence_paths, list) or len(evidence_paths) == 0:
                errors.append(f"READY_WITHOUT_EVIDENCE: gate={gid}")

            tip = gate.get("tip_sha_short")
            if tip != tip_short:
                errors.append(
                    f"STALE_TIP: gate={gid} tip={tip!r} current={tip_short}"
                )

            depends_on = gate.get("depends_on")
            if isinstance(depends_on, list):
                for dep in depends_on:
                    if not isinstance(dep, str):
                        continue
                    dep_gate = gates.get(dep)
                    dep_status = (
                        dep_gate.get("status")
                        if isinstance(dep_gate, dict)
                        else None
                    )
                    if dep_status not in ("READY", "N_A"):
                        errors.append(
                            f"DEPENDENCY: gate={gid} needs={dep} "
                            f"(status={dep_status!r})"
                        )

    _check_art_consistency(gates, root, errors)
    return errors


def current_tip(root: Path) -> str:
    return subprocess.check_output(
        ["git", "rev-parse", "--short", "HEAD"], cwd=root, text=True
    ).strip()


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    path = root / "docs" / "launch" / "launch_gates.json"
    if not path.is_file():
        print(
            f"launch-gate-check: FAIL missing {path.relative_to(root)}",
            file=sys.stderr,
        )
        return 1
    data = json.loads(path.read_text(encoding="utf-8"))
    tip = current_tip(root)
    errors = validate_data(data, root, tip)
    overall = derive_overall(data)
    if errors:
        print("launch-gate-check: FAIL", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        print(
            f"launch-gate-check: overall={overall} tip={tip}",
            file=sys.stderr,
        )
        return 1
    gates = data.get("gates") or {}
    for gid in REQUIRED_GATE_IDS:
        g = gates.get(gid) or {}
        print(f"  {gid}: {g.get('status')} tip={g.get('tip_sha_short')}")
    print(f"launch-gate-check: PASS overall={overall} tip={tip}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
