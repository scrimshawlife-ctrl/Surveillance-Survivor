#!/usr/bin/env python3
"""Fail when release-facing documentation contradicts repository truth.

This does not declare the product release-ready. It verifies that the store and
device worksheets retain required owner/operator gates and do not regress to
known-stale implementation claims.
"""

from __future__ import annotations

import plistlib
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STORE_DOC = ROOT / "docs" / "APP_STORE_METADATA.md"
DEVICE_LOG = ROOT / "docs" / "DEVICE_TEST_LOG.md"
PRIVACY_MANIFEST = ROOT / "App" / "PrivacyInfo.xcprivacy"


def require_text(path: Path, required: list[str], errors: list[str]) -> str:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        errors.append(f"missing or unreadable {path.relative_to(ROOT)}: {exc}")
        return ""
    for needle in required:
        if needle not in text:
            errors.append(
                f"{path.relative_to(ROOT)} missing required release marker: {needle!r}"
            )
    return text


def validate_store_doc(errors: list[str]) -> None:
    text = require_text(
        STORE_DOC,
        [
            "life.zerostate.surveillancesurvivor",
            "68/68",
            "physical-device listening",
            "Live privacy policy URL",
            "Live support URL",
            "ASC privacy questionnaire",
            "Truthful iPhone screenshots from release build",
        ],
        errors,
    )
    stale_claims = [
        "catalog only; need ElevenLabs license",
        "Blocked — catalog only",
        "zero binaries",
    ]
    for claim in stale_claims:
        if claim.lower() in text.lower():
            errors.append(
                f"{STORE_DOC.relative_to(ROOT)} contains stale audio claim: {claim!r}"
            )


def validate_device_log(errors: list[str]) -> None:
    require_text(
        DEVICE_LOG,
        [
            "commit SHA:",
            "git status --short",
            "frame p50 / p95 / maximum (ms):",
            "backgrounded at least 10 seconds",
            "VoiceOver",
            "speaker / headphones",
            "silent mode",
            "audio interruption",
            "route change",
            "dense-combat clipping",
            "Device receipt JSON",
        ],
        errors,
    )


def validate_privacy_manifest(errors: list[str]) -> None:
    try:
        with PRIVACY_MANIFEST.open("rb") as handle:
            manifest = plistlib.load(handle)
    except (OSError, plistlib.InvalidFileException) as exc:
        errors.append(
            f"missing or invalid {PRIVACY_MANIFEST.relative_to(ROOT)}: {exc}"
        )
        return

    if manifest.get("NSPrivacyTracking") is not False:
        errors.append("privacy manifest must explicitly set NSPrivacyTracking=false")
    if manifest.get("NSPrivacyCollectedDataTypes") != []:
        errors.append("offline MVP privacy claim requires no collected data types")

    accessed = manifest.get("NSPrivacyAccessedAPITypes")
    if not isinstance(accessed, list):
        errors.append("privacy manifest NSPrivacyAccessedAPITypes must be an array")
        return
    user_defaults = [
        item
        for item in accessed
        if isinstance(item, dict)
        and item.get("NSPrivacyAccessedAPIType")
        == "NSPrivacyAccessedAPICategoryUserDefaults"
    ]
    if len(user_defaults) != 1:
        errors.append("privacy manifest must declare exactly one UserDefaults API entry")
        return
    reasons = user_defaults[0].get("NSPrivacyAccessedAPITypeReasons")
    if reasons != ["CA92.1"]:
        errors.append(
            f"UserDefaults required-reason declaration must be ['CA92.1'], got {reasons!r}"
        )


def main() -> int:
    errors: list[str] = []
    validate_store_doc(errors)
    validate_device_log(errors)
    validate_privacy_manifest(errors)
    if errors:
        print("release-docs-check: FAIL", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print(
        "release-docs-check: PASS — store blockers, device evidence fields, "
        "and privacy claims are internally consistent"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
