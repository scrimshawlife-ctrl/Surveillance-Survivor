#!/usr/bin/env python3
"""Versioned contracts for simulator QA JSON artifacts.

The module is dependency-free so CI and local simulator workflows can validate
artifacts without installing a JSON Schema implementation. Contracts deliberately
cover envelope and cross-field invariants used by consumers. Unknown versions,
missing required fields, and malformed shapes fail closed.
"""
from __future__ import annotations

import json
import sys
from copy import deepcopy
from pathlib import Path
from typing import Any, Callable


class QAArtifactError(ValueError):
    """Raised when a QA artifact violates its versioned contract."""


def _fail(kind: str, message: str) -> None:
    raise QAArtifactError(f"{kind}: {message}")


def _object(kind: str, value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        _fail(kind, "expected a JSON object")
    return value


def _require(kind: str, value: dict[str, Any], fields: dict[str, type | tuple[type, ...]]) -> None:
    for field, expected in fields.items():
        if field not in value:
            _fail(kind, f"missing required field {field!r}")
        actual = value[field]
        if expected is int and isinstance(actual, bool):
            _fail(kind, f"field {field!r} must be int")
        if not isinstance(actual, expected):
            names = ", ".join(item.__name__ for item in expected) if isinstance(expected, tuple) else expected.__name__
            _fail(kind, f"field {field!r} must be {names}")


def _version(kind: str, value: dict[str, Any], supported: set[int]) -> int:
    if "schemaVersion" not in value:
        _fail(kind, "missing required field 'schemaVersion'")
    version = value["schemaVersion"]
    if not isinstance(version, int) or isinstance(version, bool):
        _fail(kind, "field 'schemaVersion' must be int")
    if version not in supported:
        _fail(kind, f"unsupported schemaVersion {version}; supported: {sorted(supported)}")
    return version


def _status(kind: str, value: dict[str, Any], allowed: set[str]) -> None:
    status = value.get("status")
    if status not in allowed:
        _fail(kind, f"field 'status' must be one of {sorted(allowed)}")


def _matrix(value: dict[str, Any]) -> dict[str, Any]:
    _version("matrix", value, {2})
    _require("matrix", value, {
        "status": str, "commit": str, "generatedAt": str, "variants": list,
        "expectedDistrictCount": int, "expectedPanelCount": int, "panels": list,
        "errors": list, "limitations": str,
    })
    _status("matrix", value, {"pass", "fail"})
    if value["expectedPanelCount"] != value["expectedDistrictCount"] * len(value["variants"]):
        _fail("matrix", "expectedPanelCount must equal districts × variants")
    if value["status"] == "pass" and len(value["panels"]) != value["expectedPanelCount"]:
        _fail("matrix", "passing artifact must contain expectedPanelCount panels")
    if "execution" in value:
        execution = _object("matrix.execution", value["execution"])
        _require("matrix.execution", execution, {
            "workerCount": int, "settleSeconds": int,
            "sharedBuild": bool, "installCount": int,
        })
        if not 1 <= execution["workerCount"] <= 4 or execution["settleSeconds"] < 1:
            _fail("matrix.execution", "workerCount must be 1...4 and settleSeconds must be positive")
        if execution["sharedBuild"] is not True or execution["installCount"] != execution["workerCount"]:
            _fail("matrix.execution", "must use one shared build and one install per worker")
    for index, panel in enumerate(value["panels"]):
        panel = _object(f"matrix.panels[{index}]", panel)
        _require(f"matrix.panels[{index}]", panel, {
            "variant": str, "district": str, "cityName": str, "title": str,
            "signatureMechanic": str, "bossName": str, "reducedMotion": bool,
            "reducedFlash": bool, "width": int, "height": int,
            "screenshot": str, "receipt": str,
        })
    return value


def _triage(value: dict[str, Any]) -> dict[str, Any]:
    _version("triage", value, {1})
    _require("triage", value, {
        "status": str, "commit": str, "generatedAt": str, "panelCount": int,
        "comparisonCount": int, "meanLumaRange": list, "panels": list,
        "variantComparisons": list, "errors": list, "policy": str,
    })
    _status("triage", value, {"pass", "fail"})
    if value["panelCount"] != len(value["panels"]):
        _fail("triage", "panelCount does not match panels")
    if value["comparisonCount"] != len(value["variantComparisons"]):
        _fail("triage", "comparisonCount does not match variantComparisons")
    return value


def _history(value: dict[str, Any]) -> dict[str, Any]:
    version = _version("history", value, {1, 2})
    _require("history", value, {
        "commit": str, "generatedAt": str, "status": str, "panelCount": int,
        "comparisonCount": int, "meanLumaMinimum": (int, float),
        "meanLumaMaximum": (int, float), "identicalVariantPairs": int,
    })
    _status("history", value, {"pass", "fail"})
    normalized = deepcopy(value)
    if version == 1:
        normalized["schemaVersion"] = 2
        normalized["perCity"] = {}
        normalized["migratedFromSchemaVersion"] = 1
    else:
        _require("history", value, {"perCity": dict})
    return normalized


def _trend(value: dict[str, Any]) -> dict[str, Any]:
    _version("trend", value, {1})
    _require("trend", value, {
        "status": str, "currentCommit": str, "deltas": dict,
        "annotations": list, "policy": str,
    })
    _status("trend", value, {"no-baseline", "stable", "review"})
    if value.get("baselineCommit") is not None and not isinstance(value.get("baselineCommit"), str):
        _fail("trend", "field 'baselineCommit' must be string or null")
    return value


def _anomaly(value: dict[str, Any]) -> dict[str, Any]:
    _version("anomaly", value, {1})
    _require("anomaly", value, {
        "status": str, "currentCommit": str, "baselineCommit": str,
        "baselineCompatibility": str, "districts": list, "contactSheet": str,
        "policy": str,
    })
    _status("anomaly", value, {"none", "legacy-baseline", "review"})
    return value


def _baseline(value: dict[str, Any]) -> dict[str, Any]:
    _version("baseline", value, {1})
    _require("baseline", value, {
        "status": str, "validatedCommit": str, "counts": dict,
        "commands": dict, "limitations": list,
    })
    _status("baseline", value, {"pass", "fail"})
    expected = {"swiftPackage", "simulatorHosted", "uiJourneys"}
    if set(value["counts"]) != expected:
        _fail("baseline", f"counts keys must be exactly {sorted(expected)}")
    for name, count in value["counts"].items():
        if not isinstance(count, int) or isinstance(count, bool) or count < 0:
            _fail("baseline", f"count {name!r} must be a non-negative int")
    if "decreaseReview" in value:
        review = _object("baseline.decreaseReview", value["decreaseReview"])
        _require("baseline.decreaseReview", review, {
            "approved": bool, "reason": str, "previousCounts": dict,
            "newCounts": dict, "reviewedCommit": str,
        })
        if review["approved"] is not True or not review["reason"].strip():
            _fail("baseline.decreaseReview", "must be explicitly approved with a non-empty reason")
        if review["newCounts"] != value["counts"]:
            _fail("baseline.decreaseReview", "newCounts must match baseline counts")
        if not any(review["newCounts"].get(key, 0) < review["previousCounts"].get(key, 0) for key in expected):
            _fail("baseline.decreaseReview", "must document at least one count decrease")
    return value


def _index(value: dict[str, Any]) -> dict[str, Any]:
    _version("index", value, {1})
    _require("index", value, {
        "status": str, "commit": str, "testBaseline": dict,
        "visualEvidence": dict, "links": list, "errors": list,
        "limitations": str,
    })
    _status("index", value, {"pass", "fail"})
    _baseline(_object("index.testBaseline", value["testBaseline"]))
    return value


VALIDATORS: dict[str, Callable[[dict[str, Any]], dict[str, Any]]] = {
    "matrix": _matrix,
    "triage": _triage,
    "history": _history,
    "trend": _trend,
    "anomaly": _anomaly,
    "baseline": _baseline,
    "index": _index,
}


def validate(kind: str, value: Any) -> dict[str, Any]:
    """Validate and normalize one artifact. Legacy history v1 becomes v2."""
    try:
        validator = VALIDATORS[kind]
    except KeyError as exc:
        raise QAArtifactError(f"unknown artifact kind {kind!r}") from exc
    return validator(_object(kind, value))


def load(path: Path, kind: str) -> dict[str, Any]:
    if not path.is_file():
        raise QAArtifactError(f"{kind}: missing required artifact: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise QAArtifactError(f"{kind}: invalid JSON {path}: {exc}") from exc
    return validate(kind, value)


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("usage: qa_artifact_schemas.py KIND ARTIFACT_JSON")
    kind, path = sys.argv[1], Path(sys.argv[2])
    try:
        value = load(path, kind)
    except QAArtifactError as exc:
        raise SystemExit(f"qa-schema: {exc}") from exc
    source_version = value.get("migratedFromSchemaVersion", value["schemaVersion"])
    suffix = f" normalized-to=v{value['schemaVersion']}" if source_version != value["schemaVersion"] else ""
    print(f"qa-schema: PASS {kind}=v{source_version}{suffix}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
