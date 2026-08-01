#!/usr/bin/env python3
"""Fail closed when shipping audio lacks verified chain-of-title metadata."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "AUDIO_ASSET_MANIFEST.json"
LEDGER = ROOT / "docs" / "audio" / "rights" / "AUDIO_RIGHTS_LEDGER.json"
SHA256 = re.compile(r"^[a-f0-9]{64}$")
SHIPPING_STATUSES = {"approved_master", "derived_delivery", "runtime_integrated"}


def load(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"ERROR missing required file: {path.relative_to(ROOT)}")
    except json.JSONDecodeError as exc:
        raise SystemExit(f"ERROR invalid JSON in {path.relative_to(ROOT)}: {exc}")
    if not isinstance(value, dict):
        raise SystemExit(f"ERROR root must be an object: {path.relative_to(ROOT)}")
    return value


def main() -> int:
    manifest = load(MANIFEST)
    ledger = load(LEDGER)
    errors: list[str] = []

    evidence = {
        item.get("evidence_id"): item
        for item in ledger.get("evidence", [])
        if isinstance(item, dict) and item.get("evidence_id")
    }
    rights_assets = {
        item.get("asset_id"): item
        for item in ledger.get("assets", [])
        if isinstance(item, dict) and item.get("asset_id")
    }

    for ev_id, item in evidence.items():
        digest = item.get("sha256")
        if not isinstance(digest, str) or not SHA256.fullmatch(digest):
            errors.append(f"evidence {ev_id}: invalid sha256")

    shipping = [
        item for item in manifest.get("assets", [])
        if isinstance(item, dict) and item.get("status") in SHIPPING_STATUSES
    ]

    for asset in shipping:
        asset_id = asset.get("asset_id")
        if not asset_id:
            errors.append("manifest shipping asset missing asset_id")
            continue
        record = rights_assets.get(asset_id)
        if record is None:
            errors.append(f"{asset_id}: missing rights ledger record")
            continue

        manifest_hash = asset.get("master_sha256")
        ledger_hash = record.get("master_sha256")
        if not isinstance(manifest_hash, str) or not SHA256.fullmatch(manifest_hash):
            errors.append(f"{asset_id}: manifest master_sha256 missing or invalid")
        elif ledger_hash != manifest_hash:
            errors.append(f"{asset_id}: rights ledger hash does not match manifest")

        if record.get("rights_status") != "cleared":
            errors.append(f"{asset_id}: rights_status is not cleared")
        if record.get("third_party_ip_review") != "passed":
            errors.append(f"{asset_id}: third_party_ip_review is not passed")
        if record.get("commercial_use") != "allowed":
            errors.append(f"{asset_id}: commercial_use is not allowed")
        if record.get("beta_status") == "unknown":
            errors.append(f"{asset_id}: beta_status is unknown")

        evidence_ids = record.get("evidence_ids")
        if not isinstance(evidence_ids, list) or not evidence_ids:
            errors.append(f"{asset_id}: no evidence_ids")
        else:
            for ev_id in evidence_ids:
                ev = evidence.get(ev_id)
                if ev is None:
                    errors.append(f"{asset_id}: unknown evidence_id {ev_id}")
                elif ev.get("verification_status") != "verified":
                    errors.append(f"{asset_id}: evidence {ev_id} is not verified")

        if record.get("source_class") == "ai_generated":
            for field in ("product_or_model", "plan_or_license", "terms_version"):
                if not record.get(field):
                    errors.append(f"{asset_id}: AI-generated asset missing {field}")

    extra = sorted(set(rights_assets) - {a.get("asset_id") for a in manifest.get("assets", []) if isinstance(a, dict)})
    for asset_id in extra:
        errors.append(f"{asset_id}: ledger record has no manifest asset")

    if errors:
        print("AUDIO RIGHTS GATE: BLOCKED")
        for error in sorted(errors):
            print(f"- {error}")
        print(f"\n{len(errors)} blocker(s); {len(shipping)} shipping asset(s) inspected.")
        return 1

    print(f"AUDIO RIGHTS GATE: PASS — {len(shipping)} shipping asset(s) cleared.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
