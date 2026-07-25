#!/usr/bin/env python3
"""Re-key magenta / hot-pink chroma plates to true alpha for runtime sprites.

Used for Hallmark remediation C1. Skips character combat heroes that use intentional
cyan/red accents without magenta plates, and fully-opaque terrain/skylines.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DIR = ROOT / "Resources" / "RuntimeSprites"

# Families that may intentionally carry pink accents — only rekey if corners are keyed.
CONSERVATIVE_PREFIXES = (
    "player_",
    "guard_",
    "boss_",
    "lpr_",
    "projectile_",
    "deployable_",
    "suspicion_",
    "blind_spot",
)

# Always-skip full plates that should stay opaque.
OPAQUE_HINTS = (
    "_terrain_",
    "_skyline_",
    "env_tile_",
    "env_parallax_",
    "env_obstacle_",
)


def is_magenta_key(r: int, g: int, b: int, a: int) -> bool:
    if a < 8:
        return False
    # Classic chroma pink / magenta plate
    if r >= 160 and b >= 130 and g <= 145 and (r - g) >= 35 and (b - g) >= 15:
        return True
    # Hot pink plate (SF fog style)
    if r >= 170 and g <= 110 and b >= 90 and (r - g) >= 55:
        return True
    return False


def key_distance(r: int, g: int, b: int) -> float:
    # Distance toward pure magenta (255,0,255) and hot pink (220,40,150)
    d1 = ((r - 255) ** 2 + (g - 0) ** 2 + (b - 255) ** 2) ** 0.5
    d2 = ((r - 220) ** 2 + (g - 40) ** 2 + (b - 150) ** 2) ** 0.5
    return min(d1, d2)


def corner_is_keyed(im: Image.Image) -> bool:
    w, h = im.size
    samples = [
        im.getpixel((0, 0)),
        im.getpixel((w - 1, 0)),
        im.getpixel((0, h - 1)),
        im.getpixel((w - 1, h - 1)),
        im.getpixel((max(0, w // 2), 0)),
        im.getpixel((0, max(0, h // 2))),
    ]
    return sum(1 for p in samples if is_magenta_key(*p)) >= 2


def should_process(path: Path, force: bool) -> bool:
    name = path.name
    if any(h in name for h in OPAQUE_HINTS):
        return False
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    mag = 0
    for y in range(0, h, max(1, h // 64)):
        for x in range(0, w, max(1, w // 64)):
            if is_magenta_key(*px[x, y]):
                mag += 1
    # coarse sample fraction
    samples = max(1, (h // max(1, h // 64) + 1) * (w // max(1, w // 64) + 1))
    frac = mag / samples
    corner = corner_is_keyed(im)
    if force:
        return frac > 0.01 or corner
    if name.startswith(CONSERVATIVE_PREFIXES) or any(name.startswith(p) for p in CONSERVATIVE_PREFIXES):
        return corner and frac > 0.05
    return corner or frac > 0.08


def rekey_image(im: Image.Image) -> tuple[Image.Image, float]:
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    changed = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            if is_magenta_key(r, g, b, a):
                # Soft edge by distance
                dist = key_distance(r, g, b)
                if dist < 90:
                    px[x, y] = (r, g, b, 0)
                    changed += 1
                elif dist < 140:
                    fade = int(a * (dist - 90) / 50)
                    px[x, y] = (r, g, b, max(0, min(a, fade)))
                    changed += 1
    return im, changed / max(1, w * h)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", type=Path, default=DEFAULT_DIR)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--write-report", type=Path, default=None)
    args = parser.parse_args()

    paths = sorted(args.dir.glob("*.png"))
    processed: list[str] = []
    skipped = 0
    for path in paths:
        if not should_process(path, force=args.force):
            skipped += 1
            continue
        im = Image.open(path).convert("RGBA")
        out, frac = rekey_image(im)
        if frac < 0.005:
            skipped += 1
            continue
        processed.append(f"{path.name}: rekeyed_frac={frac:.3f}")
        if not args.dry_run:
            out.save(path, format="PNG", optimize=True)
        print(f"rekey: {path.name} frac={frac:.3f}")

    if args.write_report:
        args.write_report.write_text(
            "\n".join(processed) + f"\n# processed={len(processed)} skipped={skipped}\n",
            encoding="utf-8",
        )
    print(f"rekey_magenta_sprites: processed={len(processed)} skipped={skipped} dry_run={args.dry_run}")
    if not processed and not args.dry_run:
        # Not a failure — inventory may already be clean.
        pass


if __name__ == "__main__":
    main()
