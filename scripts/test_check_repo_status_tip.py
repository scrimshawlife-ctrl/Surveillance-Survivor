#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("check_repo_status_tip.py")
spec = importlib.util.spec_from_file_location("check_repo_status_tip", MODULE_PATH)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DocumentedTipTests(unittest.TestCase):
    def test_accepts_canonical_status_field(self) -> None:
        self.assertEqual(
            module.documented_tip("**`main` tip:** `03708b0` — description"),
            "03708b0",
        )

    def test_accepts_full_sha(self) -> None:
        sha = "03708b0b1c8fca1e0520dcd5af23e7dfb39e8fc2"
        self.assertEqual(module.documented_tip(f"**`main` tip:** `{sha}`"), sha)

    def test_normalizes_hex_case(self) -> None:
        self.assertEqual(module.documented_tip("**`main` tip:** `ABCDEF1`"), "abcdef1")

    def test_rejects_missing_field(self) -> None:
        with self.assertRaises(module.StatusError):
            module.documented_tip("main tip: 03708b0")

    def test_rejects_malformed_sha(self) -> None:
        with self.assertRaises(module.StatusError):
            module.documented_tip("**`main` tip:** `not-a-sha`")

    def test_rejects_too_short_sha(self) -> None:
        with self.assertRaises(module.StatusError):
            module.documented_tip("**`main` tip:** `123abc`")


if __name__ == "__main__":
    unittest.main()
