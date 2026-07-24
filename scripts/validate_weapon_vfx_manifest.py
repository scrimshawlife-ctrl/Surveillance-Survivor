#!/usr/bin/env python3
"""Validate the weapon/projectile/VFX production manifest against repo contracts."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "WEAPON_VFX_ASSET_MANIFEST.json"
GAME_ASSET_NAMES = ROOT / "Game" / "Rendering" / "GameAssetName.swift"
VISUAL_ASSET_MAP = ROOT / "Game" / "Rendering" / "VisualAssetMap.swift"

EXPECTED_RUNTIME_STEMS = {
    "projectile_default",
    "deployable_mirror_array",
    "deployable_signal_flood",
}

EXPECTED_WEAPONS = {
    "kineticCountermeasure",
    "redactionOrdinance",
    "identityTransponder",
    "foiaSwarm",
    "mirrorArray",
    "signalFlood",
}

REQUIRED_FIELDS = {
    "asset_id",
    "logical_stem",
    "scope",
    "priority",
    "family",
    "weapon",
    "canvas",
    "anchor",
    "frames",
    "loop",
    "status",
    "reuse_status",
    "prompt",
}

STEM_RE = re.compile(r"^[a-z0-9]+(?:_[a-z0-9]+)*$")


def fail(message: str) -> None:
    print(f"weapon-vfx-check: ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {path.relative_to(ROOT)}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path.relative_to(ROOT)}: {exc}")


def main() -> None:
    data = load_json(MANIFEST)
    if data.get("schema_version") != 1:
        fail("unsupported schema_version; expected 1")

    statuses = set(data.get("status_values", []))
    reuse_values = set(data.get("reuse_values", []))
    if not statuses or not reuse_values:
        fail("status_values and reuse_values must be non-empty")

    assets = data.get("assets")
    if not isinstance(assets, list) or not assets:
        fail("assets must be a non-empty list")

    ids: set[str] = set()
    stems: set[str] = set()
    runtime_stems: set[str] = set()
    covered_weapons: set[str] = set()

    for index, asset in enumerate(assets):
        if not isinstance(asset, dict):
            fail(f"assets[{index}] is not an object")
        missing = REQUIRED_FIELDS - set(asset)
        if missing:
            fail(f"assets[{index}] missing fields: {sorted(missing)}")

        asset_id = asset["asset_id"]
        stem = asset["logical_stem"]
        if not isinstance(asset_id, str) or not asset_id:
            fail(f"assets[{index}].asset_id must be non-empty")
        if asset_id in ids:
            fail(f"duplicate asset_id: {asset_id}")
        ids.add(asset_id)

        if not isinstance(stem, str) or not STEM_RE.fullmatch(stem):
            fail(f"invalid logical_stem: {stem!r}")
        if stem in stems:
            fail(f"duplicate logical_stem: {stem}")
        stems.add(stem)

        if asset["status"] not in statuses:
            fail(f"{asset_id}: invalid status {asset['status']!r}")
        if asset["reuse_status"] not in reuse_values:
            fail(f"{asset_id}: invalid reuse_status {asset['reuse_status']!r}")

        canvas = asset["canvas"]
        anchor = asset["anchor"]
        if (
            not isinstance(canvas, list)
            or len(canvas) != 2
            or not all(isinstance(v, int) and v > 0 for v in canvas)
        ):
            fail(f"{asset_id}: canvas must be [positive_int, positive_int]")
        if (
            not isinstance(anchor, list)
            or len(anchor) != 2
            or not all(isinstance(v, (int, float)) and 0 <= v <= 1 for v in anchor)
        ):
            fail(f"{asset_id}: anchor must be two values in 0...1")
        if not isinstance(asset["frames"], int) or asset["frames"] < 1:
            fail(f"{asset_id}: frames must be a positive integer")
        if not isinstance(asset["loop"], bool):
            fail(f"{asset_id}: loop must be boolean")
        if not isinstance(asset["prompt"], str) or len(asset["prompt"].strip()) < 24:
            fail(f"{asset_id}: prompt is missing or too short")

        weapon = asset["weapon"]
        if weapon is not None:
            if weapon not in EXPECTED_WEAPONS:
                fail(f"{asset_id}: unknown or deferred weapon {weapon!r}")
            covered_weapons.add(weapon)

        scope = asset["scope"]
        if scope == "runtime_addressable":
            runtime_stems.add(stem)
            if asset["reuse_status"] == "RESERVED_INTEGRATION":
                fail(f"{asset_id}: runtime asset cannot be RESERVED_INTEGRATION")
        elif scope != "reserved":
            fail(f"{asset_id}: invalid scope {scope!r}")

        if asset["status"] == "runtime_integrated" and scope != "runtime_addressable":
            fail(f"{asset_id}: reserved asset cannot claim runtime_integrated")

    if runtime_stems != EXPECTED_RUNTIME_STEMS:
        fail(
            "runtime_addressable stems drifted; "
            f"expected {sorted(EXPECTED_RUNTIME_STEMS)}, got {sorted(runtime_stems)}"
        )

    if covered_weapons != EXPECTED_WEAPONS:
        fail(
            "manifest does not cover the canonical six-weapon roster; "
            f"missing {sorted(EXPECTED_WEAPONS - covered_weapons)}"
        )

    game_asset_text = GAME_ASSET_NAMES.read_text(encoding="utf-8")
    visual_map_text = VISUAL_ASSET_MAP.read_text(encoding="utf-8")
    for stem in EXPECTED_RUNTIME_STEMS:
        if f'"{stem}"' not in game_asset_text:
            fail(f"GameAssetName.swift does not register {stem}")

    required_roles = {"projectileDefault", "mirrorArray", "signalFlood"}
    missing_roles = {role for role in required_roles if f"case {role}" not in visual_map_text}
    if missing_roles:
        fail(f"VisualAssetMap.swift missing roles: {sorted(missing_roles)}")

    print(
        "weapon-vfx-check: PASS — "
        f"{len(assets)} assets, {len(runtime_stems)} runtime roles, "
        f"{len(covered_weapons)} canonical weapons"
    )


if __name__ == "__main__":
    main()
