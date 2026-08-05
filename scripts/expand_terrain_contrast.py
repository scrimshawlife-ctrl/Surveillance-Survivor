#!/usr/bin/env python3
"""Expand the tonal range of the terrain tiles so their detail is visible.

The regeneration prompt asked for a mean luminance of 150-190 with "detail
within ~25 of the mean". The generator honoured the mean and treated the detail
clause as a ceiling, so all twenty tiles arrived at mean 169.5 with a standard
deviation of 4-11 — visually flat. Rendered as a full-coverage floor they read
as plain grey, which is what the operator reported.

The detail is present, just compressed into a narrow band. This stretches each
tile's luminance around its own mean until it reaches a target spread, scaling
the RGB channels together so hue and the city's colour identity survive. The
mean is preserved, so the contrast the entities rely on does not move.

This amplifies detail that exists; it does not invent any. Tiles that already
carry contrast are left alone. Regenerating with a *minimum* detail requirement
is the real fix — see GROUND_VALUE in generate_visual_asset_prompts.py.
"""

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RUNTIME = ROOT / "Resources/RuntimeSprites"
XCASSETS = ROOT / "Resources/Assets.xcassets"

# Spread that reads as a surface at gameplay zoom without turning into noise.
TARGET_SD = 18.0
# Beyond this the stretch starts quantising the source's smooth gradients.
MAX_GAIN = 4.0
# Headroom around the 150-190 mean band. Wider than the authored band on
# purpose: the band constrains the *mean*, and detail needs room either side.
FLOOR, CEIL = 120.0, 215.0

R, G, B = 0.2126, 0.7152, 0.0722


def luminance(px):
    return R * px[0] + G * px[1] + B * px[2]


def stats(img):
    px = img.load()
    w, h = img.size
    vals = [luminance(px[x, y]) for y in range(0, h, 3) for x in range(0, w, 3)]
    mean = sum(vals) / len(vals)
    sd = (sum((v - mean) ** 2 for v in vals) / len(vals)) ** 0.5
    return mean, sd


def expand(path: Path, apply: bool) -> str:
    img = Image.open(path)
    alpha = img.getchannel("A") if img.mode == "RGBA" else None
    rgb = img.convert("RGB")
    mean, sd = stats(rgb)
    if sd >= 12.0:
        return f"{path.name}: sd={sd:.1f} already reads, left alone"

    gain = min(MAX_GAIN, TARGET_SD / sd) if sd > 0.01 else 1.0
    px = rgb.load()
    w, h = rgb.size
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            lum = R * r + G * g + B * b
            if lum <= 0.5:
                continue
            target = max(FLOOR, min(CEIL, mean + (lum - mean) * gain))
            k = target / lum
            px[x, y] = (
                min(255, int(r * k + 0.5)),
                min(255, int(g * k + 0.5)),
                min(255, int(b * k + 0.5)),
            )

    new_mean, new_sd = stats(rgb)
    out = rgb.convert("RGBA")
    if alpha is not None:
        out.putalpha(alpha)
    if apply:
        out.save(path)
        mirror = XCASSETS / f"{path.stem}.imageset" / path.name
        if mirror.parent.exists():
            out.save(mirror)
    return (
        f"{path.name}: gain x{gain:.2f}  sd {sd:.1f}->{new_sd:.1f}  "
        f"mean {mean:.1f}->{new_mean:.1f}"
    )


def main() -> int:
    apply = "--apply" in sys.argv
    targets = sorted(RUNTIME.glob("*terrain*.png")) + sorted(RUNTIME.glob("env_tile_*.png"))
    if not targets:
        print("no terrain tiles found")
        return 1
    for path in targets:
        print(f"  {expand(path, apply)}")
    print(f"\n{'applied to' if apply else 'dry run over'} {len(targets)} tile(s)")
    if not apply:
        print("re-run with --apply to write")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
