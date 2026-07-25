# Hallmark asset remediation receipt (order 1–5)

```yaml
version: 1.0.0
status: complete
last_updated: 2026-07-25
source_audit: docs/HALLMARK_ASSET_AUDIT.md
```

## Completed

| # | Work | Evidence |
| ---: | --- | --- |
| 1 | Chroma re-key gate + plate cleanup | `scripts/validate_sprite_chroma.py`, `scripts/rekey_magenta_sprites.py`, `make sprite-chroma-check` green; ~50 sprites rekeyed |
| 2 | Strip LPR baked text | `lpr_intact.png` re-exported, no glyph label |
| 3 | Pixel projectile + Blind Spot | `projectile_default.png`, `blind_spot_decal.png` restyled |
| 4 | Landmark top-down (Wichita proof set) | hangar, bridge span, grain elevator converted toward orthographic footprints |
| 5 | Boss recolor + deployable 3-states | `boss_default` charcoal municipal; mirror/signal inactive·active·expended + projector wiring |

## Gates

```bash
make assets-check          # 185 runtime PNGs
make sprite-chroma-check   # OK
make test                  # 132 passed
```

## Residual (not blockers for this pass)

- Non-Wichita iso landmarks still vary in projection language (P7 polish)
- Skyline painterly vs pixel playfield soft-clash remains intentional parallax
- Deployable inactive state art shipped; runtime mostly shows active until despawn
- Device ART QA (#3) still required after re-exports

## Do not claim

- Physical-device readability
- Full ten-city landmark projection unification
