#!/usr/bin/env python3
"""Validate the audio production manifest and its runtime catalog boundary."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "AUDIO_ASSET_MANIFEST.json"
RUNTIME_CATALOG = (
    ROOT
    / "Sources"
    / "SurveillanceCore"
    / "Resources"
    / "Content"
    / "audio_events.json"
)

REQUIRED_ENTRY_FIELDS = {
    "asset_id",
    "logical_stem",
    "filename",
    "scope",
    "category",
    "bus",
    "loop",
    "duration_target",
    "variant_count",
    "status",
    "integration_target",
    "prompt",
}


def fail(message: str) -> None:
    print(f"audio-manifest error: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {path.relative_to(ROOT)}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path.relative_to(ROOT)}: {exc}")


def assert_unique(entries: list[dict], field: str) -> None:
    values = [entry.get(field) for entry in entries]
    duplicates = sorted({value for value in values if values.count(value) > 1})
    if duplicates:
        fail(f"duplicate {field}: {duplicates}")


def main() -> int:
    manifest = load_json(MANIFEST)
    runtime = load_json(RUNTIME_CATALOG)

    if manifest.get("schema_version") != 1:
        fail("unsupported manifest schema_version")

    statuses = set(manifest.get("status_values", []))
    if not statuses:
        fail("status_values must not be empty")

    entries = manifest.get("assets")
    if not isinstance(entries, list) or not entries:
        fail("assets must be a non-empty list")

    for index, entry in enumerate(entries):
        missing = REQUIRED_ENTRY_FIELDS - set(entry)
        if missing:
            fail(f"entry {index} missing fields: {sorted(missing)}")
        if entry["status"] not in statuses:
            fail(f"entry {entry['asset_id']} has unsupported status {entry['status']}")
        if not isinstance(entry["variant_count"], int) or entry["variant_count"] < 1:
            fail(f"entry {entry['asset_id']} has invalid variant_count")
        if not entry["filename"].endswith(".wav"):
            fail(f"entry {entry['asset_id']} master filename must end in .wav")
        if entry["filename"] != f"{entry['logical_stem']}.wav":
            fail(f"entry {entry['asset_id']} filename/stem mismatch")
        if not entry["prompt"].strip():
            fail(f"entry {entry['asset_id']} has empty prompt")

    for field in ("asset_id", "logical_stem", "filename"):
        assert_unique(entries, field)

    runtime_stems = {cue["assetName"] for cue in runtime.get("cues", [])}
    required_stems = {
        entry["logical_stem"]
        for entry in entries
        if entry["scope"] == "runtime_required"
    }

    if required_stems != runtime_stems:
        missing_from_manifest = sorted(runtime_stems - required_stems)
        extra_runtime_claims = sorted(required_stems - runtime_stems)
        fail(
            "runtime boundary drift; "
            f"missing_from_manifest={missing_from_manifest}, "
            f"extra_runtime_claims={extra_runtime_claims}"
        )

    reserved_integrated = [
        entry["asset_id"]
        for entry in entries
        if entry["scope"] != "runtime_required"
        and entry["status"] == "runtime_integrated"
    ]
    if reserved_integrated:
        fail(
            "reserved assets claim runtime integration without catalog authority: "
            f"{reserved_integrated}"
        )

    print(
        "audio manifest valid: "
        f"{len(entries)} assets, {len(runtime_stems)} runtime-required stems"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
