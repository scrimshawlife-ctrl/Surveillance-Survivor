from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))

from refresh_qa_baseline import (  # noqa: E402
    SWIFT_PATTERNS,
    XCODE_PATTERN,
    XCODE_PATTERNS,
    compare,
    extract_count,
    observed_counts,
    refresh_payload,
)


class QABaselineRefreshTests(unittest.TestCase):
    def setUp(self) -> None:
        self.baseline = {
            "schemaVersion": 1,
            "status": "pass",
            "validatedCommit": "old1234",
            "counts": {"swiftPackage": 211, "simulatorHosted": 319, "uiJourneys": 10},
            "commands": {"swiftPackage": "swift test", "simulatorHostedAndUI": "make simulator-test"},
            "limitations": ["non-device"],
        }

    def test_extracts_realistic_swift_and_xcode_summaries(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            swift = root / "swift.log"
            simulator = root / "simulator.log"
            ui = root / "ui.log"
            swift.write_text("✔ Test run with 211 tests in 6 suites passed\n", encoding="utf-8")
            simulator.write_text("Executed 319 tests, with 0 failures\nExecuted 319 tests, with 0 failures\n", encoding="utf-8")
            ui.write_text("Executed 10 tests, with 0 failures\n", encoding="utf-8")
            self.assertEqual(
                observed_counts(swift, simulator, ui),
                {"swiftPackage": 211, "simulatorHosted": 319, "uiJourneys": 10},
            )

    def test_uses_largest_suite_summary(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "xcode.log"
            path.write_text("Executed 10 tests\nExecuted 319 tests\n", encoding="utf-8")
            self.assertEqual(extract_count(path, (XCODE_PATTERN,), "simulator"), 319)

    def test_xcode_parser_prefers_swift_testing_aggregate_over_xctest_compatibility_suite(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "xcode.log"
            path.write_text(
                "Executed 8 tests, with 0 failures\n"
                "✔ Test run with 322 tests in 6 suites passed\n",
                encoding="utf-8",
            )
            self.assertEqual(extract_count(path, XCODE_PATTERNS, "simulator"), 322)

    def test_missing_or_malformed_log_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            missing = Path(directory) / "missing.log"
            with self.assertRaisesRegex(ValueError, "missing test log"):
                extract_count(missing, SWIFT_PATTERNS, "swift")
            malformed = Path(directory) / "malformed.log"
            malformed.write_text("tests passed somehow", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "no test-count summary"):
                extract_count(malformed, SWIFT_PATTERNS, "swift")

    def test_compare_identifies_increases_and_decreases(self) -> None:
        observed = {"swiftPackage": 212, "simulatorHosted": 318, "uiJourneys": 10}
        increases, decreases = compare(self.baseline["counts"], observed)
        self.assertEqual(increases, ["swiftPackage: 211 -> 212"])
        self.assertEqual(decreases, ["simulatorHosted: 319 -> 318"])

    def test_increase_refreshes_without_review_record(self) -> None:
        observed = {"swiftPackage": 212, "simulatorHosted": 319, "uiJourneys": 10}
        updated = refresh_payload(self.baseline, observed, "new1234", None)
        self.assertEqual(updated["counts"], observed)
        self.assertEqual(updated["validatedCommit"], "new1234")
        self.assertNotIn("decreaseReview", updated)

    def test_decrease_requires_explicit_review_reason(self) -> None:
        observed = {"swiftPackage": 211, "simulatorHosted": 318, "uiJourneys": 10}
        with self.assertRaisesRegex(ValueError, "--approve-decrease"):
            refresh_payload(self.baseline, observed, "new1234", None)

    def test_reviewed_decrease_records_previous_and_new_counts(self) -> None:
        observed = {"swiftPackage": 211, "simulatorHosted": 318, "uiJourneys": 10}
        updated = refresh_payload(self.baseline, observed, "new1234", "Removed duplicate generated case")
        review = updated["decreaseReview"]
        self.assertTrue(review["approved"])
        self.assertEqual(review["reason"], "Removed duplicate generated case")
        self.assertEqual(review["previousCounts"], self.baseline["counts"])
        self.assertEqual(review["newCounts"], observed)
        self.assertEqual(review["reviewedCommit"], "new1234")


if __name__ == "__main__":
    unittest.main()
