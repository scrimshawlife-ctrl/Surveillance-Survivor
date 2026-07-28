# Repository status audit

**As of:** 2026-07-28
**QA working tip:** `b5c1637` — current review tip; advanced simulator QA baseline is integrated in `qa/non-device-baseline.json`
**App version:** `0.1.0` build `1`  
**Plan:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) · **Workflow:** `/continue-ss`  
**Device automation:** [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md)  
**Closeout:** [`CONTINUATION_REPORT_2026-07-25_tip8a84315.md`](CONTINUATION_REPORT_2026-07-25_tip8a84315.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | None (update after closeout PR lands) |

## Recently merged

| PR | Title |
| ---: | --- |
| [#96](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/96) | pause expanded suspicion meter + board/device log hygiene |
| [#95](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/95) | GameChrome receipt, district list, upgrade queue cue |
| [#94](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/94) | physical device automation suite |
| [#93](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/93) | tip-matched device-smoke deploy proof for c468b90 |
| [#92](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/92) | continue-ss closeout for tip deb1d4f |

## Phase snapshot

| Phase | Status |
| --- | --- |
| P2 device | Dual-launch smoke on **`8a84315`** pass; **full acceptance open** |
| P3 ART | `ART_EVIDENCE_INSUFFICIENT` |
| P4–P5 | Owner |
| P7–P11 | Systems + presentation on main |
| Agent chrome residuals | **Closed** through #96 |
| Non-device QA | **PASS** — 229 package + 347 simulator + 10 UI tests (`qa/non-device-baseline.json`) |
| Dense visual stress | **PASS (simulator)** — deterministic fixture + normalized screenshot receipt |
| Unified non-device QA index | **PASS** — 229 package / 347 simulator / 10 UI baseline plus visual-matrix receipts when generated |

## Suggested next

1. **Operator:** full device acceptance on current tip ([`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) step 2)  
2. **Owner:** store URLs + ElevenLabs  
3. **Agent next slice:** keep QA evidence formats and release docs tip-aligned as branches land

## Latest non-device QA increment

- Deterministic XCUITest launch states: upgrade, extraction, defeat, and dense combat.
- Daily and weekly challenge launch journeys.
- Reduced-motion setting interaction and sheet-reopen persistence.
- Raw and normalized landscape simulator screenshots.
- `make simulator-visual-matrix` for 20 ordinary/reduced city panels, unique semantic city metadata checks, and a generated contact sheet.
- Every authored interactable is now activation-tested across all ten cities.
- SF, Columbus, NYC, LA, and Atlanta publish deterministic boss phases to events, receipts, HUD, and accessibility.
- Atlanta's Chimera is explicitly boss-prelude narrative metadata, not a separate unimplemented entity.
- Approved bundle audio now has a real AVFoundation playback path; missing or unapproved assets remain silent.
- Reduced-flash mode dims city overlays while retaining non-color wayfinding and phone-scale labels.
- Dense review repaired Suspicion `S5` wrapping under HUD pressure.

These claims remain simulator-only. Thermal behavior, haptics, audio routing, touch ergonomics, and ship-grade combat readability still require a physical iPhone.

## Art ship gate

| Field | Value |
| --- | --- |
| `ship_gate` | **ART_EVIDENCE_INSUFFICIENT** |
| Check | `make art-qa-check` |
