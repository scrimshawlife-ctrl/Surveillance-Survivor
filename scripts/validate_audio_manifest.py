#!/usr/bin/env python3
"""Validate the audio production manifest and its runtime catalog boundary."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "AUDIO_ASSET_MANIFEST.json"
RUNTIME_CATALOG = (
    ROOT
    / "Sources"
    / "SurveillanceCore"
    / "Resources"
    / "Content"
    / "audio_events.json"
)

REQUIRED_ENTRY_FIELDS = {
    "asset_id",
    "logical_stem",
    "filename",
    "scope",
    "category",
    "bus",
    "loop",
    "duration_target",
    "variant_count",
    "status",
    "integration_target",
    "prompt",
}

DELIVERY_ROOT = ROOT / "Resources" / "Audio" / "Delivery"
DELIVERY_PATH_PREFIX = ("Resources", "Audio", "Delivery")
DELIVERY_STATUSES = {"derived_delivery", "runtime_integrated"}
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")


class ValidationError(Exception):
    """A closed validation failure suitable for CLI and focused unit tests."""


def fail(message: str) -> None:
    raise ValidationError(message)


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {display_path(path)}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {display_path(path)}: {exc}")


def scene_assets(catalog: dict) -> set[str]:
    """Assets referenced by the schema-2 scenes section.

    Looping ambience and music are addressed by state projection rather than by
    cues, so the runtime boundary has to count them too or they would drift
    unnoticed.
    """
    scenes = catalog.get("scenes") or {}
    names: set[str] = set()
    for district in scenes.get("districts", []):
        for key in ("foundationAsset", "ambienceAsset", "runAsset", "bossAsset"):
            if district.get(key):
                names.add(district[key])
        names.update(district.get("bossPhaseAssets") or [])
    for key in ("overlayExtractionAsset", "scanSweepAsset"):
        if scenes.get(key):
            names.add(scenes[key])
    return names


def assert_unique(entries: list[dict], field: str) -> None:
    values = [entry.get(field) for entry in entries]
    duplicates = sorted({value for value in values if values.count(value) > 1})
    if duplicates:
        fail(f"duplicate {field}: {duplicates}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def delivery_claims(entries: list[dict], delivery_root: Path) -> dict[Path, dict]:
    claims: dict[Path, dict] = {}
    seen_paths: set[str] = set()

    for entry in entries:
        asset_id = entry["asset_id"]
        delivery_path = entry.get("delivery_path")
        delivery_hash = entry.get("delivery_sha256")
        claims_delivery = entry["status"] in DELIVERY_STATUSES

        if claims_delivery and not delivery_path:
            fail(f"entry {asset_id} claims delivery status without delivery_path")
        if claims_delivery and not delivery_hash:
            fail(f"entry {asset_id} claims delivery status without delivery_sha256")
        if not delivery_path:
            continue

        relative = PurePosixPath(delivery_path)
        if (
            relative.is_absolute()
            or ".." in relative.parts
            or tuple(relative.parts[:3]) != DELIVERY_PATH_PREFIX
            or len(relative.parts) <= len(DELIVERY_PATH_PREFIX)
        ):
            fail(f"entry {asset_id} has invalid delivery_path {delivery_path}")
        if relative.suffix != ".caf":
            fail(f"entry {asset_id} delivery_path must end in .caf")
        if relative.name != f"{entry['logical_stem']}.caf":
            fail(f"entry {asset_id} delivery filename/stem mismatch")
        if not isinstance(delivery_hash, str) or not SHA256_PATTERN.fullmatch(delivery_hash):
            fail(f"entry {asset_id} has invalid delivery_sha256")

        normalized = relative.as_posix()
        if normalized in seen_paths:
            fail(f"duplicate delivery_path: {normalized}")
        seen_paths.add(normalized)
        actual = delivery_root.joinpath(*relative.parts[len(DELIVERY_PATH_PREFIX):])
        claims[actual] = entry

    return claims


def validate_delivery_files(entries: list[dict], delivery_root: Path) -> int:
    delivery_root = delivery_root.resolve()
    claims = delivery_claims(entries, delivery_root)

    if not delivery_root.is_dir():
        fail(f"missing delivery directory {display_path(delivery_root)}")

    discovered: set[Path] = set()
    for path in sorted(delivery_root.rglob("*")):
        if path.is_symlink():
            fail(f"delivery resource must not be a symlink: {display_path(path)}")
        if not path.is_file():
            continue
        # XcodeGen explicitly excludes these tracked directory markers from the
        # resource phase. They are repository structure, not delivery assets.
        if path.name == ".gitkeep":
            continue
        discovered.add(path)
        if path.name.startswith("."):
            fail(f"placeholder file is forbidden in delivery resources: {display_path(path)}")
        if path.stat().st_size == 0:
            fail(f"zero-byte delivery resource: {display_path(path)}")
        if path.suffix != ".caf":
            fail(f"unexpected delivery extension: {display_path(path)}")
        if path not in claims:
            fail(f"unmanifested delivery resource: {display_path(path)}")

    for path, entry in sorted(claims.items(), key=lambda item: str(item[0])):
        if path not in discovered:
            fail(f"missing delivery resource for {entry['asset_id']}: {display_path(path)}")
        actual_hash = sha256(path)
        if actual_hash != entry["delivery_sha256"]:
            fail(
                f"delivery hash mismatch for {entry['asset_id']}: "
                f"expected {entry['delivery_sha256']}, got {actual_hash}"
            )

    return len(discovered)


def validate_audio_manifest(
    manifest_path: Path = MANIFEST,
    runtime_catalog_path: Path = RUNTIME_CATALOG,
    delivery_root: Path = DELIVERY_ROOT,
) -> tuple[int, int, int]:
    manifest = load_json(manifest_path)
    runtime = load_json(runtime_catalog_path)

    if manifest.get("schema_version") != 1:
        fail("unsupported manifest schema_version")

    statuses = set(manifest.get("status_values", []))
    if not statuses:
        fail("status_values must not be empty")

    entries = manifest.get("assets")
    if not isinstance(entries, list) or not entries:
        fail("assets must be a non-empty list")

    for index, entry in enumerate(entries):
        missing = REQUIRED_ENTRY_FIELDS - set(entry)
        if missing:
            fail(f"entry {index} missing fields: {sorted(missing)}")
        if entry["status"] not in statuses:
            fail(f"entry {entry['asset_id']} has unsupported status {entry['status']}")
        if not isinstance(entry["variant_count"], int) or entry["variant_count"] < 1:
            fail(f"entry {entry['asset_id']} has invalid variant_count")
        if not entry["filename"].endswith(".wav"):
            fail(f"entry {entry['asset_id']} master filename must end in .wav")
        if entry["filename"] != f"{entry['logical_stem']}.wav":
            fail(f"entry {entry['asset_id']} filename/stem mismatch")
        if not entry["prompt"].strip():
            fail(f"entry {entry['asset_id']} has empty prompt")

    for field in ("asset_id", "logical_stem", "filename"):
        assert_unique(entries, field)

    runtime_stems = {cue["assetName"] for cue in runtime.get("cues", [])}
    runtime_stems |= scene_assets(runtime)
    required_stems = {
        entry["logical_stem"]
        for entry in entries
        if entry["scope"] == "runtime_required"
    }

    if required_stems != runtime_stems:
        missing_from_manifest = sorted(runtime_stems - required_stems)
        extra_runtime_claims = sorted(required_stems - runtime_stems)
        fail(
            "runtime boundary drift; "
            f"missing_from_manifest={missing_from_manifest}, "
            f"extra_runtime_claims={extra_runtime_claims}"
        )

    reserved_integrated = [
        entry["asset_id"]
        for entry in entries
        if entry["scope"] != "runtime_required"
        and entry["status"] == "runtime_integrated"
    ]
    if reserved_integrated:
        fail(
            "reserved assets claim runtime integration without catalog authority: "
            f"{reserved_integrated}"
        )

    delivery_count = validate_delivery_files(entries, delivery_root)

    return len(entries), len(runtime_stems), delivery_count


def main() -> int:
    try:
        entry_count, runtime_count, delivery_count = validate_audio_manifest()
    except ValidationError as exc:
        print(f"audio-manifest error: {exc}", file=sys.stderr)
        return 1

    print(
        "audio manifest valid: "
        f"{entry_count} assets, {runtime_count} runtime-required stems, "
        f"{delivery_count} verified delivery files"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
