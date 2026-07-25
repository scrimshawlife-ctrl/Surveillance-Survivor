# Repository status audit

**As of:** 2026-07-25  
**`main` tip:** `49fa13f` — boards through #63; P9 landmark + clearing builds on next merge
**App version:** `0.1.0` build `1` (pre-alpha) — see [`VERSIONING.md`](VERSIONING.md) · [`versions.json`](../versions.json)

**Primary sequencing:** [`ROADMAP.md`](ROADMAP.md) (launch P0–P6 · polish P7 · systemic P8–P11)  
**Continuation paste:** [`CONTINUATION_PROMPT.md`](CONTINUATION_PROMPT.md)  
**Systemic design:** [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md)  
**Device / ship gates:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**ART inventory:** [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)  
**Engineering style:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md)  
**P9 proof board:** [`P9_BIG_BOX_PROOF.md`](P9_BIG_BOX_PROOF.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | **None** |

## Recently merged (high signal)

| PR | Title |
| ---: | --- |
| [#58](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/58) | P8 Run Story Compiler A |
| [#57](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/57) | Hallmark HUD visual tokens |
| [#56](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/56) | P8 Coordination Graph A |
| [#55](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/55) | P8 Build Engine A |
| [#54](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/54) | P8 City State A |
| [#53](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/53) | P8 Suspicion Director A |

## Open issues

| Issue | Title | Close criterion |
| ---: | --- | --- |
| [#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3) | ART production exports | Device ART QA checklist + owner ship note |

**#2 closed** on GitHub. Physical-device matrix may still lack tip-SHA log.

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
| P8 contract stack A (Director→Story) | **Done** (#53–#58) |
| Hallmark HUD tokens | **Done** (#57) |
| **P9 interactables A** (6 Wichita) | **Done** (#59) |
| **P9 landmark + clearing builds A** | **This PR** (receipt v9) |
| Adaptive audio stems / device perf | Open (operator / license) |
| Audio Batch 1 | Open (owner license) |

---

## Inventory snapshot

| Item | Count / note |
| --- | --- |
| Runtime PNGs | **179** |
| Cities | 10 × 13 foundation |
| App | `0.1.0`+`1` pre-alpha |
| Receipt schema | **v9** (landmark + clearing builds) |

---

## Gates

| Gate | Status |
| --- | --- |
| P8 checks | director / city-state / build-engine / coordination / story |
| `interactables-check` | OK |
| `landmark-check` | OK |
| `clearing-builds-check` | OK |
| ART #3 | Device QA open |
| Device acceptance | Evidence pending |

---

## Suggested next

### Launch lane
1. Device ART QA + ship note → close **#3**  
2. Device acceptance log for tip SHA  
3. Store fields; Audio Batch 1 after license  

### Systemic lane
1. P9 residual: adaptive audio hooks (catalog only until license); device performance receipt  
2. Then P10 ten-city rule projection  
3. No city 11  
