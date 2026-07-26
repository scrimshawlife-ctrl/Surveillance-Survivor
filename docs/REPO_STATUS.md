# Repository status audit

**As of:** 2026-07-26  
**`main` tip:** `47b1f5b` — device mechanical acceptance automation (#123)  
**App version:** `0.1.0` build `1`  
**Plan:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) · **Workflow:** `/continue-ss`  
**Device automation:** [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md) (`make device-accept`)  
**Launch packet:** [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | None |

## Recently merged

| PR | Title |
| ---: | --- |
| [#123](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/123) | automate mechanical Blind Spot acceptance |
| [#122](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/122) | tip 7423f90 deploy ready for operator acceptance |
| [#121](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/121) | stationary LPR LOS + chrome XCUITest stability |
| [#119](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/119) | machine-honest launch gates |
| [#116](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/116) | medium: sensor deploy budget, landmark hazards, build history, director |

## Phase snapshot

| Phase | Status |
| --- | --- |
| P2 device | Dual-launch + **mechanical force-extract** automated on tip **`47b1f5b`**; **ART eyes + live extract still open** |
| P3 ART | `ART_EVIDENCE_INSUFFICIENT` until tip-matched checklist + #3 |
| P4–P5 | Owner (store URLs, ElevenLabs) |
| P7–P11 | Systems + presentation on main |
| Agent chrome residuals | **Closed** through #96; launch automation through #123 |

## Suggested next

1. **Operator:** ART device checklist + one **live** (non-force) extract on tip `47b1f5b+` ([`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) · [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md))  
2. **Owner:** privacy/support URLs, SKU, screenshots, ElevenLabs  
3. **Agent:** board tip hygiene; never invent `ART_SHIP_APPROVED`  

```bash
DEVELOPMENT_TEAM=X9M969D8M3 make device-accept   # mechanical only
make launch-gate-check art-qa-check
```

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
