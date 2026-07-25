#!/usr/bin/env python3
"""Fail if runtime sprites still carry large magenta chroma plates (Hallmark C1).

Stdlib-only (no Pillow) so CI runners without PIL still pass.
"""

from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPRITE_DIR = ROOT / "Resources" / "RuntimeSprites"

MAX_MAGENTA_FRAC = 0.05
MAX_KEYED_CORNERS = 1

SKIP_OPAQUE = (
    "_terrain_",
    "_skyline_",
    "env_tile_",
    "env_parallax_",
    "env_obstacle_",
)
ALLOW_ACCENT = ("suspicion_tier_",)


def fail(msg: str) -> None:
    print(f"sprite-chroma-check: ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def is_magenta_key(r: int, g: int, b: int, a: int) -> bool:
    if a < 20:
        return False
    if r >= 160 and b >= 130 and g <= 145 and (r - g) >= 35 and (b - g) >= 15:
        return True
    if r >= 170 and g <= 110 and b >= 90 and (r - g) >= 55:
        return True
    return False


def read_png_rgba(path: Path) -> tuple[int, int, list[bytes]]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos = 8
    width = height = 0
    bit_depth = color_type = 0
    idat = b""
    while pos + 8 <= len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        pos += 4
        ctype = data[pos : pos + 4]
        pos += 4
        chunk = data[pos : pos + length]
        pos += length
        pos += 4  # CRC
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, _, _, _ = struct.unpack(">IIBBBBB", chunk)
        elif ctype == b"IDAT":
            idat += chunk
        elif ctype == b"IEND":
            break
    if bit_depth != 8:
        raise ValueError(f"unsupported bit depth {bit_depth}")
    if color_type == 6:
        bpp = 4
    elif color_type == 2:
        bpp = 3
    else:
        raise ValueError(f"unsupported color type {color_type}")
    raw = zlib.decompress(idat)
    stride = width * bpp
    rows: list[bytes] = []
    i = 0
    prev = bytearray(stride)

    def paeth(a: int, b: int, c: int) -> int:
        p = a + b - c
        pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
        if pa <= pb and pa <= pc:
            return a
        if pb <= pc:
            return b
        return c

    for _ in range(height):
        filt = raw[i]
        i += 1
        row = bytearray(raw[i : i + stride])
        i += stride
        if filt == 1:
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                row[x] = (row[x] + left) & 255
        elif filt == 2:
            for x in range(stride):
                row[x] = (row[x] + prev[x]) & 255
        elif filt == 3:
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                row[x] = (row[x] + ((left + prev[x]) // 2)) & 255
        elif filt == 4:
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                up = prev[x]
                ul = prev[x - bpp] if x >= bpp else 0
                row[x] = (row[x] + paeth(left, up, ul)) & 255
        elif filt != 0:
            raise ValueError(f"unsupported filter {filt}")
        # Expand RGB → RGBA with full alpha for sampling.
        if bpp == 3:
            expanded = bytearray()
            for x in range(0, stride, 3):
                expanded.extend([row[x], row[x + 1], row[x + 2], 255])
            rows.append(bytes(expanded))
        else:
            rows.append(bytes(row))
        prev = row
    return width, height, rows


def pixel(rows: list[bytes], x: int, y: int) -> tuple[int, int, int, int]:
    row = rows[y]
    o = x * 4
    return row[o], row[o + 1], row[o + 2], row[o + 3]


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
        try:
            width, height, rows = read_png_rgba(path)
        except Exception as exc:  # noqa: BLE001 — report per-file
            fail(f"{name}: cannot decode PNG ({exc})")
        step = max(1, min(width, height) // 128)
        mag = samples = 0
        for y in range(0, height, step):
            for x in range(0, width, step):
                samples += 1
                if is_magenta_key(*pixel(rows, x, y)):
                    mag += 1
        frac = mag / max(1, samples)
        corners = [
            pixel(rows, 0, 0),
            pixel(rows, width - 1, 0),
            pixel(rows, 0, height - 1),
            pixel(rows, width - 1, height - 1),
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
