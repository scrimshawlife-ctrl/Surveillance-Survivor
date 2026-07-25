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
SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")


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
    for key in ("simulation_protocol", "save_data", "run_receipt", "content_catalog"):
        require_positive_int(compatibility.get(key), f"compatibility.{key}")

    documents = registry.get("documents")
    if not isinstance(documents, dict) or not documents:
        fail("documents must be a non-empty object")
    for key, value in documents.items():
        require_semver(value, f"documents.{key}")

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

    print(
        "version-check: OK "
        f"app={marketing}+{build} "
        f"simulation={compatibility['simulation_protocol']} "
        f"save={compatibility['save_data']} "
        f"receipt={compatibility['run_receipt']} "
        f"content={compatibility['content_catalog']}"
    )


if __name__ == "__main__":
    main()
