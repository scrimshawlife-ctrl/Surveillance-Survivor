#!/usr/bin/env python3
"""Focused delivery-boundary tests for validate_audio_manifest.py."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True

import validate_audio_manifest as validator


class AudioManifestDeliveryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)
        self.delivery_root = self.root / "Resources" / "Audio" / "Delivery"
        self.delivery_file = self.delivery_root / "Runtime" / "sfx_test.caf"
        self.delivery_file.parent.mkdir(parents=True)
        self.delivery_file.write_bytes(b"valid-caf-fixture")
        self.manifest_path = self.root / "manifest.json"
        self.catalog_path = self.root / "audio_events.json"
        self.write_fixture()

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def manifest(self) -> dict:
        return json.loads(self.manifest_path.read_text(encoding="utf-8"))

    def write_manifest(self, manifest: dict) -> None:
        self.manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

    def write_fixture(self) -> None:
        delivery_hash = hashlib.sha256(self.delivery_file.read_bytes()).hexdigest()
        manifest = {
            "schema_version": 1,
            "status_values": ["runtime_integrated"],
            "assets": [
                {
                    "asset_id": "runtime.test",
                    "logical_stem": "sfx_test",
                    "filename": "sfx_test.wav",
                    "scope": "runtime_required",
                    "category": "feedback",
                    "bus": "sfx",
                    "loop": False,
                    "duration_target": "0.1-0.2s",
                    "variant_count": 1,
                    "status": "runtime_integrated",
                    "integration_target": "test",
                    "prompt": "A compact test cue.",
                    "delivery_path": "Resources/Audio/Delivery/Runtime/sfx_test.caf",
                    "delivery_sha256": delivery_hash,
                }
            ],
        }
        catalog = {
            "cues": [{"assetName": "sfx_test"}],
            "scenes": {"districts": []},
        }
        self.write_manifest(manifest)
        self.catalog_path.write_text(json.dumps(catalog), encoding="utf-8")

    def validate(self) -> tuple[int, int, int]:
        return validator.validate_audio_manifest(
            self.manifest_path,
            self.catalog_path,
            self.delivery_root,
        )

    def assert_validation_error(self, expected: str) -> None:
        with self.assertRaisesRegex(validator.ValidationError, expected):
            self.validate()

    def test_accepts_exact_manifested_nonempty_hash_matched_delivery(self) -> None:
        self.assertEqual(self.validate(), (1, 1, 1))

    def test_rejects_zero_byte_delivery(self) -> None:
        self.delivery_file.write_bytes(b"")
        self.assert_validation_error("zero-byte delivery resource")

    def test_rejects_unexpected_delivery_extension(self) -> None:
        (self.delivery_root / "Runtime" / "preview.wav").write_bytes(b"preview")
        self.assert_validation_error("unexpected delivery extension")

    def test_rejects_unmanifested_delivery(self) -> None:
        (self.delivery_root / "Runtime" / "extra.caf").write_bytes(b"extra")
        self.assert_validation_error("unmanifested delivery resource")

    def test_rejects_missing_delivery(self) -> None:
        self.delivery_file.unlink()
        self.assert_validation_error("missing delivery resource")

    def test_rejects_hash_mismatch(self) -> None:
        manifest = self.manifest()
        manifest["assets"][0]["delivery_sha256"] = "0" * 64
        self.write_manifest(manifest)
        self.assert_validation_error("delivery hash mismatch")

    def test_rejects_placeholder_files(self) -> None:
        (self.delivery_root / "Runtime" / ".gitkeep").write_bytes(b"")
        self.assert_validation_error("placeholder file is forbidden")


if __name__ == "__main__":
    raise SystemExit(unittest.main())
