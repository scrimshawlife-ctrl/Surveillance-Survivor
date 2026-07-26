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


def load(name: str) -> dict:
    return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


def current_tip() -> str:
    return subprocess.check_output(
        ["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True
    ).strip()


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


if __name__ == "__main__":
    raise SystemExit(unittest.main())
