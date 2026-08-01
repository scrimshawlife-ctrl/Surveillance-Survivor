# Repository status audit

**As of:** 2026-08-01
**`main` tip (published):** `1d38a2e` — splash + start menu + launch-smoke docs; mechanical device suite last green on binary tip `8e1c2ed` / launch-smoke on `7be94e3`. Gameplay anchor remains `0a2219e`.
**Integration tip (open PR):** `ec14dcf` — lifecycle/audio/save hardening + Prabu integrity drafts + Blind Spot wayfinding (package suite **273** local).
**App version:** `0.1.0` build `1`
**Plan:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) · **Workflow:** `/continue-ss`
**Device automation:** [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md) (`make device-accept` · `make device-test` · `make launch-smoke`)
**Launch packet:** [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| [#153](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/153) | **integration** — #152 hardening + #149 integrity/draft pacing + #150 Blind Spot wayfinding/HUD (preferred merge unit) |
| [#152](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/152) | lifecycle / presentation / save / audio hardening (included in #153) |
| [#150](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/150) | Prabu — Blind Spot compass + HUD polish (stacks on #149; included in #153) |
| [#149](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/149) | Prabu — integrity recovery upgrades + draft spacing (included in #153) |
| [#151](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/151) | Prabu — Claude Code read-only command allowlist (agent ergonomics only) |
| [#148](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/148) | **draft** — audio rights / chain-of-title package + fail-closed validator (expected BLOCKED until private evidence) |

## Recently merged

| PR | Title |
| ---: | --- |
| [#147](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/147) | post-gameplay docs reconcile and QA baseline |
| [#145](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/145) | make the game playable: combat, input, escalation, and a title screen |
| [#146](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/146) | fix PR #145 CI compilation, trim JSON churn, and refresh QA counts |
| [#144](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/144) | retry transient simulator launch failures with diagnostics |
| [#143](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/143) | keep launch-gate truth aligned with integrated audio |
| [#142](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/142) | reconcile repository documentation with current implementation |
| [#140](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/140) | improve VoiceOver control semantics |
| [#138](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/138) | harden release-readiness preflight |
| [#137](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/137) | use authoritative boss phases for audio projection |
| [#136](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/136) | unstick the visual-matrix baseline gate |
| [#135](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/135) | stop automation-tests failing on every push |
| [#134](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/134) | integrate the complete 68-asset audio bank |
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
| P2 device | Dual-launch + 14 UITests + force-extract + **launch-smoke** PASS on tip **`7be94e3`**; **re-attest after #153**; **ART eyes + live extract still open** |
| P3 ART | `ART_EVIDENCE_INSUFFICIENT` until tip-matched checklist (GitHub #3 closed; gate still honest) |
| P4 audio | **68/68 integrated**; rights (#148 draft) + physical-device listening open |
| P5 store | Owner URLs, SKU, screenshots, and ASC fields open |
| P7–P11 | Systems + presentation on main; launch shell = splash → start menu |
| Playability stack | #145 on main; **#149+#150 in #153** (repairs, draft pacing, Blind Spot compass, HUD) |
| Agent chrome residuals | Hardening + wayfinding in #153; board tip moves when #153 merges |
| Non-device QA | Integration local: **273 package** (`swift test`); baseline file reports 273/408/14 — re-run simulator after merge |
| Launch-shell smoke | **PASS (simulator)** on published tip — no `-UITesting`; splash/menu → BEGIN RUN → chrome |
| Dense visual stress | **PASS (simulator)** — deterministic fixture + normalized screenshot receipt |
| Unified non-device QA index | Package 273 verified on `ec14dcf`; full simulator UI matrix re-check after #153 lands |

## Suggested next

1. **Merge #153** (or #152 then #149 then #150) when CI green — single integration preferred
2. **Operator:** ART checklist + one **live** (non-force) extract on the post-merge tip — mechanical + launch-smoke already green on `7be94e3`
3. **Owner:** privacy/support URLs, SKU, screenshots; complete audio rights evidence for #148
4. **Agent:** board/gate honesty only after tip moves; never invent `ART_SHIP_APPROVED` or READY launch gates
5. **Optional:** #151 Claude allowlist (no product impact)

```bash
# After #153 lands — mechanical re-check:
DEVELOPMENT_TEAM=X9M969D8M3 make device-test
DEVELOPMENT_TEAM=X9M969D8M3 make device-accept
DEVELOPMENT_TEAM=X9M969D8M3 make launch-smoke
make launch-gate-check art-qa-check repo-status-check
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
- The complete 68-asset audio bank is mastered, delivered, and runtime-integrated through event cues plus state-projected ambience/music; missing or unapproved assets remain silent.
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
