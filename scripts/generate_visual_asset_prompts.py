#!/usr/bin/env python3
"""Regenerate docs/VISUAL_ASSET_PRODUCTION_PROMPTS.md from repository authority.

The prompt document is derived, never hand-maintained. Its inputs are:

  Game/Rendering/VisualAssetMap.swift   roles, canonical asset names, display sizes
  Game/Rendering/GameAssetName.swift    the string namespace those names resolve through
  Sources/.../Content/districts.json    city names, titles, signature mechanics
  Sources/.../Content/enemies.json      guard archetype speeds and health
  Resources/RuntimeSprites/*.png        the authored pixel size of every shipped sprite

Two things this script exists to get right.

Display size is not authoring size. The map entry says what SpriteKit renders at;
the art is drawn much larger and downscaled — the player renders 54x72 from a
414x596 source, guards 40x52 from 256x320. Prompts must quote the source size or
regenerated art arrives at a fraction of the resolution the rest of the set uses.

VisualAssetMap is not the whole inventory. Guard archetypes, player animation
frames, deployable states and weapon-specific projectiles resolve through
GameAssetName and OptionalSpriteFrameCycle instead, and are listed here explicitly.

    python3 scripts/generate_visual_asset_prompts.py            # check for drift
    python3 scripts/generate_visual_asset_prompts.py --write    # rewrite the doc
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSET_MAP = ROOT / "Game/Rendering/VisualAssetMap.swift"
ASSET_NAMES = ROOT / "Game/Rendering/GameAssetName.swift"
DISTRICTS = ROOT / "Sources/SurveillanceCore/Resources/Content/districts.json"
ENEMIES = ROOT / "Sources/SurveillanceCore/Resources/Content/enemies.json"
WEAPON_VFX = ROOT / "docs/WEAPON_VFX_ASSET_MANIFEST.json"
ANIMATION = ROOT / "docs/GAMEPLAY_ANIMATION_MANIFEST.json"
SPRITES = ROOT / "Resources/RuntimeSprites"
DOC = ROOT / "docs/VISUAL_ASSET_PRODUCTION_PROMPTS.md"

GROUND_VALUE = (
    # The earlier wording gave only the ceiling ("within about 25 of the mean") and
    # every one of the twenty delivered tiles came back at mean 169.5 with a standard
    # deviation of 4-11 — visually flat, rendering as plain grey. State a floor as
    # well as a ceiling, and state it as a required spread rather than a limit.
    "Critical value constraint: this is a pale mid-tone ground surface, average luminance 150-190 of 255 — light grey concrete and worn pale asphalt, not dark tarmac. "
    "The surface must carry clearly visible texture: individual slabs, joints, patch repairs, tyre polish and grit should read distinctly at a glance. "
    "Required detail spread: the luminance standard deviation across the tile must fall between 15 and 25, with the darkest detail no lower than 120 and the brightest no higher than 215. "
    "A near-uniform surface is a failure — do not deliver a smooth or evenly-toned tile. "
    "Within that range keep the contrast even: no pure black lines, no deep cast shadows, no large dark grime patches, and no circuit-board or panel-line patterns. "
    "Characters are dark silhouettes standing on this surface and must stay readable at a glance, so no part of the texture may approach their value. Fully opaque RGBA with an alpha channel present."
)

STYLE = (
    "top-down orthographic pixel art, straight overhead camera, no perspective skew, crisp "
    "hard-edged pixels with no anti-aliasing or blur, limited desaturated palette of cool greys / "
    "olive / asphalt with a single cyan accent reserved for player-facing signals, muted late-dusk "
    "lighting, grounded contemporary American surveillance-state realism, no cartoon outlines, no "
    "text, no watermarks, no UI chrome"
)

# District id -> asset filename prefix. These differ (newYorkCity -> new_york).
PREFIX = {
    "wichita": "wichita", "louisville": "louisville", "tulsa": "tulsa", "dayton": "dayton",
    "oakland": "oakland", "sanFrancisco": "san_francisco", "columbus": "columbus",
    "newYorkCity": "new_york", "losAngeles": "los_angeles", "atlanta": "atlanta",
}
ORDER = list(PREFIX)

CORE = {
    "player_idle_down": "top-down hooded infiltrator standing still, facing the camera (south). Dark hooded jacket, cyan visor glow at the eyes, satchel at the hip. Isolated on full transparency, feet near the bottom edge, strong readable silhouette against busy ground",
    "player_idle_left": "the same infiltrator standing still, facing left (west). Identical costume, palette and proportions to the other player frames",
    "player_idle_up": "the same infiltrator standing still, seen from behind (north). Hood and shoulders read clearly, no face visible",
    "player_idle_right": "the same infiltrator standing still, facing right (east), mirror-consistent with the left frame",
    "player_walk_down": "the same infiltrator mid-stride walking toward the camera (south), clear leg separation so motion reads in a single frame",
    "player_walk_left": "the same infiltrator mid-stride walking left (west)",
    "player_walk_up": "the same infiltrator mid-stride walking away from camera (north)",
    "player_walk_right": "the same infiltrator mid-stride walking right (east)",
    "lpr_intact": "top-down licence-plate-reader camera pole, intact and powered: slim mast, camera head with a visible lens, small live status light. Isolated on transparency with the base at the bottom edge",
    "lpr_damaged": "the same camera pole visibly damaged: housing cracked, mast bent, lens dark, a wisp of smoke. Identical canvas and base position to the intact frame",
    "lpr_destroyed": "the same camera pole destroyed: mast snapped, head hanging or fallen, scorch marks. Identical canvas and base position to the other two states",
    "blind_spot_decal": "top-down circular extraction marker — the Blind Spot. A cyan ring of collapsed surveillance with a soft inner glow and a transparent centre so the player sprite reads through it. Must be clearly distinguishable from landmark rings, which are dim amber",
    "guard_default": "top-down generic contract security guard in neutral posture: uniform polo, cap, lanyard. Isolated on transparency. The fallback used when no archetype art is attached",
    "boss_default": "top-down district authority figure, visibly senior to a guard: heavier build, long coat, distinct headwear. Reads as a threat at a glance and must not use the cyan reserved for player-facing signals",
    "projectile_default": "small top-down countermeasure projectile: a bright compact core with a short motion smear, high contrast so it stays visible over busy ground",
    "deployable_mirror_array": "top-down deployed mirror-array gadget: a low tripod carrying angled reflective panels with a faint teal sheen. Isolated on transparency",
    "deployable_signal_flood": "top-down signal-flood emitter: a squat broadcast unit surrounded by concentric interference rings in warm amber, the outer rings mostly transparent",
    "env_tile_asphalt": "seamless tileable top-down asphalt road surface with faint lane wear, low contrast",
    "env_tile_downtown": "seamless tileable top-down downtown paving: kerbstone and tight paving slabs, low contrast",
    "env_tile_gated": "seamless tileable top-down gated-community surface: clean pale concrete with tidy joints",
    "env_tile_campus": "seamless tileable top-down campus surface: pale walkway flanked by grass margins",
    "env_tile_warehouse": "seamless tileable top-down warehouse yard: stained concrete with faded loading-bay markings",
    "env_parallax_skyline": "generic horizontal parallax skyline strip in flat silhouette, fully transparent above the roofline, very low contrast",
    "env_obstacle_retail_mass": "top-down big-box retail building footprint: flat roof with rooftop plant units, reads as solid and impassable, grounded contact shadow",
    "env_prop_sheet_municipal": "sprite sheet of small top-down municipal street props on transparency, arranged in a clean grid with even padding: bollard, litter bin, bench, signpost, hydrant",
    "env_prop_sheet_retail": "sprite sheet of small top-down retail-lot props on transparency, clean grid with even padding: trolley bay, pallet stack, parking meter, planter, A-board",
    "env_decal_sheet": "sprite sheet of flat ground decals on transparency, clean grid with even padding: oil stain, tyre marks, drain cover, cracked patch, faded arrow",
}
for _tier in range(6):
    _state = "fully closed and calm" if _tier == 0 else ("fully open and alarmed" if _tier == 5 else "partway open")
    CORE[f"suspicion_tier_{_tier}"] = (
        f"HUD glyph for suspicion tier {_tier} of 5: a single-colour eye motif on transparency that opens further "
        f"and grows more alarmed as the tier rises. Tier {_tier} is {_state}. Flat, no gradients, legible when "
        f"drawn down to 34 pixels"
    )

# Guard archetypes carry gameplay identity: the sprinter must not look like the
# shambler, because the sprinter is the one you cannot outrun.
GUARD_LOOK = {
    "guard_flashlight_cadet": "a young rookie in an ill-fitting uniform sweeping a torch ahead, nervous posture",
    "guard_radio_guy": "a dispatcher type with a handheld radio raised to the mouth and a belt pack of batteries",
    "guard_clipboard_enforcer": "a heavyset bureaucrat clutching a clipboard, slow and immovable",
    "guard_tactical_polo": "a lean contractor in a tactical polo and cargo trousers, sprinting posture, wiry and fast — this is the only threat the player cannot outrun and must read as urgent at a glance",
    "guard_segway_sentinel": "a patrol officer riding a two-wheeled personal transporter, leaning into a turn",
    "guard_supervisor_on_break": "a broad supervisor in a high-vis vest holding a coffee cup, bulky and durable",
}

PROJECTILE_LOOK = {
    "projectile_foia": "a fluttering wad of legal paperwork trailing loose pages, cream and off-white",
    "projectile_identity": "a spoofed identity token: a glinting chip-card shape with a soft violet edge",
    "projectile_redaction": "a solid black redaction bar with hard edges and a faint ink bloom",
}

DEPLOYABLE_STATE = {
    "inactive": "dormant and unlit, panels folded, no glow",
    "active": "deployed and running, panels open with a steady emissive glow",
    "expended": "spent and dark, panels drooping, faint smoke, clearly finished",
}

ANIMATION_LOOK = {
    "player_damage": "the hooded infiltrator flinching from a hit: a sharp recoil away from the impact, one arm rising, a brief red rim on the silhouette that clears by the final frame",
    "player_defeat": "the hooded infiltrator being reacquired: posture collapsing, the cyan visor glow guttering out, ending on a still slumped pose",
    "player_extract": "the hooded infiltrator stepping into the Blind Spot: the figure dissolving upward into cyan scan-lines from the feet, ending fully transparent",
    "fx_impact_surveillance_hardware": "a hit landing on surveillance hardware: a hard white flash, spalled casing fragments, a puff of dust, settling to nothing",
    "lpr_scan_loop": "a licence-plate reader sweeping: the lens iris pulsing and a faint scan wash brightening and dimming, seamless so it can loop indefinitely",
    "lpr_destroy_sequence": "a camera pole being destroyed: the housing rupturing, the mast buckling, sparks and a short smoke plume, ending on the dead pole",
    "boss_telegraph_primary": "the district authority winding up its primary move: a clear anticipatory crouch and a widening warning ring on the ground, unmistakable at a glance so the player can react",
    "fx_blind_spot_open": "the Blind Spot opening: a surveillance network collapsing inward then releasing outward as a cyan shockwave, a moment of pressure release",
}

CORE_SECTIONS = [
    "Player — base frames (must share one canvas and base line)",
    "Player — animation frames",
    "LPR camera pole (3 states — must share one canvas and base line)",
    "Combat entities and markers",
    "Guard archetypes",
    "Projectiles",
    "Deployables",
    "Suspicion HUD glyphs",
    "Global environment package",
]


def source_dimensions() -> dict[str, tuple[int, int]]:
    """Authored pixel size of every shipped sprite, measured from the files."""
    out: dict[str, tuple[int, int]] = {}
    for path in sorted(SPRITES.glob("*.png")):
        probe = subprocess.run(
            ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
            capture_output=True, text=True,
        ).stdout
        width = height = None
        for line in probe.splitlines():
            if "pixelWidth" in line:
                width = int(line.split(":")[1])
            if "pixelHeight" in line:
                height = int(line.split(":")[1])
        if width and height:
            out[path.stem] = (width, height)
    return out


def load_mapped() -> list[dict]:
    """Every VisualAssetMap entry, resolved to a literal name and display size."""
    consts: dict[str, str] = {}
    namespace = None
    for line in ASSET_NAMES.read_text().splitlines():
        header = re.match(r"\s*(?:public )?enum (\w+)", line)
        if header:
            namespace = header.group(1)
            continue
        const = re.search(r'static let `?(\w+)`?\s*=\s*"([^"]+)"', line)
        if const and namespace:
            consts[f"{namespace}.{const.group(1)}"] = const.group(2)

    rows: list[dict] = []
    for line in ASSET_MAP.read_text().splitlines():
        if ".init(role:" not in line:
            continue
        name = re.search(r"assetName: ([^,]+),", line)
        size = re.search(r"CGSize\(width: ([\d.]+), height: ([\d.]+)\)", line)
        required = re.search(r"requiredForMVP: (true|false)", line)
        if not (name and size):
            continue
        key = name.group(1).strip().replace("GameAssetName.", "")
        literal = consts.get(key)
        if literal is None:
            tier = re.search(r"name\(for: (\d)\)", key)
            quoted = re.search(r'"([^"]+)"', name.group(1))
            literal = f"suspicion_tier_{tier.group(1)}" if tier else (quoted.group(1) if quoted else key)
        rows.append({
            "asset": literal,
            "dw": int(float(size.group(1))),
            "dh": int(float(size.group(2))),
            "required": bool(required and required.group(1) == "true"),
        })
    return rows


def load_cities() -> dict[str, dict]:
    data = json.loads(DISTRICTS.read_text())
    return {
        row["id"]: {"name": row["cityName"], "title": row["title"], "mech": row["signatureMechanic"]}
        for row in data["districts"]
    }


def load_weapon_vfx() -> list[dict]:
    """Weapon VFX assets. The manifest already carries authored prompt text, so it is
    quoted verbatim rather than reworded — it is the art direction of record."""
    data = json.loads(WEAPON_VFX.read_text())
    return data["assets"]


def load_animation_clips() -> list[dict]:
    """Gameplay animation clips. Unlike the weapon VFX and audio manifests this one
    carries no prompt text, so wording comes from ANIMATION_LOOK here."""
    data = json.loads(ANIMATION.read_text())
    return data.get("assets") or data.get("clips") or []


def load_guards() -> dict[str, dict]:
    data = json.loads(ENEMIES.read_text())
    out = {}
    for guard in data["guards"]:
        snake = re.sub(r"(?<!^)(?=[A-Z])", "_", guard["id"]).lower()
        out[f"guard_{snake}"] = guard
    return out


def city_prompt(asset: str, w: int, h: int, cities: dict) -> str | None:
    for prefix, district in sorted(((v, k) for k, v in PREFIX.items()), key=lambda kv: -len(kv[0])):
        if not asset.startswith(prefix + "_"):
            continue
        rest = asset[len(prefix) + 1:]
        city = cities[district]
        flavour = f"{city['name']} — \"{city['title']}\", themed around {city['mech']}"

        def subject(kind: str) -> str:
            return rest.replace(kind, "").replace("_01", "").replace("_distant", "").replace("_", " ").strip()

        if rest.startswith("terrain"):
            return (f"Seamless tileable {w}x{h} top-down ground texture for {flavour}. Surface: "
                    f"{subject('terrain_')}. Must tile edge-to-edge with no visible seam. {GROUND_VALUE.strip()} {STYLE}.")
        if rest.startswith("skyline"):
            return (f"{w}x{h} horizontal parallax skyline strip for {flavour}. Distant city profile in flat "
                    f"silhouette, very low contrast, fully transparent above the roofline, no ground detail. {STYLE}.")
        if rest.startswith("landmark"):
            return (f"{w}x{h} top-down landmark building for {flavour}: {subject('landmark_')}. Isolated on full "
                    f"transparency, reads as a solid blocking structure seen from directly above, subtle roof detail, "
                    f"grounded contact shadow at the base. {STYLE}.")
        if rest.startswith("prop"):
            return (f"{w}x{h} small top-down street prop for {flavour}: {subject('prop_')}. Isolated on full "
                    f"transparency, a single object, readable silhouette at small size, no base plate. {STYLE}.")
        if rest.startswith("overlay"):
            return (f"{w}x{h} soft radial atmospheric overlay for {flavour}: {subject('overlay_')}. Mostly "
                    f"transparent, alpha falling to zero at the edges, no hard rim — it composites over the playfield "
                    f"without hiding entities underneath. {STYLE}.")
        if rest.startswith("decal"):
            return (f"{w}x{h} flat ground decal for {flavour}: {subject('decal_')}. A painted or worn marking lying "
                    f"flat on the surface, isolated on full transparency, scuffed edges, no drop shadow. {STYLE}.")
    return None


def extra_prompt(asset: str, w: int, h: int, guards: dict) -> str | None:
    """Assets resolved outside VisualAssetMap."""
    if asset in GUARD_LOOK:
        spec = guards.get(asset, {})
        speed, health = spec.get("speed"), spec.get("health")
        pace = ""
        if speed and health:
            pace = (f" Moves at {speed} against the player's 155 and carries {health} health, so it must read as "
                    f"{'faster and fragile' if speed > 155 else 'slower but sturdier'} at a glance.")
        return (f"{w}x{h} top-down contract security guard: {GUARD_LOOK[asset]}.{pace} Isolated on full transparency, "
                f"silhouette distinct from the other five archetypes. {STYLE}.")

    if asset in PROJECTILE_LOOK:
        return (f"{w}x{h} small top-down projectile: {PROJECTILE_LOOK[asset]}. Isolated on full transparency, high "
                f"contrast so it stays visible over busy ground, short motion smear. {STYLE}.")

    deployable = re.match(r"deployable_(mirror_array|signal_flood)_(inactive|active|expended)$", asset)
    if deployable:
        kind, state = deployable.groups()
        body = ("a low tripod carrying angled reflective panels with a faint teal sheen" if kind == "mirror_array"
                else "a squat broadcast unit ringed by concentric interference bands in warm amber")
        return (f"{w}x{h} top-down {kind.replace('_', ' ')} deployable, {DEPLOYABLE_STATE[state]}: {body}. Identical "
                f"canvas and footprint to the other two states of this deployable. Isolated on transparency. {STYLE}.")

    frame = re.match(r"(player_(idle|walk)_(down|left|up|right))_(\d)$", asset)
    if frame:
        base, motion, facing, index = frame.groups()
        total = "2-frame" if motion == "idle" else "4-frame"
        if motion == "idle":
            beat = "a subtle breathing settle — shoulders and hood shift only slightly from frame 1"
        else:
            beat = {"2": "the contact pose, weight landing on the leading foot",
                    "3": "the passing pose, legs together, body at its highest",
                    "4": "the opposite contact pose, mirroring frame 2"}[index]
        return (f"{w}x{h} frame {index} of a {total} top-down walk cycle: the same hooded infiltrator "
                f"{'standing' if motion == 'idle' else 'walking'} {facing}. This frame is {beat}. Identical costume, "
                f"palette, canvas and base line to `{base}.png` — only the pose changes. {STYLE}.")
    return None


def section_for(asset: str) -> tuple[str, str]:
    for prefix, district in sorted(((v, k) for k, v in PREFIX.items()), key=lambda kv: -len(kv[0])):
        if asset.startswith(prefix + "_"):
            return ("city", district)
    if re.match(r"player_(idle|walk)_(down|left|up|right)_\d$", asset):
        return ("core", CORE_SECTIONS[1])
    if asset.startswith("player_"):
        return ("core", CORE_SECTIONS[0])
    if asset.startswith("lpr_"):
        return ("core", CORE_SECTIONS[2])
    if asset in GUARD_LOOK:
        return ("core", CORE_SECTIONS[4])
    if asset.startswith("projectile_"):
        return ("core", CORE_SECTIONS[5])
    if asset.startswith("deployable_"):
        return ("core", CORE_SECTIONS[6])
    if asset.startswith("suspicion_tier"):
        return ("core", CORE_SECTIONS[7])
    if asset.startswith("env_"):
        return ("core", CORE_SECTIONS[8])
    return ("core", CORE_SECTIONS[3])


def build() -> str:
    mapped = {row["asset"]: row for row in load_mapped()}
    dims = source_dimensions()
    cities = load_cities()
    guards = load_guards()
    vfx = load_weapon_vfx()
    clips = [c for c in load_animation_clips() if c.get("status") == "missing"]
    vfx_missing = sum(1 for v in vfx if v.get("status") == "missing")

    resolved = []
    # Frames belonging to a weapon VFX or animation clip are covered by their own
    # sections below; listing them here as well would duplicate every frame.
    clip_stems = {v["logical_stem"] for v in vfx} | {c["logical_stem"] for c in load_animation_clips()}

    def is_clip_frame(name: str) -> bool:
        stem = re.sub(r"_\d+$", "", name)
        return stem in clip_stems and name not in mapped

    for asset in sorted(dims):
        if is_clip_frame(asset):
            continue
        w, h = dims[asset]
        entry = mapped.get(asset, {})
        prompt = city_prompt(asset, w, h, cities) or extra_prompt(asset, w, h, guards)
        if prompt is None:
            core = CORE.get(asset)
            # Match on name structure, not substring: "projectile_default" contains
            # "tile" and was silently given a ground-surface constraint, producing a
            # prompt that asked for a projectile shaped like pale asphalt.
            is_ground = asset.startswith("env_tile_") or "_terrain_" in asset
            if core is not None and is_ground:
                core = core + "." + GROUND_VALUE.rstrip()
            if core is None:
                raise SystemExit(f"no prompt for '{asset}' — add it to CORE in {Path(__file__).name}")
            prompt = f"{w}x{h} {core}. {STYLE}."
        resolved.append({
            "asset": asset, "w": w, "h": h,
            "dw": entry.get("dw"), "dh": entry.get("dh"),
            "required": entry.get("required", False),
            "mapped": asset in mapped,
            "prompt": prompt,
        })

    groups: "OrderedDict[tuple[str, str], list[dict]]" = OrderedDict()
    for row in resolved:
        groups.setdefault(section_for(row["asset"]), []).append(row)

    required = sum(1 for r in resolved if r["required"])
    core_count = sum(len(v) for k, v in groups.items() if k[0] == "core")

    out: list[str] = []
    add = out.append
    add("# Surveillance Survivor — Graphics Asset Generation Prompts")
    add("")
    add(f"**{len(resolved)} shipped sprites, {len(vfx)} weapon VFX assets and {len(clips)} unproduced animation "
        f"clips.** Every entry is a ready-to-paste prompt carrying the pixel size the art is actually authored at.")
    add("")
    add(f"The highest-value entries are the ones that **do not exist yet**: {vfx_missing} weapon VFX assets and "
        f"{len(clips)} animation clips are specified in the repo but unproduced, so generating them adds something "
        "the game currently lacks rather than replacing art already shipping.")
    add("")
    add("> Generated by `scripts/generate_visual_asset_prompts.py`. Do not hand-edit — rerun the script. Names, sizes, "
        "city themes and guard statistics are read from the repository, so adding a role or resizing an entry is "
        "picked up automatically.")
    add("")
    add("---")
    add("")
    add("## Read this before generating anything")
    add("")
    add("**Generate at the source size quoted in each prompt, not the display size.** These differ, often by a lot. "
        "The player renders at 54x72 on screen but the art is authored 414x596; guards render 40x52 from 256x320. "
        "SpriteKit downscales. Generating at display size would produce art at roughly a seventh of the resolution "
        "the existing set uses, and it would look soft next to everything already shipped.")
    add("")
    add("**Save each file under the exact asset name given, as `.png`, into `Resources/RuntimeSprites/`.** The runtime "
        "resolves textures by name. A mismatch silently falls back to a coloured shape node and the game keeps "
        "running, which is precisely why a wrong name is easy to miss.")
    add("")
    add("| Requirement | Why it matters |")
    add("| --- | --- |")
    add("| Exact source dimensions as listed | Matches the resolution of the shipped set; wrong sizes look soft or over-sharp after scaling |")
    add("| Real alpha transparency on everything except the tiling ground textures | Sprites composite over a busy playfield |")
    add("| sRGB colour space | `make assets-check` rejects other profiles |")
    add("| No text, watermark, signature or UI chrome | The HUD is native SwiftUI; baked text cannot localise or scale |")
    add("| Player frames share one canvas and one base line | Frame-to-frame drift reads as the character jittering |")
    add("| The 3 LPR states share one canvas and one base line | The pole must not appear to move when it takes damage |")
    add("")
    add("Two colour rules carry gameplay meaning rather than taste:")
    add("")
    add("- **Cyan is reserved for player-facing signals** — the player's visor, the Blind Spot extraction marker, the "
        "targeting reticle. Nothing hostile may use it.")
    add("- **Landmark rings are dim amber; the Blind Spot is cyan.** Deliberately separated so the exit is never "
        "mistaken for scenery.")
    add("")
    add("### Shared style suffix")
    add("")
    add("Already appended to every prompt below, repeated here so entries can be pasted standalone:")
    add("")
    add(f"> {STYLE}")
    add("")
    add("---")
    add("")
    add("## Core assets")
    add("")
    add(f"{core_count} assets shared across every district. The {required} marked **required** render as obviously "
        "placeholder shape nodes when absent.")
    add("")
    for name in CORE_SECTIONS:
        items = groups.get(("core", name))
        if not items:
            continue
        add(f"### {name}")
        add("")
        for row in items:
            flag = " · **required**" if row["required"] else ""
            shown = f" · renders {row['dw']}x{row['dh']}" if row["dw"] else ""
            add(f"**`{row['asset']}.png`** — generate {row['w']}x{row['h']}{shown}{flag}")
            add("")
            add(f"> {row['prompt']}")
            add("")

    add("---")
    add("")
    add("## City foundation packs")
    add("")
    add("Ten districts, 13 assets each. Every pack has the same shape — two ground tiles, one parallax skyline, four "
        "landmarks, one prop, three atmospheric overlays, two ground decals — so a city generates as a single batch "
        "and drops in without touching code.")
    add("")
    for district in ORDER:
        items = groups.get(("city", district))
        if not items:
            continue
        city = cities[district]
        add(f"### {city['name']} — *{city['title']}*")
        add("")
        add(f"Signature mechanic: {city['mech']}.")
        add("")
        for row in items:
            shown = f" · renders {row['dw']}x{row['dh']}" if row["dw"] else ""
            add(f"**`{row['asset']}.png`** — generate {row['w']}x{row['h']}{shown}")
            add("")
            add(f"> {row['prompt']}")
            add("")

    add("---")
    add("")
    add("## Weapon VFX")
    add("")
    add(f"{len(vfx)} assets from `docs/WEAPON_VFX_ASSET_MANIFEST.json`, **{vfx_missing} of them not yet produced**. "
        "Prompt text is quoted verbatim from that manifest — it is the art direction of record and is not reworded "
        "here. Multi-frame entries want one PNG per frame, numbered from 1.")
    add("")
    for row in vfx:
        canvas = row.get("canvas") or []
        size = f"{canvas[0]}x{canvas[1]}" if len(canvas) == 2 else "see manifest"
        frames = row.get("frames") or 1
        state = "**not yet produced**" if row.get("status") == "missing" else row.get("status", "").replace("_", " ")
        loop = " · loops" if row.get("loop") else ""
        add(f"**`{row['logical_stem']}`** — generate {size} · {frames} frame{'s' if frames != 1 else ''}{loop} · {state}")
        add("")
        add(f"> {row.get('prompt') or '(no prompt text in the manifest)'}")
        add("")

    add("---")
    add("")
    add("## Gameplay animation clips")
    add("")
    add(f"{len(clips)} clips from `docs/GAMEPLAY_ANIMATION_MANIFEST.json` that are **not yet produced**. Unlike the "
        "weapon VFX and audio manifests, this one carries no prompt text, so the wording below is written here and "
        "will need review by whoever owns the art direction.")
    add("")
    add("Two rules from the manifest's `presentation_rules` bind every clip: **the simulation owns the transform** "
        "(animation never moves an entity or emits a gameplay event), and every clip needs a reduced-motion and "
        "reduced-flash variant. Keep secondary motion bounded and never gate a hit window on a frame.")
    add("")
    for row in clips:
        frames = row.get("target_frames") or []
        span = f"{frames[0]}–{frames[1]} frames" if len(frames) == 2 else "frame count per manifest"
        note = row.get("notes")
        add(f"**`{row['logical_stem']}`** — {span} · family `{row.get('family')}`" + (f" · {note}" if note else ""))
        add("")
        look = ANIMATION_LOOK.get(row["logical_stem"])
        if look:
            add(f"> Top-down sprite animation, {span}: {look}. Frames share one canvas and one base line so the "
                f"entity does not drift. Isolated on full transparency. {STYLE}.")
        else:
            add("> (no prompt written — add it to `ANIMATION_LOOK` in the generator)")
        add("")

    add("---")
    add("")
    add("## Full checklist")
    add("")
    add("| # | Asset | Generate at | Renders at | Required |")
    add("| ---: | --- | --- | --- | :---: |")
    for index, row in enumerate(resolved, 1):
        shown = f"{row['dw']}x{row['dh']}" if row["dw"] else "—"
        add(f"| {index} | `{row['asset']}.png` | {row['w']}x{row['h']} | {shown} | "
            f"{'yes' if row['required'] else '—'} |")
    add("")
    add("---")
    add("")
    add("## After generating")
    add("")
    add("```bash")
    add("make assets-check")
    add("make sprite-chroma-check")
    add("```")
    add("")
    add("`assets-check` validates canonical filenames, PNG decodability, sRGB colour space, alpha presence, and shared "
        "canvas dimensions within the player and LPR families. `sprite-chroma-check` flags stray magenta, which is "
        "used as a chroma sentinel.")
    add("")
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true", help="rewrite the document in place")
    args = parser.parse_args()

    rendered = build()
    if args.write:
        DOC.write_text(rendered)
        print(f"visual-asset-prompts: WROTE {DOC.relative_to(ROOT)}")
        return 0

    current = DOC.read_text() if DOC.exists() else ""
    if current != rendered:
        print("visual-asset-prompts: DRIFT — regenerate with --write", file=sys.stderr)
        return 1
    print("visual-asset-prompts: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
