# Repository status audit

**As of:** 2026-08-01  
**`main` tip:** `44a204f` — dynamic stick at press point (implementation tip for device evidence). Board/docs continue after; re-read `git rev-parse --short HEAD`. Playability stack #153; rights #148; allowlist #151. Package **273** / simulator **417** / UI **14**. Gameplay anchor `0a2219e`.  
**App version:** `0.1.0` build `1`  
**Plan:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) · **Workflow:** `/continue-ss`  
**Device:** [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md) · [`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md) · [`device_evidence/`](device_evidence/)  
**Launch packet:** [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| *(none)* | #148–#153 landed |

## Recently merged

| PR | Title |
| ---: | --- |
| [#148](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/148) | audio rights chain-of-title package + fail-closed validator |
| [#151](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/151) | Claude Code read-only command allowlist |
| [#153](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/153) | integrate playability stack (hardening + #149 + #150) |
| [#152](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/152) | lifecycle/audio/save hardening (via #153) |
| [#150](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/150) | Blind Spot wayfinding + HUD (via #153) |
| [#149](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/149) | integrity recovery + draft pacing (via #153) |
| [#147](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/147) | post-gameplay docs reconcile and QA baseline |
| [#145](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/145) | make the game playable: combat, input, escalation, and a title screen |
| [#146](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/146) | fix PR #145 CI compilation, trim JSON churn, and refresh QA counts |

## Phase snapshot

| Phase | Status |
| --- | --- |
| P2 device | Mechanical full suite **PASS** (`7c400e7`); smoke re-check **PASS** (`a2c6e3a`); **live extracts** Louisville (`7c400e7`) + Tulsa (`44a204f`); residual: tip-match READY + listening notes |
| P3 ART | **`ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES`** (operator 2026-08-01) — see [`art_qa/art_qa_audit.json`](art_qa/art_qa_audit.json); walk density / formal 4-weapon matrix nonblocking |
| P4 audio | 68/68 integrated; ledger **scaffolded** (68 `pending_evidence` + 5 unverified slots); `audio-rights-check` **BLOCKED** until private verified evidence; listening open |
| P5 store | Privacy/support **live**; SKU **SS-IOS-001** + **Action**; **6 sim screenshot candidates** in [`store_screenshots/`](store_screenshots/) (`08042d1`); physical/release recapture open |
| P6 TF | Blocked on priors READY |
| P7–P11 | Systems + presentation on main; splash → start menu |
| Input | **Dynamic stick** — appears at press (`44a204f`) |
| Playability | #145 + #153 (repairs, draft pacing, Blind Spot compass, HUD) |
| Non-device QA | **273** package / **417** simulator-hosted / **14** UI |
| Launch-shell smoke | **PASS (device)** on `7c400e7` |
| Open PRs | **none** |

## Suggested next

Aligned with [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md):

1. **Owner/operator:** freeze ship SHA + residual closeout ([`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md))
2. **Owner:** audio rights packet + freeze-tip listening; copyright + screenshot accept
3. **Agent:** promote READY only after freeze + evidence; never invent clearance

```bash
# Honesty
make launch-gate-check art-qa-check repo-status-check release-docs-check

# Mechanical re-check if binary tip moves:
DEVELOPMENT_TEAM=X9M969D8M3 make device-test
DEVELOPMENT_TEAM=X9M969D8M3 make device-accept
DEVELOPMENT_TEAM=X9M969D8M3 make launch-smoke
```

## Latest increments (2026-08-01)

- Residual closeout guide landed ([`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md) design + playbook)
- Playability stack #153 (integrity drafts, draft pacing, Blind Spot compass, HUD)
- Hardening (pause lifecycle, presentation interpolation, save compat, audio delivery)
- Audio rights package #148 (fail-closed)
- Device mechanical suite on `7c400e7`
- Live Louisville extract (`7c400e7`) + live Tulsa extract (`44a204f`)
- Dynamic movement stick at press point (`44a204f`)
- Continuation plan refreshed for launch residual path
- Operator ART approval → `ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES` (2026-08-01)
- Batch 2B prop-stable idle frames
- Store privacy/support live (zero-state Pages) + SKU/Action locked
- Six App Store screenshot **simulator candidates** packed under [`store_screenshots/`](store_screenshots/) (`08042d1`)

- Audio rights ledger scaffolded (pending only) + owner packet

Owner copyright confirm, Connect screenshot accept/recapture, **private rights evidence**, and listening notes remain open. Launch overall still **LAUNCH_BLOCKED**.

## Art ship gate

| Field | Value |
| --- | --- |
| `ship_gate` | **ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES** |
| Check | `make art-qa-check` |
| Approval | Operator 2026-08-01 — “art approved for now” |

## Launch gates (machine)

| Field | Value |
| --- | --- |
| Overall | **LAUNCH_BLOCKED** |
| Check | `make launch-gate-check` |
| Manifest | [`launch/launch_gates.json`](launch/launch_gates.json) |
| Agent playbook | [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) |

| Gate | Status | Tip / note |
| --- | --- | --- |
| device_acceptance | EVIDENCE_INSUFFICIENT | `44a204f` — mechanical + live extracts; not READY |
| art_ship | EVIDENCE_INSUFFICIENT | art_qa approved w/ notes; launch READY awaits tip-match + device_acceptance READY |
| store_metadata | EVIDENCE_INSUFFICIENT | URLs + SKU + sim screenshots; not READY |
| audio_product | BLOCKED | pending_evidence scaffold; rights + listening |
| testflight_rc | BLOCKED | shared |

*Statuses must match `launch_gates.json`. Checker exit 0 means honest, not ship-ready.*
