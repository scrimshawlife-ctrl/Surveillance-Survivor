# Repository status audit

**As of:** 2026-07-24  
**`main` tip context:** collision/background fix **#41** · marketing hero **#40** · roadmap **#39** · README **#38** · final trilogy art **#37**  
**Audio:** Batch **0** inventory/dedup/receipts under [`audio/`](audio/)

**Primary sequencing:** [`ROADMAP.md`](ROADMAP.md)  
**Device / ship gates:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**ART inventory:** [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)  
**Store worksheet:** [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md)  
**Audio Batch 0:** [`audio/AUDIO_WORK_RECEIPT.md`](audio/AUDIO_WORK_RECEIPT.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | **None** (update when this branch opens) |

## Recently merged

| PR | Title |
| ---: | --- |
| [#41](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/41) | Collision slide + calmer city backgrounds |
| [#40](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/40) | Marketing pixel hero as README banner |
| [#39](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/39) | Roadmap + production readiness docs |
| [#38](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/38) | README hero + atlas badges |
| [#37](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/37) | NYC + LA + Atlanta foundation packs |
| [#36](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/36)–[#28](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/28) | Columbus → Wichita city packs + audits |

## Open issues

| Issue | Title | Close criterion |
| ---: | --- | --- |
| [#2](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/2) | WP1 playable iPhone foundation | Device acceptance protocol complete |
| [#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3) | ART production exports | Device ART QA + reserved-art decision + owner ship note |

Closed: #4, #6.

---

## Task board

### Operator / owner

| Task | Doc |
| --- | --- |
| Physical-device acceptance | RELEASE_READINESS · DEVICE_TEST_LOG · #2 |
| ART device QA + ship note | ART_PRODUCTION_READINESS · #3 |
| Privacy + support URLs, SKU, copyright, age rating | APP_STORE_METADATA |
| Store screenshots from release build | APP_STORE_METADATA |
| ElevenLabs license before **Batch 1** generation | AUDIO_* · audio/AUDIO_WORK_RECEIPT |

### Autonomous / offline

| Task | Status |
| --- | --- |
| 10-city foundation art | **Done** |
| README / atlas / roadmap docs | **Done** (#38–#40) |
| Collision / background readability | **Done** (#41) |
| Audio Batch 0 inventory + dedup + receipts | **Done** |
| Audio Batch 1 (11 runtime stems) | **Open** (after owner license) |
| Weapon/VFX Batch 0 inventory + dedup | **Done** — [`weapon_vfx/`](weapon_vfx/) (#43) |
| Weapon/VFX Batch 1 P0 candidates | **Open** (3 stems; no intake without owner) |
| Animation doctrine + `make animation-check` | **This track** — [`GAMEPLAY_ANIMATION_PLAN.md`](GAMEPLAY_ANIMATION_PLAN.md) |
| Animation Batch 0 inventory | **Open** (next autonomous) |
| Projectile/deployable runtime intake | Open (after owner + Batch 2) |

---

## City foundation packs

All **10** cities on `main`, 13 textures each · **160** runtime PNGs · `make assets-check` green.

## Gates

| Gate | Status |
| --- | --- |
| CI core + simulator | Green on recent merges |
| assets-check | 160 PNGs |
| audio-check | Manifest valid; **62 assets missing** binaries |
| weapon-vfx-check | Manifest valid; P0 binaries missing |
| animation-check | Manifest valid; physics-informed doctrine |
| Audio Batch 0 | **Complete** |
| Device acceptance | Pending |
| Store listing | Owner fields pending |

## Suggested next

1. Device acceptance (#2) if hardware available  
2. Merge weapon-vfx Batch 0 (#43) if open; Animation Batch 0 inventory  
3. Owner: ElevenLabs license OK → Audio Batch 1; P0 weapon silhouette decision  
4. No city 11  
