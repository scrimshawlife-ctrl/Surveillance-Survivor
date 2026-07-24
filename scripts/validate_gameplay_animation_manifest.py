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
    if rules.get("sim_owns_transform") is not True:
        fail("presentation_rules.sim_owns_transform must be true")
    if rules.get("animation_emits_gameplay_events") is not False:
        fail("presentation_rules.animation_emits_gameplay_events must be false")
    if rules.get("sk_physics_for_hitboxes") is not False:
        fail("presentation_rules.sk_physics_for_hitboxes must be false")

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
        ids.append(clip["clip_id"])
        stems.append(stem)

    if len(ids) != len(set(ids)):
        fail(f"duplicate clip_id: {sorted({i for i in ids if ids.count(i) > 1})}")
    if len(stems) != len(set(stems)):
        fail(f"duplicate logical_stem: {sorted({s for s in stems if stems.count(s) > 1})}")

    # Player single-frame stems must exist in GameAssetName / atlas when marked present.
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
