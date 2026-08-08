#!/usr/bin/env python3
"""Fail runtime sprites that are empty / wiped after bad chroma rekey.

Pure stdlib (no Pillow) so CI macOS runners can run assets-check without pip.

A sprite fails when fewer than MIN_OPAQUE_FRAC of pixels have alpha > 8,
unless listed in ALLOW_SPARSE.

Residual near-magenta RGB under transparent pixels is reported as a WARNING
only (common after chroma rekey; zero-alpha RGB does not composite).
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path

MIN_OPAQUE_FRAC = 0.005  # 0.5%
WARN_TRANSPARENT_MAGENTA_FRAC = 0.50

ALLOW_SPARSE = {
    "dayton_decal_test_lane_stripe_01",
    "wichita_overlay_aircraft_shadow_01",
}


def _read_png_rgba(path: Path) -> tuple[int, int, bytes]:
    """Decode PNG to raw RGBA bytes. Supports 8-bit RGB/RGBA and palette+tRNS."""
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"not a PNG: {path}")
    i = 8
    width = height = None
    bit_depth = color_type = None
    idat = bytearray()
    plte = None
    trns = None
    while i + 8 <= len(data):
        length = struct.unpack(">I", data[i : i + 4])[0]
        i += 4
        ctype = data[i : i + 4]
        i += 4
        chunk = data[i : i + length]
        i += length
        i += 4  # crc
        if ctype == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", chunk[:10])
        elif ctype == b"PLTE":
            plte = chunk
        elif ctype == b"tRNS":
            trns = chunk
        elif ctype == b"IDAT":
            idat.extend(chunk)
        elif ctype == b"IEND":
            break
    if width is None or height is None:
        raise ValueError(f"missing IHDR: {path}")
    if bit_depth != 8:
        raise ValueError(f"unsupported bit depth {bit_depth}: {path}")
    raw = zlib.decompress(bytes(idat))

    # Undo filter per scanline
    if color_type == 6:  # RGBA
        bpp = 4
    elif color_type == 2:  # RGB
        bpp = 3
    elif color_type == 3:  # palette
        bpp = 1
    elif color_type == 4:  # gray+alpha
        bpp = 2
    elif color_type == 0:  # gray
        bpp = 1
    else:
        raise ValueError(f"unsupported color type {color_type}: {path}")

    stride = width * bpp
    rows = []
    prev = bytearray(stride)
    o = 0
    for _y in range(height):
        filt = raw[o]
        o += 1
        row = bytearray(raw[o : o + stride])
        o += stride
        if filt == 0:
            pass
        elif filt == 1:  # Sub
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                row[x] = (row[x] + left) & 0xFF
        elif filt == 2:  # Up
            for x in range(stride):
                row[x] = (row[x] + prev[x]) & 0xFF
        elif filt == 3:  # Average
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                up = prev[x]
                row[x] = (row[x] + ((left + up) // 2)) & 0xFF
        elif filt == 4:  # Paeth
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                up = prev[x]
                up_left = prev[x - bpp] if x >= bpp else 0
                p = left + up - up_left
                pa, pb, pc = abs(p - left), abs(p - up), abs(p - up_left)
                pr = left if pa <= pb and pa <= pc else (up if pb <= pc else up_left)
                row[x] = (row[x] + pr) & 0xFF
        else:
            raise ValueError(f"unsupported filter {filt}: {path}")
        rows.append(row)
        prev = row

    # Expand to RGBA
    out = bytearray(width * height * 4)
    oi = 0
    if color_type == 6:
        for row in rows:
            out[oi : oi + stride] = row
            oi += stride
    elif color_type == 2:
        for row in rows:
            for x in range(width):
                r, g, b = row[x * 3 : x * 3 + 3]
                out[oi : oi + 4] = bytes((r, g, b, 255))
                oi += 4
    elif color_type == 3:
        if not plte:
            raise ValueError(f"palette PNG missing PLTE: {path}")
        palette = [(plte[i], plte[i + 1], plte[i + 2]) for i in range(0, len(plte), 3)]
        alpha_map = [255] * len(palette)
        if trns:
            for i, a in enumerate(trns):
                if i < len(alpha_map):
                    alpha_map[i] = a
        for row in rows:
            for x in range(width):
                idx = row[x]
                r, g, b = palette[idx]
                out[oi : oi + 4] = bytes((r, g, b, alpha_map[idx]))
                oi += 4
    elif color_type == 4:
        for row in rows:
            for x in range(width):
                g, a = row[x * 2], row[x * 2 + 1]
                out[oi : oi + 4] = bytes((g, g, g, a))
                oi += 4
    elif color_type == 0:
        for row in rows:
            for x in range(width):
                g = row[x]
                out[oi : oi + 4] = bytes((g, g, g, 255))
                oi += 4
    return width, height, bytes(out)


def check(path: Path) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    try:
        w, h, rgba = _read_png_rgba(path)
    except Exception as exc:  # noqa: BLE001 — report per-file
        return [f"{path}: decode failed: {exc}"], []
    total = w * h
    opaque = 0
    magenta_under = 0
    transparent = 0
    for i in range(0, len(rgba), 4):
        r, g, b, a = rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]
        if a > 8:
            opaque += 1
        else:
            transparent += 1
            if r > 160 and b > 140 and g < 120:
                magenta_under += 1
    name = path.stem
    frac = opaque / total if total else 0.0
    min_frac = 0.001 if name in ALLOW_SPARSE else MIN_OPAQUE_FRAC
    if frac < min_frac:
        errors.append(
            f"{path}: EMPTY/WIPED content opaque(a>8)={opaque}/{total} ({frac:.3%}); "
            f"min={min_frac:.3%}"
        )
    if transparent > 0:
        mag_frac = magenta_under / transparent
        if mag_frac > WARN_TRANSPARENT_MAGENTA_FRAC and magenta_under > 2000:
            warnings.append(
                f"{path}: residual magenta RGB under transparent "
                f"({magenta_under}/{transparent} = {mag_frac:.1%}) — harmless if alpha=0"
            )
    return errors, warnings


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("root", type=Path, help="RuntimeSprites directory or Resources root")
    args = ap.parse_args()
    root = args.root
    if (root / "RuntimeSprites").is_dir():
        root = root / "RuntimeSprites"
    if not root.is_dir():
        print(f"Missing asset root: {root}", file=sys.stderr)
        return 66
    pngs = sorted(root.glob("*.png"))
    if not pngs:
        print(f"No PNGs under {root}", file=sys.stderr)
        return 65
    errors: list[str] = []
    warnings: list[str] = []
    for p in pngs:
        e, w = check(p)
        errors.extend(e)
        warnings.extend(w)
    for w in warnings:
        print(f"WARN {w}", file=sys.stderr)
    if errors:
        for e in errors:
            print(e, file=sys.stderr)
        print(
            f"sprite-content-check: FAIL ({len(errors)} issue(s), {len(warnings)} warn)",
            file=sys.stderr,
        )
        return 1
    print(
        f"sprite-content-check: OK checked={len(pngs)} "
        f"min_opaque={MIN_OPAQUE_FRAC} warns={len(warnings)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
