# Repository status audit

**As of:** 2026-07-25  
**`main` tip:** `de0f632` — refactor: combat density on PresentationQualityTier (#82)  
**App version:** `0.1.0` build `1` (pre-alpha) — see [`VERSIONING.md`](VERSIONING.md) · [`versions.json`](../versions.json)

**Primary sequencing:** [`ROADMAP.md`](ROADMAP.md) (launch P0–P6 · polish P7 · systemic P8–P11)  
**Continuation paste:** [`CONTINUATION_PROMPT.md`](CONTINUATION_PROMPT.md)  
**Systemic design:** [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md)  
**Device / ship gates:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**ART inventory:** [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)  
**Art QA perception package:** [`ART_QA_PERCEPTION_AUDIT.md`](ART_QA_PERCEPTION_AUDIT.md) · [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) · [`art_qa/art_qa_audit.json`](art_qa/art_qa_audit.json)  
**Art QA combat remediation receipt:** [`ART_QA_COMBAT_READABILITY_AUDIT.md`](ART_QA_COMBAT_READABILITY_AUDIT.md)  
**Engineering style:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md)  
**P9 proof board:** [`P9_BIG_BOX_PROOF.md`](P9_BIG_BOX_PROOF.md)  
**P10 board:** [`P10_CITY_PROJECTION.md`](P10_CITY_PROJECTION.md)  
**P11 board:** [`P11_REPLAYABILITY.md`](P11_REPLAYABILITY.md)  
**Store worksheet:** [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | **None** at write (update after open PRs) |

## Recently merged (high signal)

| PR | Title |
| ---: | --- |
| [#82](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/82) | combat density on existing PresentationQualityTier |
| [#81](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/81) | combat readability via existing projectors |
| [#80](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/80) | board hygiene + challenge emulator UX smoke |
| [#79](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/79) | polish: challenge objectives, seed-stable decals, HUD labels |
| [#78](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/78) | lot-ghost trail, label mutators, Hallmark floor audit |
| [#77](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/77) | P11 unlock presentation HUD wiring |
| [#76](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/76) | P11 unlockables catalog |
| [#75](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/75) | P11 mastery store + Daily/Weekly UI |

## Phase snapshot

| Phase | Status |
| --- | --- |
| P0–P1 | Done |
| P2 device | Operator evidence open |
| P3 ART | Mostly done; device QA open (repo combat-readability #81/#82) |
| P4 audio | Catalog only; stems missing |
| P5 store | Owner fields open |
| P6 TF | Blocked on P2–P5 |
| P7 polish | Advanced (pipeline, multi-frame, floors, combat hierarchy/density) |
| P8–P9 | Systems on main (interactables, landmarks, builds) |
| P10 | **Done** (#69–#73) |
| P11 | **A–D + polish** (#74–#80); cosmetics presentation live |

## Suggested next

1. **Operator:** tip-matched `DEVICE_TEST_LOG` + [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) (gate is `ART_EVIDENCE_INSUFFICIENT` until then)  
2. **Owner:** store privacy/support URLs + ElevenLabs before audio Batch 1  
3. **Agent:** optional P2 polish (kinetic still, non-color status) only after device feedback; no city 11  

## Art ship gate (repo package)

| Field | Value |
| --- | --- |
| Package | `docs/ART_QA_PERCEPTION_AUDIT.md` |
| JSON | `docs/art_qa/art_qa_audit.json` |
| `ship_gate` | **`ART_EVIDENCE_INSUFFICIENT`** (no tip-matched device ART pass) |
| Code remediations | #81 / #82 OBSERVED fixed |
