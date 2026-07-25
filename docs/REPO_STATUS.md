# Repository status audit

**As of:** 2026-07-25  
**`main` tip:** `5a82d80` — Build Engine A (#55); Coordination Graph A in flight  
**App version:** `0.1.0` build `1` (pre-alpha) — see [`VERSIONING.md`](VERSIONING.md) · [`versions.json`](../versions.json)

**Primary sequencing:** [`ROADMAP.md`](ROADMAP.md) (launch P0–P6 · polish P7 · systemic P8–P11)  
**Systemic design:** [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md)  
**Device / ship gates:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**ART inventory:** [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)  
**Engineering style:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md)  
**Store worksheet:** [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| (this change) | P8 Dynamic City State contract A |

## Recently merged (high signal)

| PR | Title |
| ---: | --- |
| [#53](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/53) | P8 Suspicion Director contract slice A |
| [#52](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/52) | Board refresh dual lanes |
| [#51](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/51) | Emulator smoke for P0 combat + multi-frame player |
| [#50](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/50) | Issue #3 ART inventory reconciliation |
| [#49](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/49) | P0 weapon intake + player multi-frame cycles |
| [#48](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/48) | CI audio / weapon-vfx / animation gates |
| [#47](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/47)–[#42](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/42) | Weapon/audio/animation Batch 0–1 + candidates |
| — | Versioning registry + `make version-check` (stack on main) |
| — | Roguelike design assimilation → ROADMAP P8–P11 |

## Open issues

| Issue | Title | Close criterion |
| ---: | --- | --- |
| [#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3) | ART production exports | Device ART QA checklist + owner ship note |

**#2 closed** on GitHub (2026-07-24). Physical-device matrix in RELEASE_READINESS may still lack a tip-SHA log — treat as **evidence gap**, not “done by issue close.”

Closed also: #4, #6.

---

## Task board

### Operator / owner (launch lane)

| Task | Doc |
| --- | --- |
| Device ART QA + ship note → close #3 | ART_PRODUCTION_READINESS |
| Physical-device acceptance log for tip SHA | RELEASE_READINESS · DEVICE_TEST_LOG |
| Privacy + support URLs, SKU, copyright, age rating | APP_STORE_METADATA |
| ElevenLabs license before Audio Batch 1 | AUDIO_PLAN |

### Autonomous / offline

| Task | Status |
| --- | --- |
| Ten-city foundation art | **Done** |
| Audio Batch 0 | **Done** (#42) |
| Weapon/VFX Batch 0–2 (P0 stills) | **Done** (#43–#49) |
| Animation Batch 0–2 (pipeline + multi-frame) | **Done** (#44–#49) |
| CI manifest + version gates | **Done** (#48 + version stack) |
| Board refresh to tip + P8 | **Done** (#52) |
| Audio Batch 1 (11 stems) | **Open** (owner license) |
| **P8 Suspicion Director** (contracts + runtime A) | **Done** (#53) |
| **P8 Dynamic City State** (Wichita graph A) | **Done** (#54) |
| **P8 Emergent Build Engine** (synergy graph A) | **Done** (#55) |
| **P8 Coordination Graph** (lot capture cascade A) | **This change** |
| P8 Run Story | **Approved / not started** |

---

## Inventory snapshot

| Item | Count / note |
| --- | --- |
| Runtime PNGs | **179** (`make assets-check`) |
| Cities | 10 × 13 foundation |
| P0 combat | `projectile_default`, `deployable_mirror_array`, `deployable_signal_flood` integrated |
| Player multi-frame | idle 2f + walk 4f × 4 dirs |
| Audio binaries | **0** / 62 manifest rows |
| App | `0.1.0`+`1` pre-alpha |

---

## Gates

| Gate | Status |
| --- | --- |
| CI core + simulator | Green on recent merges |
| `version-check` | OK app=0.1.0+1 |
| `assets-check` | 179 PNGs |
| `audio-check` | Schema OK; binaries missing |
| `weapon-vfx-check` | P0 `runtime_integrated` |
| `animation-check` | Multi-frame + architecture |
| ART #3 | Repo inventory met; **device QA open** |
| Device acceptance | Evidence pending |
| Store listing | Owner fields pending |
| `director-check` | Suspicion Director rules OK |
| `city-state-check` | Infrastructure graph OK |
| P8 Director A | **Done** (#53) |
| `build-engine-check` | Build synergy graph OK |
| `coordination-check` | Coordination graph OK |
| P8 City State A | **Done** (#54) |
| P8 Build Engine A | **Done** (#55) |
| P8 Coordination A | **This PR** |
| P8 Run Story / P9–P11 | Design approved; not started |

---

## Suggested next

### Launch lane
1. Device ART QA + ship note → close **#3**  
2. Device acceptance log for current tip  
3. Store owner fields; Audio Batch 1 after license  

### Systemic lane (parallel, not TF-blocking)
1. ~~Director~~ #53 · ~~City State~~ #54 · ~~Build Engine~~ #55 · ~~Coordination~~ **this PR**  
2. Next: Run Story Compiler contracts  
3. Authority: assimilation · P8 Director / City State / Build Engine / Coordination packets  
4. No city 11  
