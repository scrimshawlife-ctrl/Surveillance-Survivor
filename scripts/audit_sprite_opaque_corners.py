#!/usr/bin/env python3
"""Audit landmark/prop sprites for opaque-canvas suspects (report-only by default).

Flags PNGs whose four corners are fully opaque (alpha == 255) and near-uniform
in RGB — typical leftover black/magenta plates that should be true alpha.

Optional --repair applies a conservative edge flood-fill of near-black or
magenta plate pixels connected to the image border. Prefer documentation over
mass repair; only clear plate offenders should be rewritten.

Stdlib-only for audit. --repair requires Pillow.
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
import zlib
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SPRITE_DIR = ROOT / "Resources" / "RuntimeSprites"
DEFAULT_XCASSETS = ROOT / "Resources" / "Assets.xcassets"

# Name tokens that identify landmark / prop runtime art (not full terrain plates).
NAME_TOKENS = ("landmark", "prop")

# Near-uniform RGB tolerance across the four corners (0–255).
UNIFORM_TOL = 18

# Conservative near-black plate for optional repair (max channel + low chroma).
REPAIR_MAX_LUMA = 58
REPAIR_MAX_CHROMA = 14


def is_magenta_key(r: int, g: int, b: int, a: int) -> bool:
    if a < 20:
        return False
    if r >= 160 and b >= 130 and g <= 145 and (r - g) >= 35 and (b - g) >= 15:
        return True
    if r >= 170 and g <= 110 and b >= 90 and (r - g) >= 55:
        return True
    return False


def is_near_black(r: int, g: int, b: int, a: int, thr: int = 36) -> bool:
    if a < 250:
        return False
    mx, mn = max(r, g, b), min(r, g, b)
    return mx <= thr and (mx - mn) <= 14


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


def near_uniform(corners: list[tuple[int, int, int, int]], tol: int = UNIFORM_TOL) -> bool:
    if not all(c[3] == 255 for c in corners):
        return False
    mr = sum(c[0] for c in corners) / 4
    mg = sum(c[1] for c in corners) / 4
    mb = sum(c[2] for c in corners) / 4
    return all(
        abs(c[0] - mr) <= tol and abs(c[1] - mg) <= tol and abs(c[2] - mb) <= tol
        for c in corners
    )


def collect_targets(sprite_dir: Path) -> list[Path]:
    paths: list[Path] = []
    for path in sorted(sprite_dir.glob("*.png")):
        name = path.name.lower()
        if any(tok in name for tok in NAME_TOKENS):
            paths.append(path)
    return paths


def analyze(path: Path) -> dict:
    width, height, rows = read_png_rgba(path)
    corners = [
        pixel(rows, 0, 0),
        pixel(rows, width - 1, 0),
        pixel(rows, 0, height - 1),
        pixel(rows, width - 1, height - 1),
    ]
    opaque_corners = sum(1 for c in corners if c[3] == 255)
    transparent_corners = sum(1 for c in corners if c[3] < 20)
    magenta_corners = sum(1 for c in corners if is_magenta_key(*c))
    black_corners = sum(1 for c in corners if is_near_black(*c, thr=36))
    uniform = near_uniform(corners)

    step = max(1, min(width, height) // 64)
    samples = opaque = magenta = black = 0
    for y in range(0, height, step):
        for x in range(0, width, step):
            samples += 1
            r, g, b, a = pixel(rows, x, y)
            if a == 255:
                opaque += 1
            if is_magenta_key(r, g, b, a):
                magenta += 1
            if is_near_black(r, g, b, a, thr=36):
                black += 1
    opaque_frac = opaque / max(1, samples)
    mag_frac = magenta / max(1, samples)
    black_frac = black / max(1, samples)

    flags: list[str] = []
    if opaque_corners == 4 and uniform:
        flags.append("OPAQUE_UNIFORM_CORNERS")
    if magenta_corners >= 2:
        flags.append("MAGENTA_CORNERS")
    if black_corners >= 3 and opaque_corners == 4:
        flags.append("BLACK_OPAQUE_CORNERS")
    if opaque_frac >= 0.95 and transparent_corners == 0:
        flags.append("NEAR_FULL_OPAQUE")

    # Clear repair candidate: corners themselves are black or magenta plate.
    # High black_frac alone is not enough (intentional night-sky landmarks).
    clear_plate = opaque_corners == 4 and uniform and (
        black_corners >= 3 or magenta_corners >= 2 or mag_frac >= 0.08
    )

    if transparent_corners >= 2 and not flags:
        status = "OK"
    elif clear_plate:
        status = "SUSPECT_CLEAR_PLATE"
    elif flags:
        status = "SUSPECT"
    else:
        status = "REVIEW"

    return {
        "path": str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path),
        "name": path.name,
        "size": f"{width}x{height}",
        "corners": [list(c) for c in corners],
        "opaque_corners": opaque_corners,
        "transparent_corners": transparent_corners,
        "magenta_corners": magenta_corners,
        "black_corners": black_corners,
        "uniform_corners": uniform,
        "opaque_frac": round(opaque_frac, 3),
        "magenta_frac": round(mag_frac, 3),
        "black_frac": round(black_frac, 3),
        "flags": flags,
        "clear_plate": clear_plate,
        "status": status,
    }


def repair_edge_plate(path: Path, max_luma: int = REPAIR_MAX_LUMA) -> tuple[int, float]:
    """Edge flood-fill near-black / magenta plate → alpha 0. Returns (changed, frac)."""
    from PIL import Image  # local import — only needed for --repair

    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()

    def plate(r: int, g: int, b: int, a: int) -> bool:
        if a < 8:
            return False
        if is_magenta_key(r, g, b, a):
            return True
        mx, mn = max(r, g, b), min(r, g, b)
        return mx <= max_luma and (mx - mn) <= REPAIR_MAX_CHROMA

    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if plate(*px[x, y]):
                visited[y][x] = True
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not visited[y][x] and plate(*px[x, y]):
                visited[y][x] = True
                q.append((x, y))

    changed = 0
    while q:
        x, y = q.popleft()
        r, g, b, a = px[x, y]
        if a > 0:
            px[x, y] = (r, g, b, 0)
            changed += 1
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx] and plate(*px[nx, ny]):
                visited[ny][nx] = True
                q.append((nx, ny))

    im.save(path, format="PNG", optimize=True)
    return changed, changed / max(1, w * h)


def sync_xcassets(runtime_path: Path, xcassets: Path) -> Path | None:
    """Copy repaired runtime PNG into matching imageset if present."""
    stem = runtime_path.stem
    imageset = xcassets / f"{stem}.imageset" / runtime_path.name
    if imageset.is_file():
        imageset.write_bytes(runtime_path.read_bytes())
        return imageset
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dir", type=Path, default=DEFAULT_SPRITE_DIR)
    parser.add_argument("--xcassets", type=Path, default=DEFAULT_XCASSETS)
    parser.add_argument(
        "--repair",
        action="store_true",
        help="Rewrite clear black/magenta edge plates only (requires Pillow)",
    )
    parser.add_argument(
        "--repair-all-suspects",
        action="store_true",
        help="With --repair, also attempt non-clear SUSPECT rows (dangerous; prefer docs)",
    )
    parser.add_argument("--json", type=Path, default=None, help="Optional JSON report path")
    parser.add_argument("--max-luma", type=int, default=REPAIR_MAX_LUMA)
    args = parser.parse_args()

    if not args.dir.is_dir():
        print(f"audit_sprite_opaque_corners: ERROR missing {args.dir}", file=sys.stderr)
        raise SystemExit(1)

    targets = collect_targets(args.dir)
    rows = [analyze(p) for p in targets]
    ok = [r for r in rows if r["status"] == "OK"]
    review = [r for r in rows if r["status"] == "REVIEW"]
    suspects = [r for r in rows if r["status"] in ("SUSPECT", "SUSPECT_CLEAR_PLATE")]

    print(f"audit_sprite_opaque_corners: scanned={len(rows)} ok={len(ok)} review={len(review)} suspects={len(suspects)}")
    for r in rows:
        if r["status"] == "OK":
            continue
        flags = ",".join(r["flags"]) if r["flags"] else "-"
        corners = " ".join(
            f"({c[0]},{c[1]},{c[2]},{c[3]})" for c in r["corners"]
        )
        print(
            f"  {r['status']:18} {r['name']} {r['size']} "
            f"oc={r['opaque_corners']} of={r['opaque_frac']:.2f} "
            f"bf={r['black_frac']:.2f} mf={r['magenta_frac']:.3f} flags={flags}"
        )
        print(f"    corners: {corners}")

    repaired: list[str] = []
    if args.repair:
        try:
            from PIL import Image  # noqa: F401
        except ImportError as exc:
            print(f"audit_sprite_opaque_corners: ERROR Pillow required for --repair ({exc})", file=sys.stderr)
            raise SystemExit(1)

        for r in rows:
            if r["status"] == "SUSPECT_CLEAR_PLATE" or (
                args.repair_all_suspects and r["status"] in ("SUSPECT", "SUSPECT_CLEAR_PLATE")
            ):
                path = ROOT / r["path"] if not Path(r["path"]).is_absolute() else Path(r["path"])
                if not path.is_file():
                    path = args.dir / r["name"]
                changed, frac = repair_edge_plate(path, max_luma=args.max_luma)
                synced = sync_xcassets(path, args.xcassets)
                note = f"{r['name']}: keyed={changed} frac={frac:.3f}"
                if synced:
                    note += f" synced={synced.relative_to(ROOT)}"
                repaired.append(note)
                print(f"  REPAIRED {note}")

        if not repaired:
            print("  --repair: no clear plate offenders matched")

    if args.json:
        payload = {
            "scanned": len(rows),
            "ok": len(ok),
            "review": len(review),
            "suspects": len(suspects),
            "rows": rows,
            "repaired": repaired,
        }
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {args.json}")

    # Report-only audit never fails the gate; repair mode exits 0 after writes.
    print(
        "audit_sprite_opaque_corners: done "
        f"repair={args.repair} repaired={len(repaired)}"
    )


if __name__ == "__main__":
    main()
