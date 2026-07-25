#!/usr/bin/env python3
"""Fail if runtime sprites still carry large magenta chroma plates (Hallmark C1)."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPRITE_DIR = ROOT / "Resources" / "RuntimeSprites"

# Max fraction of opaque-ish magenta plate pixels allowed (non-opaque families).
MAX_MAGENTA_FRAC = 0.05
# Corner samples that look keyed.
MAX_KEYED_CORNERS = 1

SKIP_OPAQUE = (
    "_terrain_",
    "_skyline_",
    "env_tile_",
    "env_parallax_",
    "env_obstacle_",
)

# Intentional pink/magenta design accents (glyphs only).
ALLOW_ACCENT = (
    "suspicion_tier_",
)


def is_magenta_key(r: int, g: int, b: int, a: int) -> bool:
    if a < 20:
        return False
    if r >= 160 and b >= 130 and g <= 145 and (r - g) >= 35 and (b - g) >= 15:
        return True
    if r >= 170 and g <= 110 and b >= 90 and (r - g) >= 55:
        return True
    return False


def fail(msg: str) -> None:
    print(f"sprite-chroma-check: ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if not SPRITE_DIR.is_dir():
        fail(f"missing {SPRITE_DIR}")
    offenders: list[str] = []
    checked = 0
    for path in sorted(SPRITE_DIR.glob("*.png")):
        name = path.name
        if any(s in name for s in SKIP_OPAQUE):
            continue
        if any(name.startswith(a) for a in ALLOW_ACCENT):
            continue
        im = Image.open(path).convert("RGBA")
        w, h = im.size
        px = im.load()
        mag = 0
        total = w * h
        # subsample for speed on large sheets
        step = max(1, min(w, h) // 128)
        samples = 0
        for y in range(0, h, step):
            for x in range(0, w, step):
                samples += 1
                if is_magenta_key(*px[x, y]):
                    mag += 1
        frac = mag / max(1, samples)
        corners = [
            px[0, 0],
            px[w - 1, 0],
            px[0, h - 1],
            px[w - 1, h - 1],
        ]
        keyed_corners = sum(1 for c in corners if is_magenta_key(*c))
        checked += 1
        if frac > MAX_MAGENTA_FRAC or keyed_corners > MAX_KEYED_CORNERS:
            offenders.append(f"{name} mag≈{frac:.3f} keyed_corners={keyed_corners}")

    if offenders:
        for line in offenders[:30]:
            print(f"sprite-chroma-check: ERROR: {line}", file=sys.stderr)
        if len(offenders) > 30:
            print(f"... and {len(offenders) - 30} more", file=sys.stderr)
        raise SystemExit(1)

    print(f"sprite-chroma-check: OK checked={checked} max_magenta_frac={MAX_MAGENTA_FRAC}")


if __name__ == "__main__":
    main()
