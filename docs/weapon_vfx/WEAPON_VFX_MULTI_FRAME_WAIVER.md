# Weapon VFX multi-frame waiver (Hallmark C5)

```yaml
version: 1.0.0
status: waived_until_p7
last_updated: 2026-07-25
audit_id: C5
```

## Claim

Hallmark audit **C5** required multi-frame weapon / hit / flood VFX in runtime.  
**This is waived for pre-alpha** after single-frame family stills land.

## What shipped instead (closeout)

| Role | Status |
| --- | --- |
| `projectile_default` (kinetic) | Runtime + catalog |
| `projectile_redaction` | Runtime + catalog (Hallmark M9) |
| `projectile_identity` | Runtime + catalog (Hallmark M9) |
| `projectile_foia` | Runtime + catalog (Hallmark M9) |
| Deployable mirror / signal 3-state | Runtime + projector |
| Multi-frame hit / muzzle / flood pulse | **Deferred P7** — not required for systems truth |

## Why waiver is valid

1. SurveillanceCore owns combat truth; presentation stills do not invent damage.  
2. Distinct **single-frame** silhouettes satisfy weapon-family readability (M9).  
3. Manifest Batch 0–2 multi-frame stems remain **GENERATE_MISSING** in `docs/weapon_vfx/` until owner art budget.  
4. Emulator ≠ device; multi-frame flash/safety needs device QA (#3) before ship claims.

## Re-open criterion

Remove this waiver when:

- multi-frame heroes are attached under RuntimeSprites + GameAssetName, **and**  
- `make weapon-vfx-check` + device reduced-flash pass for high-luminance sequences.
