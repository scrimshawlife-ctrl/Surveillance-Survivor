# Gameplay animation dedup report — Batch 0

**Generated:** 2026-07-24  
**Commit:** see `ANIMATION_INVENTORY.json` → `git_commit_at_generation`  
**Authority:** [`GAMEPLAY_ANIMATION_AGENT_EXECUTION.md`](../GAMEPLAY_ANIMATION_AGENT_EXECUTION.md) · [`GAMEPLAY_ANIMATION_MANIFEST.json`](../GAMEPLAY_ANIMATION_MANIFEST.json)

## Summary

| Check | Result |
| --- | --- |
| Manifest clips | **27** |
| Player idle/walk binaries | **8 / 8** single-frame PNGs |
| Multi-frame banks | **None** (`PlayerAtlasManifest` `frameCount: 1`) |
| SHA-256 duplicates among animation-relevant stems | **0** |
| P0 weapon stills (`projectile_default`, deployables) | **Missing** (weapon VFX track) |
| Presentation architecture (interp / SM / secondary) | **Not implemented** |
| `SKPhysicsWorld` gameplay authority | **Absent** (correct) |
| Art generated this batch | **None** |

**Conclusion:** Reuse the eight player stills as **REUSE_EXACT_STILL** bases for future multi-frame expansion. Do not re-export under new stems. Architecture clips require **Batch 1 code**, not PNGs. Weapon motion waits on weapon-VFX P0 stills.

---

## Player atlas

| Stem | W×H | Frames today | Target |
| --- | ---: | ---: | --- |
| `player_idle_{down,left,up,right}` | 436×640 | 1 each | 4–8 |
| `player_walk_{down,left,up,right}` | 436×640 | 1 each | 6–10 |

Anchors: `(0.5, 0.12)` per `PlayerAtlasManifest`.  
No duplicate hashes across the eight files.

---

## Other entity stills (presentation, not multi-frame)

| Stem | Role | Animation notes |
| --- | --- | --- |
| `lpr_intact` / `damaged` / `destroyed` | Camera body swap by health | No scan/destroy sequence clips |
| `guard_default` | Guard sprite | Tint only for processing/disrupted |
| `boss_default` | Boss sprite | No telegraph clips |
| `blind_spot_decal` | Extraction | No open/field loop |
| `projectile_default` | **Missing binary** | Shape fallback; no flight sheet |
| `deployable_mirror_array` | **Missing** | Shape fallback |
| `deployable_signal_flood` | **Missing** | Shape fallback + reducedFlash colors |

---

## Manifest classification (Batch 0)

| Decision | Count | Clips |
| --- | ---: | --- |
| REUSE_EXACT_STILL | 8 | Player idle/walk four dirs |
| IMPLEMENT_IN_BATCH_1 | 3 | snapshot_interpolation, secondary_motion, quality_tiers |
| PROCEDURAL_LATER | 1 | env secondary beacon pulse |
| GENERATE_OR_IMPLEMENT_LATER | 15 | damage/defeat/extract, weapon FX, LPR sequences, guard/boss, Blind Spot |

---

## Presentation vs simulation (no ownership leaks)

| Behavior | Finding |
| --- | --- |
| Position | Set from `entity.position` each render — **sim owned** |
| Heading (camera) | `zRotation = entity.heading` |
| Player facing | Texture role from velocity/heading map — not animation time |
| Hits / damage windows | Not driven by clips or `SKAction` completion |
| Pooling | `EntityProjector` reuses nodes; clears actions on recycle |

---

## Rejected shortcuts

| Action | Decision |
| --- | --- |
| Generate multi-frame player now | **Deferred** → Batch 2 |
| Invent weapon flight PNGs under animation names | **Rejected** — weapon VFX stills first |
| Add SKPhysics for projectiles | **Rejected** |
| Mark architecture clips runtime-integrated | **Rejected** — code missing |
| Claim multi-frame complete from single stills | **Rejected** |

---

## Next

1. **Batch 1** — presentation architecture (interpolation, SM, bounded secondary motion, quality tiers).  
2. **Batch 2** — multi-frame player cycles (expand REUSE_EXACT stills).  
3. Weapon motion after weapon-VFX P0 candidates + owner intake.
