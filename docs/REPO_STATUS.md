# Repository status audit

**As of:** 2026-07-25  
**`main` tip:** `e97fbf5` — animation Batch 0+1 (#46)  
**Recent:** #46 presentation pipeline · #44 animation doctrine · #43 weapon-vfx Batch 0 · #42 audio Batch 0 · #41 collision/BG

**Primary sequencing:** [`ROADMAP.md`](ROADMAP.md)  
**Device / ship gates:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**ART inventory:** [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)  
**Store worksheet:** [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md)  
**Audio:** [`AUDIO_PLAN.md`](AUDIO_PLAN.md) · Batch 0 [`audio/`](audio/)  
**Weapon/VFX:** [`WEAPON_VFX_AGENT_EXECUTION.md`](WEAPON_VFX_AGENT_EXECUTION.md) · Batch 0 [`weapon_vfx/`](weapon_vfx/)  
**Animation:** [`GAMEPLAY_ANIMATION_PLAN.md`](GAMEPLAY_ANIMATION_PLAN.md) · [`animation/`](animation/)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | **None** |

## Recently merged

| PR | Title |
| ---: | --- |
| [#46](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/46) | Animation Batch 0 inventory + Batch 1 presentation pipeline |
| [#44](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/44) | Physics-informed animation doctrine + `make animation-check` |
| [#43](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/43) | Weapon/VFX Batch 0 inventory |
| [#42](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/42) | Audio Batch 0 inventory |
| [#41](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/41) | Collision slide + calmer city backgrounds |
| [#40](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/40)–[#37](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/37) | README/docs + final trilogy city packs |

## Open issues

| Issue | Title | Close criterion |
| ---: | --- | --- |
| [#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3) | ART production exports | Device ART QA + reserved-art decision + owner ship note |

**#2 closed** (2026-07-24) — GitHub state closed, but [`RELEASE_READINESS.md`](RELEASE_READINESS.md) still lists physical-device acceptance rows as **Pending**. Reconcile with dated [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) evidence or reopen/track device work separately.

Closed also: #4, #6.

---

## Task board

### Operator / owner

| Task | Doc |
| --- | --- |
| Physical-device acceptance evidence | RELEASE_READINESS · DEVICE_TEST_LOG |
| ART device QA + ship note + projectile decision | ART_PRODUCTION_READINESS · #3 |
| Privacy + support URLs, SKU, copyright, age rating | APP_STORE_METADATA |
| Store screenshots from release build | APP_STORE_METADATA |
| ElevenLabs license before Audio Batch 1 | AUDIO_PLAN |
| Owner review of Weapon/VFX P0 candidates | weapon_vfx receipts |

### Autonomous / offline

| Task | Status |
| --- | --- |
| 10-city foundation art | **Done** |
| Audio Batch 0 | **Done** (#42) |
| Weapon/VFX Batch 0 | **Done** (#43) |
| Animation doctrine | **Done** (#44) |
| Animation Batch 0 + 1 (pipeline) | **Done** (#46) |
| Weapon/VFX Batch 1 P0 candidates | **Done** — Masters/P0 + receipt; **owner review** before intake |
| Animation Batch 2 multi-frame player | **Open** |
| Audio Batch 1 (11 stems) | **Open** (after owner license) |
| Projectile/deployable runtime intake | Open (after owner + Batch 2) |

---

## City foundation packs

All **10** cities on `main`, 13 textures each · **160** runtime PNGs · `make assets-check` green.

## Gates

| Gate | Status |
| --- | --- |
| CI core + simulator | Green on #46 |
| assets-check | 160 PNGs |
| audio-check | 62 assets; all binaries missing |
| weapon-vfx-check | 20 assets; P0 stills not runtime-integrated |
| animation-check | 27 clips; architecture integrated |
| Device acceptance | Evidence pending (see #2 note) |
| Store listing | Owner fields pending |

## Suggested next

1. Owner: review P0 weapon candidates (`docs/weapon_vfx/WEAPON_VFX_BATCH_1_RECEIPT.md`)  
2. Device acceptance evidence / ART #3  
3. Audio Batch 1 after ElevenLabs license  
4. Animation Batch 2 multi-frame player **or** Weapon Batch 2 intake if approved  
5. No city 11  
