#!/usr/bin/env python3
"""Validate the Art QA machine package under docs/art_qa/.

Ensures ship_gate honesty: ART_SHIP_APPROVED requires cited device evidence paths
that exist in-repo. Does not invent device receipts.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "docs" / "art_qa" / "art_qa_audit.json"

GATES = {
    "ART_SHIP_APPROVED",
    "ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES",
    "ART_SHIP_BLOCKED",
    "ART_EVIDENCE_INSUFFICIENT",
}


def main() -> int:
    if not JSON_PATH.is_file():
        print(f"art-qa-check: FAIL missing {JSON_PATH.relative_to(ROOT)}", file=sys.stderr)
        return 1

    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    errors: list[str] = []

    gate = data.get("ship_gate")
    if gate not in GATES:
        errors.append(f"ship_gate must be one of {sorted(GATES)}, got {gate!r}")

    commit = data.get("commit") or data.get("commit_short")
    if not commit:
        errors.append("commit / commit_short required")

    findings = data.get("findings")
    if findings is None:
        errors.append("findings key required")
    elif not isinstance(findings, list):
        errors.append("findings must be a list")
    elif len(findings) == 0 and not data.get("findings_justified_empty"):
        errors.append("findings empty without findings_justified_empty=true")

    markdown = data.get("markdown")
    if markdown:
        md_path = ROOT / markdown
        if not md_path.is_file():
            errors.append(f"markdown missing: {markdown}")
    else:
        errors.append("markdown path required")

    checklist = data.get("device_checklist")
    if checklist:
        cl_path = ROOT / checklist
        if not cl_path.is_file():
            errors.append(f"device_checklist missing: {checklist}")

    if gate == "ART_SHIP_APPROVED":
        evidence = data.get("device_evidence_paths") or []
        if not evidence:
            errors.append(
                "ART_SHIP_APPROVED requires non-empty device_evidence_paths "
                "(tip-matched DEVICE_TEST_LOG / ART checklist entries)"
            )
        for rel in evidence:
            if not (ROOT / rel).exists():
                errors.append(f"device evidence path missing: {rel}")

    if gate == "ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES":
        evidence = data.get("device_evidence_paths") or []
        if not evidence:
            errors.append(
                "ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES requires device_evidence_paths"
            )

    if errors:
        print("art-qa-check: FAIL", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print(
        f"art-qa-check: PASS gate={gate} findings={len(findings or [])} "
        f"commit={(commit or '')[:12]}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
