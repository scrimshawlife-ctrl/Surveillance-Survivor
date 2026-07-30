#!/usr/bin/env python3
"""Unit tests for validate_launch_gates.py (stdlib unittest)."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))

import validate_launch_gates as v  # noqa: E402

FIXTURES = Path(__file__).resolve().parent / "testdata" / "launch"

# Relative evidence paths used by ready_all.json — materialize under temp roots.
READY_ALL_EVIDENCE = [
    "docs/DEVICE_TEST_LOG.md",
    "docs/ART_DEVICE_QA_CHECKLIST.md",
    "docs/APP_STORE_METADATA.md",
    "docs/AUDIO_ASSET_MANIFEST.json",
    "docs/LAUNCH_OPERATOR_PACKET.md",
]


def _audio_manifest(status: str = "runtime_integrated") -> str:
    return json.dumps(
        {"assets": [{"asset_id": "fixture.audio", "status": status}]},
        indent=2,
    ) + "\n"


def load(name: str) -> dict:
    return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


def current_tip() -> str:
    return subprocess.check_output(
        ["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True
    ).strip()


def _write(path: Path, text: str = "fixture\n") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


class ValidateLaunchGatesTests(unittest.TestCase):
    def test_honest_blocked_no_errors(self) -> None:
        data = load("honest_blocked.json")
        errors = v.validate_data(data, ROOT, current_tip())
        self.assertEqual(errors, [], errors)

    def test_ready_without_evidence(self) -> None:
        data = load("ready_without_evidence.json")
        tip = current_tip()
        data["gates"]["device_acceptance"]["tip_sha_short"] = tip
        errors = v.validate_data(data, ROOT, tip)
        self.assertTrue(any("READY_WITHOUT_EVIDENCE" in e for e in errors), errors)

    def test_stale_tip(self) -> None:
        data = load("stale_tip.json")
        errors = v.validate_data(data, ROOT, current_tip())
        self.assertTrue(any("STALE_TIP" in e for e in errors), errors)

    def test_missing_path(self) -> None:
        data = load("missing_path.json")
        tip = current_tip()
        data["gates"]["device_acceptance"]["tip_sha_short"] = tip
        errors = v.validate_data(data, ROOT, tip)
        self.assertTrue(any("MISSING_PATH" in e for e in errors), errors)

    def test_dependency_break(self) -> None:
        data = load("dependency_break.json")
        tip = current_tip()
        for g in data["gates"].values():
            if g.get("status") == "READY":
                g["tip_sha_short"] = tip
        errors = v.validate_data(data, ROOT, tip)
        self.assertTrue(any("DEPENDENCY" in e for e in errors), errors)

    def test_art_inconsistent(self) -> None:
        data = load("art_inconsistent.json")
        tip = current_tip()
        for g in data["gates"].values():
            if g.get("status") == "READY":
                g["tip_sha_short"] = tip
        errors = v.validate_data(data, ROOT, tip)
        self.assertTrue(any("ART_INCONSISTENT" in e for e in errors), errors)

    def test_overall_blocked_derived(self) -> None:
        data = load("honest_blocked.json")
        overall = v.derive_overall(data)
        self.assertEqual(overall, "LAUNCH_BLOCKED")

    def test_overall_mismatch_schema_error(self) -> None:
        data = load("honest_blocked.json")
        data["overall"] = "LAUNCH_READY"  # lies: gates are not all READY
        errors = v.validate_data(data, ROOT, current_tip())
        self.assertTrue(
            any(
                e.startswith("SCHEMA: overall=") and "derived=" in e for e in errors
            ),
            errors,
        )

    def test_integrated_audio_rejects_stale_catalog_only_reason(self) -> None:
        data = load("honest_blocked.json")
        data["gates"]["audio_product"]["reason"] = (
            "No licensed product stems; catalog only"
        )
        errors = v.validate_data(data, ROOT, current_tip())
        self.assertTrue(any("AUDIO_INCONSISTENT" in e for e in errors), errors)

    def test_audio_ready_rejects_nonintegrated_manifest(self) -> None:
        tip = "abc1234"
        data = load("honest_blocked.json")
        audio = data["gates"]["audio_product"]
        audio["status"] = "READY"
        audio["tip_sha_short"] = tip

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest_path = root / "docs" / "AUDIO_ASSET_MANIFEST.json"
            _write(manifest_path, _audio_manifest("derived_delivery"))
            for rel in audio["evidence_paths"]:
                path = root / rel
                if path != manifest_path:
                    _write(path)
            errors = v.validate_data(
                data, root, tip, audio_manifest_path=manifest_path
            )
        self.assertTrue(any("AUDIO_INCONSISTENT" in e for e in errors), errors)

    def test_hermetic_full_ready_pass(self) -> None:
        """Temp root + approved art audit: honest READY → LAUNCH_READY."""
        tip = "abc1234"
        data = load("ready_all.json")
        for g in data["gates"].values():
            if g.get("status") == "READY":
                g["tip_sha_short"] = tip

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for rel in READY_ALL_EVIDENCE:
                content = (
                    _audio_manifest()
                    if rel == "docs/AUDIO_ASSET_MANIFEST.json"
                    else "fixture\n"
                )
                _write(root / rel, content)
            art_evidence_rel = "docs/art_qa/device_evidence_fixture.txt"
            _write(root / art_evidence_rel, "art device evidence fixture\n")
            art_audit = {
                "ship_gate": "ART_SHIP_APPROVED",
                "device_evidence_paths": [art_evidence_rel],
            }
            art_path = root / "docs" / "art_qa" / "art_qa_audit.json"
            _write(art_path, json.dumps(art_audit, indent=2) + "\n")

            errors = v.validate_data(
                data, root, tip, art_audit_path=art_path
            )
            self.assertEqual(errors, [], errors)
            self.assertEqual(v.derive_overall(data), "LAUNCH_READY")


if __name__ == "__main__":
    raise SystemExit(unittest.main())
