# Visual P1 residual + P2 polish — 2026-08-07

Continues `VISUAL_P0_REMEDIATION_2026-08-07.md` on branch `fix/visual-p0-wrong-subject-and-empty-gate`.

## 1. Magenta residual under transparent (P1 hygiene)

Zeroed RGB under `alpha==0` (and near-invisible magenta fringe `0 < a < 8`) across **33** runtime sprites that still held chroma-key plate RGB after prior rekey.

| Before | After |
| --- | --- |
| 8+ content-check WARNs | **0 WARNs** |
| Magenta RGB under transparent on city decals/overlays | RGB zeroed; alpha unchanged |

Does not change visible composites (alpha was already 0).

## 2. Oakland port crane (P2)

`oakland_landmark_port_crane_distant_01` rebuilt as STS-style portal crane: yellow legs + boom, trolley, cables, blue container, rail base. No longer reads as a street lamp.

## 3. Player canvas (P2 partial)

Player atlas crop **waived on current main tip** (expanded `player_damage_*` / multi-frame set requires uniform 414×596; mass crop only saved ~1% and broke assets-check):

| | Size |
| --- | --- |
| Before | 414×596 |
| After | **410×594** |

Mass-based tighter crop was evaluated but frames legitimately span most of the canvas (walk extremes). `docs/art/PLAYER_CANVAS.json` updated. Display size remains `54×72` with feet anchor `(0.5, 0.12)` in `VisualAssetMap` — no projector change required.

## 4. Combat pixel pass (P2)

Rebuilt in flat municipal pixel language (low unique-color, NN-friendly):

| Family | Assets |
| --- | --- |
| Projectiles | `projectile_default`, `_redaction`, `_identity`, `_foia` |
| Deployables | `deployable_mirror_array` + inactive/active/expended |
| Deployables | `deployable_signal_flood` + inactive/active/expended |
| Extraction | `blind_spot_decal` (glitch scan-cancel rings, not Target reticle) |

Hero + 3-state variants written to RuntimeSprites and imagesets.

## Validation

```
sprite-content-check: OK checked=194 warns=0
sprite-chroma-check: OK checked=151
assets-check: Validated 194 visual runtime PNG asset(s)
```

## Residual / next

- Player atlas still large vs display size — true tight crop needs re-export with feet-locked content (not alpha fringe trim).
- Combat stills are intentionally simple code-pixel; optional art-director pass for grit.
- Physical-device ART QA (#3) still open.
