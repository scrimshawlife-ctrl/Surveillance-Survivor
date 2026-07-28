#!/usr/bin/env python3
"""Validate gameplay animation manifest schema and authority boundaries."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "GAMEPLAY_ANIMATION_MANIFEST.json"
GAME_ASSET = ROOT / "Game" / "Rendering" / "GameAssetName.swift"
PLAYER_ATLAS = ROOT / "Game" / "Rendering" / "PlayerAtlasManifest.swift"

REQUIRED_CLIP_FIELDS = {
    "clip_id",
    "logical_stem",
    "family",
    "scope",
    "priority",
    "status",
    "target_frames",
    "notes",
}

CANONICAL_WEAPONS = {
    "kineticCountermeasure",
    "redactionOrdinance",
    "identityTransponder",
    "foiaSwarm",
    "mirrorArray",
    "signalFlood",
}

REQUIRED_PRESENTATION_RULES = {
    "sim_owns_transform": True,
    "animation_emits_gameplay_events": False,
    "sk_physics_for_hitboxes": False,
    "secondary_motion_bounded": True,
    "shape_fallback_required": True,
    "reduced_motion_required": True,
    "reduced_flash_required": True,
}


def fail(message: str) -> None:
    print(f"animation-manifest error: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    try:
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {MANIFEST.relative_to(ROOT)}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON: {exc}")

    if data.get("schema_version") != 1:
        fail("unsupported schema_version")

    if data.get("physics_doctrine") != "physics_informed_presentation_not_simulation":
        fail("physics_doctrine must be physics_informed_presentation_not_simulation")

    rules = data.get("presentation_rules") or {}
    for name, expected in REQUIRED_PRESENTATION_RULES.items():
        if rules.get(name) is not expected:
            fail(f"presentation_rules.{name} must be {str(expected).lower()}")

    statuses = set(data.get("status_values") or [])
    scopes = set(data.get("scope_values") or [])
    weapons = set(data.get("canonical_weapons") or [])
    if weapons != CANONICAL_WEAPONS:
        fail(f"canonical_weapons mismatch: {sorted(weapons)} vs {sorted(CANONICAL_WEAPONS)}")

    clips = data.get("clips")
    if not isinstance(clips, list) or not clips:
        fail("clips must be a non-empty list")

    ids: list[str] = []
    stems: list[str] = []
    for index, clip in enumerate(clips):
        if not isinstance(clip, dict):
            fail(f"clip {index} must be an object")
        missing = REQUIRED_CLIP_FIELDS - set(clip)
        if missing:
            fail(f"clip {index} missing fields: {sorted(missing)}")
        if clip["status"] not in statuses:
            fail(f"{clip['clip_id']} has invalid status {clip['status']}")
        if clip["scope"] not in scopes:
            fail(f"{clip['clip_id']} has invalid scope {clip['scope']}")
        if not re.fullmatch(r"P[0-3]", str(clip["priority"])):
            fail(f"{clip['clip_id']} priority must be P0 through P3")
        if not re.fullmatch(r"[a-z][a-z0-9_]*", str(clip["family"])):
            fail(f"{clip['clip_id']} family must be snake_case")
        frames = clip["target_frames"]
        if (
            not isinstance(frames, list)
            or len(frames) != 2
            or not all(isinstance(x, int) for x in frames)
            or frames[0] < 0
            or frames[1] < frames[0]
        ):
            fail(f"{clip['clip_id']} has invalid target_frames {frames}")
        stem = clip["logical_stem"]
        if not re.fullmatch(r"[a-z0-9_]+", stem):
            fail(f"{clip['clip_id']} logical_stem must be snake_case: {stem}")
        for bad in ("final", "copy", "alternate", "version2", "new"):
            if bad in stem.split("_"):
                fail(f"{clip['clip_id']} forbidden stem token: {bad}")
        weapon = clip.get("weapon")
        if weapon is not None and weapon not in CANONICAL_WEAPONS:
            fail(f"{clip['clip_id']} invents weapon {weapon}")
        if clip["status"] == "runtime_integrated" and clip["scope"] == "reserved":
            fail(f"{clip['clip_id']} reserved cannot be runtime_integrated")
        if clip["scope"] == "runtime_present" and clip["status"] in {"missing", "reserved", "deferred"}:
            fail(f"{clip['clip_id']} runtime_present cannot be {clip['status']}")
        if clip["scope"] == "reserved" and clip["status"] == "runtime_integrated":
            fail(f"{clip['clip_id']} reserved cannot be runtime_integrated")
        anchor = clip.get("anchor")
        if anchor is not None and (
            not isinstance(anchor, list)
            or len(anchor) != 2
            or not all(isinstance(value, (int, float)) and 0 <= value <= 1 for value in anchor)
        ):
            fail(f"{clip['clip_id']} anchor must be two normalized coordinates")
        ids.append(clip["clip_id"])
        stems.append(stem)

    if len(ids) != len(set(ids)):
        fail(f"duplicate clip_id: {sorted({i for i in ids if ids.count(i) > 1})}")
    if len(stems) != len(set(stems)):
        fail(f"duplicate logical_stem: {sorted({s for s in stems if stems.count(s) > 1})}")

    # Player presentation claims must resolve to the authoritative atlas, including
    # actual multi-frame availability rather than notes or target aspirations.
    game_asset = GAME_ASSET.read_text(encoding="utf-8") if GAME_ASSET.exists() else ""
    atlas = PLAYER_ATLAS.read_text(encoding="utf-8") if PLAYER_ATLAS.exists() else ""
    for clip in clips:
        if clip["family"] != "player":
            continue
        if clip["status"] not in {"single_frame_present", "multi_frame_present", "runtime_integrated"}:
            continue
        stem = clip["logical_stem"]
        if stem not in game_asset and stem not in atlas:
            fail(f"player clip {clip['clip_id']} marked present but stem not found in GameAssetName/PlayerAtlas")
        if clip["status"] == "multi_frame_present":
            asset_case = re.search(rf'static let (\w+) = "{re.escape(stem)}"', game_asset)
            if asset_case is None:
                fail(f"player clip {clip['clip_id']} has no GameAssetName declaration")
            sequence = re.search(
                rf"assetName: GameAssetName\.Player\.{asset_case.group(1)}, frameCount: (\d+)",
                atlas,
            )
            if sequence is None or int(sequence.group(1)) < 2:
                fail(f"player clip {clip['clip_id']} marked multi_frame_present without at least two atlas frames")

    # Architecture clips must not claim multi_frame art.
    for clip in clips:
        if clip["scope"] == "architecture" and clip["status"] in {
            "single_frame_present",
            "multi_frame_present",
            "runtime_integrated",
        }:
            if clip["target_frames"] != [0, 0]:
                fail(f"architecture clip {clip['clip_id']} should use target_frames [0,0]")

    present = sum(
        1
        for c in clips
        if c["status"] in {"single_frame_present", "multi_frame_present", "runtime_integrated", "procedural_only"}
    )
    print(
        "animation-check: PASS — "
        f"{len(clips)} clips, {present} non-missing statuses, "
        f"physics_informed, 6 weapons"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
