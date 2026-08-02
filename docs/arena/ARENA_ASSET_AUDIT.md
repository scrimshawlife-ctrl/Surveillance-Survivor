# Arena asset audit — landmark / prop alpha

```yaml
version: 1.0.0
status: audit_complete
last_updated: 2026-08-01
scope: landmark + prop runtime sprites (opaque-canvas / corner-alpha)
tool: scripts/audit_sprite_opaque_corners.py
base: 0eeef9f
```

**Purpose:** Find leftover **opaque canvas plates** (black / charcoal / magenta fill with alpha 255) on city landmarks and props that should be true cutouts for the urban-arena presentation stack.

**Does not claim:** READY launch, device readability, or full style unification.

---

## Method

1. Scan `Resources/RuntimeSprites/*landmark*` and `*prop*` (53 PNGs).
2. Sample four corners; flag when **alpha == 255** on all corners and RGB is **near-uniform**.
3. Secondary signals: near-black corners, magenta corners, near-full-opaque sample fraction.
4. Cross-check matching `Resources/Assets.xcassets/*.imageset` copies (hashes should match runtime).
5. **Repair only clear black/magenta edge plates** via edge flood-fill → alpha 0. Prefer docs when art may be intentional (night sky, full-bleed frame).

```bash
python3 scripts/audit_sprite_opaque_corners.py          # report only
python3 scripts/audit_sprite_opaque_corners.py --repair # clear plates only
make assets-check sprite-chroma-check
```

---

## Summary (post-repair)

| Bucket | Count | Notes |
| --- | ---: | --- |
| Scanned | **53** | landmark + prop name tokens under RuntimeSprites |
| OK cutouts | **50** | ≥2 transparent corners; no plate flags |
| REVIEW | **2** | mixed / non-uniform corners — document only |
| SUSPECT (documented) | **1** | intentional opaque night plate — **not** auto-repaired |
| Clear plate repaired | **1** | Oakland container stack |

Magenta corner leftovers: **none** on landmark/prop set (Hallmark C1 rekey holds).

---

## Suspects and review rows

| Status | Asset | Size | Corners (RGBA) | Flags | Disposition |
| --- | --- | --- | --- | --- | --- |
| **REPAIRED** | `oakland_landmark_container_stack_midground_01.png` | 384×256 | was ~`(22–29,22–29,16–29,255)` uniform charcoal | `OPAQUE_UNIFORM_CORNERS`, `BLACK_OPAQUE_CORNERS`, `NEAR_FULL_OPAQUE` | Edge flood near-black/charcoal plate → true alpha |
| **SUSPECT** | `san_francisco_landmark_victorian_midground_01.png` | 192×288 | `(52,52,52,255)` … uniform mid-gray | `OPAQUE_UNIFORM_CORNERS`, `NEAR_FULL_OPAQUE` | **Intentional night sky + stars** baked opaque; do not mass-key (would erase stars / sky). Re-export with sky alpha if product wants cutout later |
| REVIEW | `new_york_landmark_subway_entrance_01.png` | 160×160 | mixed grays `(91…)` / `(161…)`, all α=255 | non-uniform corners, content frame fills canvas | Not a plate; optional tighter crop later |
| REVIEW | `dayton_landmark_early_flight_distant_01.png` | 256×384 | 3 opaque + 1 transparent | residual dark fringe | Already mostly cut out; leave alone |

### Explicit non-suspects

- **`env_prop_sheet_municipal.png` / `env_prop_sheet_retail.png`** — sheet atlases; full canvas expected.
- Remaining city landmarks/props — transparent corners present; pass corner-alpha heuristic.

---

## Repair receipt

### `oakland_landmark_container_stack_midground_01`

| Field | Value |
| --- | --- |
| Problem | Fully opaque charcoal plate (corners RGB ≈ 18–29, α=255); silhouette not cut out |
| Method | Edge-connected flood of near-black / low-chroma charcoal (`max_luma≤58`) + magenta key → alpha 0 |
| Tool | `python3 scripts/audit_sprite_opaque_corners.py --repair` |
| Pixels keyed | **63968 / 98304** (≈65.1% of canvas) |
| Runtime path | `Resources/RuntimeSprites/oakland_landmark_container_stack_midground_01.png` |
| xcassets path | `Resources/Assets.xcassets/oakland_landmark_container_stack_midground_01.imageset/oakland_landmark_container_stack_midground_01.png` (synced byte-identical) |
| Post corners | α=0 on all four corners |
| Content check | Container RGB faces retained; no bright non-plate pixels keyed |
| sha256 (post) | `f9edd2f85bb2e8606104f1fa44c83c5f436bf3852f96615c9e0c01697945e76a` |

### Deferred (documented, not repaired)

| Asset | Why not repaired |
| --- | --- |
| `san_francisco_landmark_victorian_midground_01` | Baked night sky with star field is readable content, not a dead plate. Flood-fill at plate thresholds either leaves sky solid or punches holes through stars. Needs authored re-export if cutout is required. |
| `new_york_landmark_subway_entrance_01` | Non-uniform corner colors; structure appears to fill the canvas intentionally. |
| `dayton_landmark_early_flight_distant_01` | Already has transparency; residual fringe only. |

---

## Gates

```bash
make assets-check          # runtime PNG inventory / names
make sprite-chroma-check   # magenta plate gate (Hallmark C1)
python3 scripts/audit_sprite_opaque_corners.py   # expect: suspects ≤1 (SF night), 0 CLEAR_PLATE
```

---

## Residual / follow-ups

1. Optional SF Victorian re-export: transparent sky, keep arch + brick piers (+ optional sparse stars as sparse α).
2. NYC subway entrance: confirm on-device whether full-bleed gray frame reads as a tile or a prop; crop if needed.
3. Do **not** treat this audit as READY or as a substitute for ART device QA.
4. Report-only script stays out of `make validate` unless a fail-closed threshold is approved later.

---

## Do not claim

- Physical-iPhone alpha readability
- Full landmark style / projection unification
- READY launch or chroma perfection beyond existing gates
