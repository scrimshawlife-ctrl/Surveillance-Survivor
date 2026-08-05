# Arena asset audit — landmark / prop alpha

```yaml
version: 1.1.0
status: audit_complete
last_updated: 2026-08-01
scope: landmark + prop runtime sprites (opaque-canvas / corner-alpha)
tool: scripts/audit_sprite_opaque_corners.py
base: 0eeef9f
re_scan_after: fd2e488
```

**Purpose:** Find leftover **opaque canvas plates** (black / charcoal / magenta fill with α=255) on city landmarks and props that should be true cutouts for the urban-arena presentation stack.

**Does not claim:** READY launch, device readability, or full style unification.

---

## Method

1. Scan RuntimeSprites names matching **token** `_landmark_` / `_prop_` (not bare substring `prop`, which false-hit `improper`).
2. Classify families: `landmark` · `prop` · `sheet` (`*_sheet_*` atlases).
3. Sample four corners; flag α==255 + near-uniform RGB; secondary dark/magenta/near-full-opaque signals.
4. **Sheets** always `OK_SHEET` — never SUSPECT / never `--repair`.
5. **Repair only** `SUSPECT_CLEAR_PLATE` (uniform dark/black/magenta corner plates) via edge flood → α=0; sync xcassets.

```bash
python3 scripts/audit_sprite_opaque_corners.py
python3 scripts/audit_sprite_opaque_corners.py --repair   # clear plates only
make assets-check sprite-chroma-check
```

---

## Inventory (authoritative tree + script)

| Family | Count | How counted |
| --- | ---: | --- |
| landmark | **41** | `*_landmark_*` under `Resources/RuntimeSprites` |
| prop (city) | **9** | token `_prop_` city singles (not sheets) |
| sheet | **2** | `env_prop_sheet_municipal.png`, `env_prop_sheet_retail.png` |
| **Scanned total** | **52** | 41 + 9 + 2 |
| Excluded false-positive | 1 | `san_francisco_overlay_improper_search_01` (name contains `prop` as substring of *improper*; not a prop) |

---

## Summary (post re-scan + SF repair)

Live output of `python3 scripts/audit_sprite_opaque_corners.py` after SF repair:

```
audit_sprite_opaque_corners: scanned=52 (landmark=41 prop=9 sheet=2) ok=48 ok_sheet=2 review=2 suspects=0
  REVIEW             dayton_landmark_early_flight_distant_01.png …
  REVIEW             new_york_landmark_subway_entrance_01.png …
  sheets (excluded from SUSPECT/repair): env_prop_sheet_municipal.png, env_prop_sheet_retail.png
```

| Bucket | Count | Notes |
| --- | ---: | --- |
| Scanned | **52** | landmark 41 + prop 9 + sheet 2 |
| OK cutouts | **48** | ≥2 transparent corners; no plate flags |
| OK_SHEET | **2** | atlas sheets; excluded from SUSPECT/repair |
| REVIEW | **2** | Dayton early-flight fringe; NYC subway non-uniform frame |
| SUSPECT / CLEAR_PLATE remaining | **0** | after Oakland + SF repairs |
| Clear plates repaired (this program) | **2** | Oakland (fd2e488), SF Victorian (this pass) |

Magenta corner leftovers on the landmark/prop set: **none**.

---

## `env_prop_sheet_*` classification

| Asset | Corners | Status | Why |
| --- | --- | --- | --- |
| `env_prop_sheet_municipal.png` | all α=0 | **OK_SHEET** | Multi-cell atlas with transparent padding; full-bleed plate heuristics do not apply |
| `env_prop_sheet_retail.png` | all α=0 | **OK_SHEET** | Same |

Sheets are **included in the scan inventory** for completeness but **never** enter SUSPECT/CLEAR_PLATE and **`--repair` skips them**. They are not “hand-waved OK cutouts”; they are an explicit atlas class.

---

## Suspects / review (from re-scan)

| Status | Asset | Size | Measured corners | Flags | Disposition |
| --- | --- | --- | --- | --- | --- |
| **REPAIRED** (prior) | `oakland_landmark_container_stack_midground_01.png` | 384×256 | post: α=0 on all four | was black charcoal plate | Edge flood charcoal → true alpha |
| **REPAIRED** (this pass) | `san_francisco_landmark_victorian_midground_01.png` | 192×288 | was `(52,52,52,255)`… uniform mid-charcoal | `OPAQUE_UNIFORM_CORNERS`, `DARK_OPAQUE_CORNERS`, `NEAR_FULL_OPAQUE` | **Not night sky.** Content is blue-gray arch + brick piers on a solid opaque charcoal canvas (α≈1.0; near-white “star” pixels = 0). Residual plate keyed to true alpha cutout |
| REVIEW | `new_york_landmark_subway_entrance_01.png` | 160×160 | mixed `(91…)` / `(161…)`, all α=255 | non-uniform | Content/frame fills canvas; not a uniform plate |
| REVIEW | `dayton_landmark_early_flight_distant_01.png` | 256×384 | 3× opaque + 1× transparent | residual fringe | Already mostly cut out |

### Correction vs v1.0.0

v1.0.0 incorrectly described SF Victorian as “intentional night sky + stars.” Pixel re-check:

- Subject: **arch + two brick piers** (pixel municipal prop/landmark).
- Canvas: nearly fully opaque dark charcoal (corners RGB ≈ 47–53, α=255).
- Sparse near-zero alpha noise only (~64 px); **not** a transparent cutout on disk before repair; **not** a star field (near-white count = 0).

---

## Repair receipts

### 1. `oakland_landmark_container_stack_midground_01` (commit fd2e488)

| Field | Value |
| --- | --- |
| Method | Edge flood near-black/charcoal (`max_luma≤58`) → α=0 |
| Keyed | 63968 / 98304 (≈65.1%) |
| Paths | RuntimeSprites + matching xcassets imageset (synced) |
| sha256 | `f9edd2f85bb2e8606104f1fa44c83c5f436bf3852f96615c9e0c01697945e76a` |

### 2. `san_francisco_landmark_victorian_midground_01` (this pass)

| Field | Value |
| --- | --- |
| Problem | Opaque charcoal plate around arch/piers cutout art |
| Method | Same edge flood (`max_luma≤58`); `SUSPECT_CLEAR_PLATE` via dark uniform corners |
| Tool | `python3 scripts/audit_sprite_opaque_corners.py --repair` |
| Keyed | **46603 / 55296** (≈84.3%) |
| Paths | `Resources/RuntimeSprites/…` + `Resources/Assets.xcassets/san_francisco_landmark_victorian_midground_01.imageset/…` |
| Post corners | α=0 on all four |
| Content check | Arch + brick piers retained |
| sha256 (post) | `f86b5c87575f9391decfea292dc7d7b5d6dd6f6f0a124ca78d01cd9fb5f40077` |

### Deferred (document only)

| Asset | Why not repaired |
| --- | --- |
| `new_york_landmark_subway_entrance_01` | Non-uniform corner colors; structure appears to fill the canvas |
| `dayton_landmark_early_flight_distant_01` | Already has transparency; residual fringe only |
| `env_prop_sheet_*` | Atlas class — out of plate-repair scope |

---

## Gates

Re-run after this pass (paste live stdout into task report):

```bash
make assets-check
make sprite-chroma-check
python3 scripts/audit_sprite_opaque_corners.py
```

Expect: scanned=52, suspects=0, review=2, ok_sheet=2; chroma OK.

---

## Residual / follow-ups

1. NYC subway entrance: optional tighter crop if full-bleed frame misreads as a tile on device.
2. Dayton early-flight: optional fringe cleanup.
3. Script remains **report-only** outside `make validate` unless a fail-closed threshold is approved.
4. No READY / physical-device alpha claim.

---

## Do not claim

- Physical-iPhone alpha readability
- Full landmark style / projection unification
- READY launch
