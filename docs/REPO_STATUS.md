# Repository status audit

**As of:** 2026-07-28
**`main` tip:** `23abd2e` — upstream baseline receiving the integrated release-preparation merge; advanced simulator QA authority is `qa/non-device-baseline.json`
**App version:** `0.1.0` build `1`
**Plan:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) · **Workflow:** `/continue-ss`
**Device automation:** [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md) (`make device-accept` · `make device-test`)
**Launch packet:** [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | None |

## Recently merged

| PR | Title |
| ---: | --- |
| [#128](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/128) | tip 3923e2e full automated device suite pass |
| [#127](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/127) | full automated device suite pass on tip 1ac2377 |
| [#126](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/126) | tip 75fa128 after automation suite merge |
| [#125](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/125) | automation-focused deterministic suite |
| [#123](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/123) | automate mechanical Blind Spot acceptance |
| [#121](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/121) | stationary LPR LOS + chrome XCUITest stability |
| [#119](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/119) | machine-honest launch gates |

## Phase snapshot

| Phase | Status |
| --- | --- |
| P2 device | Dual-launch + **mechanical force-extract** automated on tip **`43396a6`**; **ART eyes + live extract still open** |
| P3 ART | `ART_EVIDENCE_INSUFFICIENT` until tip-matched checklist + #3 |
| P4–P5 | Owner (store URLs, ElevenLabs) |
| P7–P11 | Systems + presentation on main |
| Agent chrome residuals | **Closed** through #96; launch automation through #128 |
| Non-device QA | **PASS** — 229 package + 347 simulator + 10 UI tests (`qa/non-device-baseline.json`) |
| Dense visual stress | **PASS (simulator)** — deterministic fixture + normalized screenshot receipt |
| Unified non-device QA index | **PASS** — 229 package / 347 simulator / 10 UI baseline plus visual-matrix receipts when generated |

## Suggested next

1. **Operator:** ART device checklist + one **live** (non-force) extract on the final merge SHA ([`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) · [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md))
2. **Owner:** privacy/support URLs, SKU, screenshots, ElevenLabs
3. **Agent:** keep QA evidence and board tips aligned; never invent `ART_SHIP_APPROVED`

```bash
DEVELOPMENT_TEAM=X9M969D8M3 make device-test     # smoke + chrome + force-extract
make launch-gate-check art-qa-check
```

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

## Launch gates (machine)

| Field | Value |
| --- | --- |
| Overall | **LAUNCH_BLOCKED** |
| Check | `make launch-gate-check` |
| Manifest | [`launch/launch_gates.json`](launch/launch_gates.json) |
| Agent playbook | [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) |

| Gate | Status | Owner |
| --- | --- | --- |
| device_acceptance | EVIDENCE_INSUFFICIENT | operator |
| art_ship | EVIDENCE_INSUFFICIENT | operator |
| store_metadata | BLOCKED | owner |
| audio_product | BLOCKED | owner |
| testflight_rc | BLOCKED | shared |

*Statuses must match `launch_gates.json`. Mechanical `device-accept` does not flip READY without tip-matched ART + live extract evidence.*
