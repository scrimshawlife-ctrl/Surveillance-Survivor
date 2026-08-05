#!/usr/bin/env python3
"""Align multi-frame character banks to their own frame 1.

The delivered walk banks are four independently-generated illustrations rather
than one animation cycle: each frame was drawn at its own zoom and its own
position on the canvas. Played back, the player jumps ~30% in size and hops
65-100px every step. That reads as a rendering fault, not as walking.

Frame 1 is the reference. Every later frame is scaled so its content bbox
height matches frame 1's, then placed so the feet (bbox bottom) and the
horizontal centre line up. Canvas size is preserved, so nothing downstream —
anchors, display sizes, the atlas manifest — has to change.

Only character banks are touched. Effect banks are excluded on purpose: an
explosion is *supposed* to change size across its frames, and normalising one
would flatten the effect into a static blob.
"""

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RUNTIME = ROOT / "Resources/RuntimeSprites"
XCASSETS = ROOT / "Resources/Assets.xcassets"

# Banks whose frames depict one body that should hold its scale and footing.
CHARACTER_PREFIXES = ("player_walk_", "player_idle_", "guard_", "boss_")
# Effects legitimately grow, drift and dissipate — never normalise these.
EXCLUDE_PREFIXES = ("fx_", "projectile_", "deployable_", "deploy_", "pulse_", "swarm_", "lpr_")
# Effect banks that sit under a character prefix. `boss_telegraph_primary` is an
# expanding warning ring: its frames scale from x0.58 to x1.44 by design, and
# normalising them to a common height would erase the tell entirely.
EXCLUDE_EXACT = {"boss_telegraph_primary"}


def bank_frames(stem: str) -> list[Path]:
    """Frame 1 is the bare stem; frames 2..N are `{stem}_{n}`."""
    frames = [RUNTIME / f"{stem}.png"]
    n = 2
    while (RUNTIME / f"{stem}_{n}.png").exists():
        frames.append(RUNTIME / f"{stem}_{n}.png")
        n += 1
    return frames


def discover_banks() -> list[str]:
    stems = set()
    for png in RUNTIME.glob("*.png"):
        name = png.stem
        if name.startswith(EXCLUDE_PREFIXES):
            continue
        if not name.startswith(CHARACTER_PREFIXES):
            continue
        # A bank is named by its frame-1 stem, so drop any trailing _N.
        parts = name.rsplit("_", 1)
        base = parts[0] if len(parts) == 2 and parts[1].isdigit() else name
        if base in EXCLUDE_EXACT:
            continue
        if (RUNTIME / f"{base}.png").exists() and (RUNTIME / f"{base}_2.png").exists():
            stems.add(base)
    return sorted(stems)


def normalize(stem: str, apply: bool) -> list[str]:
    frames = bank_frames(stem)
    if len(frames) < 2:
        return []

    ref_img = Image.open(frames[0]).convert("RGBA")
    ref_box = ref_img.getbbox()
    if ref_box is None:
        return [f"{stem}: frame 1 is empty, skipped"]
    ref_h = ref_box[3] - ref_box[1]
    ref_feet = ref_box[3]
    ref_cx = (ref_box[0] + ref_box[2]) / 2
    canvas = ref_img.size

    report = []
    for path in frames[1:]:
        img = Image.open(path).convert("RGBA")
        box = img.getbbox()
        if box is None:
            report.append(f"{path.name}: empty, skipped")
            continue
        h = box[3] - box[1]
        scale = ref_h / h

        content = img.crop(box)
        new_size = (max(1, round(content.width * scale)), max(1, round(content.height * scale)))
        content = content.resize(new_size, Image.LANCZOS)

        out = Image.new("RGBA", canvas, (0, 0, 0, 0))
        # Feet on frame 1's baseline, body on frame 1's centre line.
        left = round(ref_cx - content.width / 2)
        top = round(ref_feet - content.height)
        out.alpha_composite(content, (left, top))

        report.append(
            f"{path.name}: scale x{scale:.3f}  feet {box[3]}->{ref_feet}  "
            f"centre {(box[0] + box[2]) / 2:.0f}->{ref_cx:.0f}"
        )
        if apply:
            out.save(path)
            mirror = XCASSETS / f"{path.stem}.imageset" / path.name
            if mirror.parent.exists():
                out.save(mirror)
    return report


def main() -> int:
    apply = "--apply" in sys.argv
    banks = discover_banks()
    if not banks:
        print("no multi-frame character banks found")
        return 0
    for stem in banks:
        lines = normalize(stem, apply)
        if lines:
            print(f"\n{stem}  ({len(bank_frames(stem))} frames)")
            for line in lines:
                print(f"  {line}")
    print(f"\n{'applied to' if apply else 'dry run over'} {len(banks)} bank(s)")
    if not apply:
        print("re-run with --apply to write")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
