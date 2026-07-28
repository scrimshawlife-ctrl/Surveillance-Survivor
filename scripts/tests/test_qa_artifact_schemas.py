from __future__ import annotations

import json
import sys
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))

from qa_artifact_schemas import QAArtifactError, load, validate  # noqa: E402


class QAArtifactSchemaTests(unittest.TestCase):
    def setUp(self) -> None:
        self.history = {
            "schemaVersion": 2,
            "commit": "abc1234",
            "generatedAt": "2026-07-28T00:00:00Z",
            "status": "pass",
            "panelCount": 20,
            "comparisonCount": 10,
            "meanLumaMinimum": 0.1,
            "meanLumaMaximum": 0.8,
            "identicalVariantPairs": 0,
            "perCity": {},
        }
        panel = {
            "variant": "combat", "district": "wichita", "cityName": "Wichita",
            "title": "Air Capital", "signatureMechanic": "wind", "bossName": "Eye",
            "reducedMotion": False, "reducedFlash": False, "width": 1179, "height": 624,
            "screenshot": "combat/wichita/launch-landscape.png",
            "receipt": "combat/wichita/emulator-receipt.json",
        }
        self.matrix = {
            "schemaVersion": 2, "status": "pass", "commit": "abc1234",
            "generatedAt": "2026-07-28T00:00:00Z", "variants": ["combat"],
            "expectedDistrictCount": 1, "expectedPanelCount": 1,
            "panels": [panel], "errors": [], "limitations": "simulator only",
        }
        self.baseline = {
            "schemaVersion": 1, "status": "pass", "validatedCommit": "abc1234",
            "counts": {"swiftPackage": 211, "simulatorHosted": 319, "uiJourneys": 10},
            "commands": {"swiftPackage": "swift test", "simulatorHostedAndUI": "make simulator-test"},
            "limitations": ["non-device"],
        }

    def test_current_versions_validate(self) -> None:
        self.assertEqual(validate("matrix", self.matrix)["schemaVersion"], 2)
        self.assertEqual(validate("history", self.history)["schemaVersion"], 2)
        self.assertEqual(validate("baseline", self.baseline)["schemaVersion"], 1)

    def test_legacy_history_v1_is_normalized_without_mutating_source(self) -> None:
        legacy = deepcopy(self.history)
        legacy["schemaVersion"] = 1
        legacy.pop("perCity")
        normalized = validate("history", legacy)
        self.assertEqual(normalized["schemaVersion"], 2)
        self.assertEqual(normalized["migratedFromSchemaVersion"], 1)
        self.assertEqual(normalized["perCity"], {})
        self.assertNotIn("perCity", legacy)

    def test_unknown_version_fails_closed(self) -> None:
        artifact = deepcopy(self.history)
        artifact["schemaVersion"] = 99
        with self.assertRaisesRegex(QAArtifactError, "unsupported schemaVersion 99"):
            validate("history", artifact)

    def test_missing_version_fails_closed(self) -> None:
        artifact = deepcopy(self.baseline)
        artifact.pop("schemaVersion")
        with self.assertRaisesRegex(QAArtifactError, "missing required field 'schemaVersion'"):
            validate("baseline", artifact)

    def test_missing_required_field_fails_closed(self) -> None:
        artifact = deepcopy(self.matrix)
        artifact.pop("panels")
        with self.assertRaisesRegex(QAArtifactError, "missing required field 'panels'"):
            validate("matrix", artifact)

    def test_cross_field_count_mismatch_fails_closed(self) -> None:
        artifact = deepcopy(self.matrix)
        artifact["expectedPanelCount"] = 2
        with self.assertRaisesRegex(QAArtifactError, "districts × variants"):
            validate("matrix", artifact)

    def test_boolean_does_not_pass_as_integer(self) -> None:
        artifact = deepcopy(self.baseline)
        artifact["counts"]["swiftPackage"] = True
        with self.assertRaisesRegex(QAArtifactError, "non-negative int"):
            validate("baseline", artifact)

    def test_malformed_json_has_bounded_error(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "history.json"
            path.write_text("{not json", encoding="utf-8")
            with self.assertRaisesRegex(QAArtifactError, "invalid JSON"):
                load(path, "history")

    def test_non_object_json_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "history.json"
            path.write_text(json.dumps([]), encoding="utf-8")
            with self.assertRaisesRegex(QAArtifactError, "expected a JSON object"):
                load(path, "history")


if __name__ == "__main__":
    unittest.main()
