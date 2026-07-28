#!/usr/bin/env python3
"""Validate the complete simulator QA artifact set."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from qa_artifact_schemas import QAArtifactError, load


ARTIFACTS = {
    "matrix": "matrix-receipt.json",
    "triage": "visual-triage.json",
    "history": "visual-history-entry.json",
    "trend": "visual-trend.json",
    "anomaly": "anomaly-review.json",
    "index": "qa-index.json",
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact_root", type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--write-migrated-history", action="store_true")
    args = parser.parse_args()

    try:
        values = {kind: load(args.artifact_root / name, kind) for kind, name in ARTIFACTS.items()}
        if args.baseline is not None:
            load(args.baseline, "baseline")
    except QAArtifactError as exc:
        raise SystemExit(f"qa-schema: {exc}") from exc

    history = values["history"]
    if args.write_migrated_history and history.get("migratedFromSchemaVersion") == 1:
        path = args.artifact_root / ARTIFACTS["history"]
        path.write_text(json.dumps(history, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    versions = ", ".join(f"{kind}=v{value['schemaVersion']}" for kind, value in values.items())
    print(f"qa-schema: PASS {versions}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
