#!/usr/bin/env python3
"""Check or refresh the non-device QA test-count baseline from test logs."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path
from typing import Iterable

from qa_artifact_schemas import QAArtifactError, load, validate

COUNT_KEYS = ("swiftPackage", "simulatorHosted", "uiJourneys")
SWIFT_PATTERNS = (
    re.compile(r"Test run with (\d+) tests?"),
    re.compile(r"Executed (\d+) tests?"),
)
XCODE_PATTERN = re.compile(r"Executed (\d+) tests?")
XCODE_PATTERNS = (
    XCODE_PATTERN,
    # Swift Testing suites hosted by xcodebuild report their aggregate with this
    # form while compatibility XCTest suites may emit much smaller Executed rows.
    re.compile(r"Test run with (\d+) tests?"),
)


def extract_count(path: Path, patterns: Iterable[re.Pattern[str]], label: str) -> int:
    if not path.is_file():
        raise ValueError(f"{label}: missing test log: {path}")
    text = path.read_text(encoding="utf-8", errors="replace")
    counts = [int(match.group(1)) for pattern in patterns for match in pattern.finditer(text)]
    if not counts:
        raise ValueError(f"{label}: no test-count summary found in {path}")
    count = max(counts)
    if count <= 0:
        raise ValueError(f"{label}: extracted non-positive count {count}")
    return count


def observed_counts(swift_log: Path, simulator_log: Path, ui_log: Path) -> dict[str, int]:
    return {
        "swiftPackage": extract_count(swift_log, SWIFT_PATTERNS, "swiftPackage"),
        "simulatorHosted": extract_count(simulator_log, XCODE_PATTERNS, "simulatorHosted"),
        "uiJourneys": extract_count(ui_log, (XCODE_PATTERN,), "uiJourneys"),
    }


def compare(previous: dict[str, int], observed: dict[str, int]) -> tuple[list[str], list[str]]:
    increases, decreases = [], []
    for key in COUNT_KEYS:
        before, after = previous[key], observed[key]
        if after > before:
            increases.append(f"{key}: {before} -> {after}")
        elif after < before:
            decreases.append(f"{key}: {before} -> {after}")
    return increases, decreases


def refresh_payload(
    baseline: dict,
    observed: dict[str, int],
    commit: str,
    decrease_reason: str | None,
) -> dict:
    previous = baseline["counts"]
    increases, decreases = compare(previous, observed)
    if decreases and not decrease_reason:
        raise ValueError(
            "test counts decreased; rerun with --approve-decrease and a review reason: "
            + "; ".join(decreases)
        )
    updated = dict(baseline)
    updated["counts"] = observed
    updated["validatedCommit"] = commit
    if decreases:
        updated["decreaseReview"] = {
            "approved": True,
            "reason": decrease_reason,
            "previousCounts": previous,
            "newCounts": observed,
            "reviewedCommit": commit,
        }
    elif increases:
        updated.pop("decreaseReview", None)
    validate("baseline", updated)
    return updated


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", type=Path, default=Path("qa/non-device-baseline.json"))
    parser.add_argument("--swift-log", type=Path, required=True)
    parser.add_argument("--simulator-log", type=Path, required=True)
    parser.add_argument("--ui-log", type=Path, required=True)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--approve-decrease", metavar="REASON")
    parser.add_argument("--repo", type=Path, default=Path("."))
    args = parser.parse_args()

    try:
        baseline = load(args.baseline, "baseline")
        observed = observed_counts(args.swift_log, args.simulator_log, args.ui_log)
        increases, decreases = compare(baseline["counts"], observed)
        if args.write:
            commit = subprocess.check_output(
                ["git", "-C", str(args.repo), "rev-parse", "--short", "HEAD"], text=True
            ).strip()
            updated = refresh_payload(baseline, observed, commit, args.approve_decrease)
            args.baseline.write_text(json.dumps(updated, indent=2, sort_keys=True) + "\n", encoding="utf-8")
            changes = increases + decreases
            print("qa-baseline: UPDATED " + ("; ".join(changes) if changes else "counts unchanged"))
            return 0
        if increases or decreases:
            direction = "decreased" if decreases else "increased"
            details = decreases + increases
            raise ValueError(
                f"observed test counts {direction}; refresh the registry with --write"
                + (" --approve-decrease REASON" if decreases else "")
                + ": " + "; ".join(details)
            )
    except (QAArtifactError, OSError, ValueError, subprocess.CalledProcessError) as exc:
        raise SystemExit(f"qa-baseline: {exc}") from exc

    counts = baseline["counts"]
    print(
        "qa-baseline: PASS "
        f"package={counts['swiftPackage']} simulator={counts['simulatorHosted']} ui={counts['uiJourneys']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
