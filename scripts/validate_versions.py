#!/usr/bin/env python3
"""Validate canonical Surveillance Survivor version authorities.

The check intentionally avoids third-party dependencies so it can run in CI,
local development, and constrained agent environments.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "versions.json"
PROJECT = ROOT / "project.yml"
CI_WORKFLOW = ROOT / ".github" / "workflows" / "ci.yml"
RUN_RECEIPT_SWIFT = ROOT / "Sources" / "SurveillanceCore" / "RunReceipt.swift"
CAMPAIGN_PROGRESS_SWIFT = ROOT / "Sources" / "SurveillanceCore" / "CampaignProgress.swift"
MASTERY_PROGRESS_SWIFT = ROOT / "Sources" / "SurveillanceCore" / "MasteryProgress.swift"
CONTENT_SWIFT = {
    "weapons": ROOT / "Sources" / "SurveillanceCore" / "ContentCatalog.swift",
    "districts": ROOT / "Sources" / "SurveillanceCore" / "DistrictCatalog.swift",
    "waves": ROOT / "Sources" / "SurveillanceCore" / "WaveCatalog.swift",
    "enemies": ROOT / "Sources" / "SurveillanceCore" / "EnemyCatalog.swift",
    "upgrades": ROOT / "Sources" / "SurveillanceCore" / "UpgradeCatalog.swift",
    "bosses": ROOT / "Sources" / "SurveillanceCore" / "BossCatalog.swift",
    "suspicion": ROOT / "Sources" / "SurveillanceCore" / "SuspicionCatalog.swift",
    "audio_events": ROOT / "Sources" / "SurveillanceCore" / "AudioEventCatalog.swift",
}
SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
SWIFT_SCHEMA_RE = re.compile(
    r"(?:public\s+)?static\s+let\s+(?:schemaVersion|currentSchemaVersion)\s*=\s*(\d+)"
)


def fail(message: str) -> None:
    print(f"version-check: ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_positive_int(value: Any, field: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or value < 1:
        fail(f"{field} must be a positive integer; got {value!r}")
    return value


def require_semver(value: Any, field: str) -> str:
    if not isinstance(value, str) or SEMVER_RE.fullmatch(value) is None:
        fail(f"{field} must be numeric SemVer MAJOR.MINOR.PATCH; got {value!r}")
    return value


def project_setting(text: str, key: str) -> str:
    match = re.search(rf"^\s*{re.escape(key)}:\s*['\"]?([^'\"\s#]+)", text, re.MULTILINE)
    if match is None:
        fail(f"project.yml is missing {key}")
    return match.group(1)


def swift_schema_constant(path: Path, field: str) -> int:
    if not path.is_file():
        fail(f"{field}: missing Swift authority {path.relative_to(ROOT)}")
    text = path.read_text(encoding="utf-8")
    match = SWIFT_SCHEMA_RE.search(text)
    if match is None:
        fail(f"{field}: could not find schemaVersion/currentSchemaVersion in {path.name}")
    return int(match.group(1))


def require_run_receipt(value: Any) -> tuple[int, int]:
    if isinstance(value, dict):
        compat = require_positive_int(
            value.get("compatibility_version"),
            "compatibility.run_receipt.compatibility_version",
        )
        schema = require_positive_int(
            value.get("schema_version"),
            "compatibility.run_receipt.schema_version",
        )
        return compat, schema
    fail(
        "compatibility.run_receipt must be an object with "
        "compatibility_version and schema_version; "
        f"got {type(value).__name__}"
    )


def main() -> None:
    try:
        registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail("versions.json is missing")
    except json.JSONDecodeError as exc:
        fail(f"versions.json is invalid JSON: {exc}")

    project_text = PROJECT.read_text(encoding="utf-8")

    require_semver(registry.get("registry_schema_version"), "registry_schema_version")
    app = registry.get("app")
    if not isinstance(app, dict):
        fail("app must be an object")

    marketing = require_semver(app.get("marketing_version"), "app.marketing_version")
    build = require_positive_int(app.get("build_number"), "app.build_number")

    compatibility = registry.get("compatibility")
    if not isinstance(compatibility, dict):
        fail("compatibility must be an object")
    for key in ("simulation_protocol", "save_data", "content_catalog"):
        require_positive_int(compatibility.get(key), f"compatibility.{key}")
    receipt_compat, receipt_schema = require_run_receipt(compatibility.get("run_receipt"))

    persistence = registry.get("persistence")
    if not isinstance(persistence, dict):
        fail("persistence must be an object")
    campaign = require_positive_int(
        persistence.get("campaign_progress"), "persistence.campaign_progress"
    )
    mastery = require_positive_int(
        persistence.get("mastery_progress"), "persistence.mastery_progress"
    )
    envelope = require_positive_int(
        persistence.get("run_receipt_envelope"), "persistence.run_receipt_envelope"
    )
    if envelope != receipt_schema:
        fail(
            "persistence.run_receipt_envelope must match "
            f"compatibility.run_receipt.schema_version ({receipt_schema}); got {envelope}"
        )

    content_schemas = registry.get("content_schemas")
    if not isinstance(content_schemas, dict) or not content_schemas:
        fail("content_schemas must be a non-empty object")
    for key, value in content_schemas.items():
        require_positive_int(value, f"content_schemas.{key}")

    documents = registry.get("documents")
    if not isinstance(documents, dict) or not documents:
        fail("documents must be a non-empty object")
    for key, value in documents.items():
        require_semver(value, f"documents.{key}")

    if not isinstance(registry.get("updated_at"), str) or not registry["updated_at"]:
        fail("updated_at must be a non-empty ISO date string")
    if not isinstance(registry.get("change_reason"), str) or not registry["change_reason"]:
        fail("change_reason must be a non-empty string")
    if "notes" in registry:
        fail("notes is retired; use change_reason for version-focused registry updates")

    project_marketing = project_setting(project_text, "MARKETING_VERSION")
    project_build_raw = project_setting(project_text, "CURRENT_PROJECT_VERSION")
    try:
        project_build = int(project_build_raw)
    except ValueError:
        fail(f"CURRENT_PROJECT_VERSION must be an integer; got {project_build_raw!r}")

    if project_marketing != marketing:
        fail(
            "MARKETING_VERSION mismatch: "
            f"project.yml={project_marketing!r}, versions.json={marketing!r}"
        )
    if project_build != build:
        fail(
            "CURRENT_PROJECT_VERSION mismatch: "
            f"project.yml={project_build}, versions.json={build}"
        )

    swift_receipt = swift_schema_constant(RUN_RECEIPT_SWIFT, "RunReceipt.schemaVersion")
    if swift_receipt != receipt_schema:
        fail(
            "RunReceipt.schemaVersion mismatch: "
            f"Swift={swift_receipt}, versions.json schema_version={receipt_schema}"
        )

    swift_campaign = swift_schema_constant(
        CAMPAIGN_PROGRESS_SWIFT, "CampaignProgress.schemaVersion"
    )
    if swift_campaign != campaign:
        fail(
            "CampaignProgress.schemaVersion mismatch: "
            f"Swift={swift_campaign}, versions.json persistence.campaign_progress={campaign}"
        )
    swift_mastery = swift_schema_constant(
        MASTERY_PROGRESS_SWIFT, "MasteryProgress.schemaVersion"
    )
    if swift_mastery != mastery:
        fail(
            "MasteryProgress.schemaVersion mismatch: "
            f"Swift={swift_mastery}, versions.json persistence.mastery_progress={mastery}"
        )

    for family, path in CONTENT_SWIFT.items():
        if family not in content_schemas:
            fail(f"content_schemas missing required family {family!r}")
        swift_value = swift_schema_constant(path, f"{family}.currentSchemaVersion")
        registry_value = content_schemas[family]
        if swift_value != registry_value:
            fail(
                f"content_schemas.{family} mismatch: "
                f"Swift={swift_value}, versions.json={registry_value}"
            )

    if not CI_WORKFLOW.is_file():
        fail("CI workflow missing at .github/workflows/ci.yml")
    ci_text = CI_WORKFLOW.read_text(encoding="utf-8")
    if "make version-check" not in ci_text:
        fail("CI workflow must invoke `make version-check` on the core-tests job")

    # Canonical docs registered under documents.* must carry matching metadata.
    doc_paths = {
        "versioning_policy": ROOT / "docs" / "VERSIONING.md",
        "roguelike_benchmark_and_design_assimilation": ROOT
        / "docs"
        / "ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md",
    }
    for key, path in doc_paths.items():
        if key not in documents:
            fail(f"documents missing required key {key!r}")
        if not path.is_file():
            fail(f"documents.{key}: missing {path.relative_to(ROOT)}")
        text = path.read_text(encoding="utf-8")
        meta = re.search(
            r"```yaml\s*\nversion:\s*([0-9]+\.[0-9]+\.[0-9]+)\s*\n"
            r"status:\s*\S+\s*\n"
            r"last_updated:\s*\S+\s*\n"
            r"supersedes:\s*.+\n"
            r"superseded_by:\s*.+\n"
            r"authority_scope:\s*.+\n```",
            text,
        )
        if meta is None:
            fail(
                f"documents.{key}: {path.name} missing required YAML metadata block "
                "(version/status/last_updated/supersedes/superseded_by/authority_scope)"
            )
        if meta.group(1) != documents[key]:
            fail(
                f"documents.{key} mismatch: "
                f"{path.name} metadata={meta.group(1)!r}, versions.json={documents[key]!r}"
            )

    print(
        "version-check: OK "
        f"app={marketing}+{build} "
        f"simulation={compatibility['simulation_protocol']} "
        f"save={compatibility['save_data']} "
        f"receipt_compat={receipt_compat} "
        f"receipt_schema={receipt_schema} "
        f"content={compatibility['content_catalog']}"
    )


if __name__ == "__main__":
    main()
