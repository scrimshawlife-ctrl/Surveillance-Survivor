#!/usr/bin/env python3
"""Ingest a generated landmark image into RuntimeSprites + Assets.xcassets."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "Resources" / "RuntimeSprites"
XCASSETS = ROOT / "Resources" / "Assets.xcassets"
SIZES = ROOT / "docs" / "art" / "LANDMARK_TOPDOWN_SIZES.json"


def strip_bg(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r + g + b < 18:
                px[x, y] = (0, 0, 0, 0)
            elif r > 248 and g > 248 and b > 248:
                px[x, y] = (0, 0, 0, 0)
            elif r >= 160 and b >= 120 and g <= 145 and (r - g) >= 35:
                px[x, y] = (r, g, b, 0)
    return im


def tight_crop(im: Image.Image, pad: int = 6) -> Image.Image:
    bbox = im.split()[-1].getbbox()
    if not bbox:
        return im
    l, t, r, b = bbox
    return im.crop(
        (max(0, l - pad), max(0, t - pad), min(im.width, r + pad), min(im.height, b + pad))
    )


def fit_nearest(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    im = im.copy()
    im.thumbnail(size, Image.Resampling.NEAREST)
    canvas.paste(im, ((size[0] - im.width) // 2, (size[1] - im.height) // 2), im)
    return canvas


def write_imageset(name: str, im: Image.Image) -> None:
    imageset = XCASSETS / f"{name}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    filename = f"{name}.png"
    im.save(imageset / filename, format="PNG", optimize=True)
    contents = {
        "images": [
            {"filename": filename, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", required=True, type=Path)
    parser.add_argument("--name", required=True, help="basename without .png")
    parser.add_argument("--width", type=int, default=0)
    parser.add_argument("--height", type=int, default=0)
    args = parser.parse_args()

    sizes = json.loads(SIZES.read_text(encoding="utf-8")) if SIZES.exists() else {}
    key = f"{args.name}.png"
    if args.width and args.height:
        size = (args.width, args.height)
    elif key in sizes:
        size = (sizes[key]["w"], sizes[key]["h"])
    else:
        # fall back to existing runtime size
        existing = RUNTIME / key
        if existing.exists():
            size = Image.open(existing).size
        else:
            size = (256, 256)

    im = Image.open(args.src).convert("RGBA")
    im = fit_nearest(tight_crop(strip_bg(im)), size)
    dest = RUNTIME / key
    im.save(dest, format="PNG", optimize=True)
    write_imageset(args.name, im)
    print(f"ingest: {key} -> {size[0]}x{size[1]}")


if __name__ == "__main__":
    main()
