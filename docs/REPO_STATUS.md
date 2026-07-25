# Repository status audit

**As of:** 2026-07-25  
**`main` tip:** `967de30` — #3 ART inventory reconciliation (#50)  
**Recent:** #50 #3 docs · #49 art complete · #48 CI gates · #47–#46 batches

**Primary sequencing:** [`ROADMAP.md`](ROADMAP.md)  
**Device / ship gates:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**ART inventory:** [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)  
**Store worksheet:** [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md)  
**Audio:** [`AUDIO_PLAN.md`](AUDIO_PLAN.md) · Batch 0 [`audio/`](audio/)  
**Weapon/VFX:** [`WEAPON_VFX_AGENT_EXECUTION.md`](WEAPON_VFX_AGENT_EXECUTION.md) · [`weapon_vfx/`](weapon_vfx/)  
**Animation:** [`GAMEPLAY_ANIMATION_PLAN.md`](GAMEPLAY_ANIMATION_PLAN.md) · [`animation/`](animation/)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | **None** |

## Recently merged

| PR | Title |
| ---: | --- |
| [#50](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/50) | Issue #3 inventory reconciliation after #49 |
| [#49](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/49) | P0 weapon runtime intake + player multi-frame animation |
| [#48](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/48) | CI audio / weapon-vfx / animation manifest gates |
| [#47](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/47) | Weapon/VFX Batch 1 P0 silhouette candidates |
| [#46](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/46) | Animation Batch 0 + 1 presentation pipeline |
| [#44](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/44)–[#41](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/41) | Doctrine, Batch 0 audio/vfx, collision |

## Open issues

| Issue | Title | Close criterion |
| ---: | --- | --- |
| [#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3) | ART production exports | Device ART QA checklist + owner ship note |

**#2 closed** (2026-07-24) — device matrix in RELEASE_READINESS may still be Pending without a tip SHA log.

Closed also: #4, #6.

---

## Task board

### Operator / owner

| Task | Doc |
| --- | --- |
| Device ART QA + ship note to close #3 | ART_PRODUCTION_READINESS checklist |
| Physical-device acceptance evidence | RELEASE_READINESS · DEVICE_TEST_LOG |
| Privacy + support URLs, SKU, copyright, age rating | APP_STORE_METADATA |
| ElevenLabs license before Audio Batch 1 | AUDIO_PLAN |

### Autonomous / offline

| Task | Status |
| --- | --- |
| 10-city foundation art | **Done** |
| Audio Batch 0 | **Done** (#42) |
| Weapon/VFX Batch 0–2 (P0 stills) | **Done** (#43–#49) |
| Animation Batch 0–2 (pipeline + multi-frame) | **Done** (#44–#49) |
| CI manifest gates | **Done** (#48) |
| Audio Batch 1 (11 stems) | **Open** (after owner license) |

---

## City foundation packs

All **10** cities · **179** runtime PNGs · `make assets-check` green.

## Gates

| Gate | Status |
| --- | --- |
| CI core + simulator | Green on #49 |
| CI manifest gates | **Done** (#48) |
| assets-check | 179 PNGs |
| audio-check | 62 assets; binaries missing |
| weapon-vfx-check | P0 `runtime_integrated` |
| animation-check | multi-frame + architecture |
| ART #3 | Repo inventory met; **device QA open** |
| Device acceptance | Evidence pending |
| Store listing | Owner fields pending |

## Suggested next

1. **Close #3** after device ART QA + ship note (checklist in ART_PRODUCTION_READINESS)  
2. Audio Batch 1 after ElevenLabs license  
3. Optional polish: deployable 3-state strips, enemy multi-frame  
4. No city 11  
