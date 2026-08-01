# Continuation plan — Surveillance Survivor

**As of:** 2026-08-01 · tip after **#153** playability + **#151** allowlist + **#148** rights package — re-read `git rev-parse --short HEAD` · gameplay anchor **`0a2219e`** · mechanical device suite on **`8e1c2ed`** / launch-smoke on **`7be94e3`** (**re-attest**)
**App:** `0.1.0` build `1` (pre-alpha)
**continue-ss result:** priority **launch** — operator phone session ([`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md)); owner store URLs + audio evidence; agent board honesty only.

---

## Authority map (read in this order)

| Priority | Doc | Role |
| ---: | --- | --- |
| 0 | [`AGENTS.md`](../AGENTS.md) | Engineering law, dual lanes, inventory-first |
| 1 | [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) | **Human** device → ART → store → audio → TF |
| 1b | [`launch/launch_gates.json`](launch/launch_gates.json) · [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) | Machine launch gates + agent promote rules |
| 2 | [`REPO_STATUS.md`](REPO_STATUS.md) | Live tip / PR board |
| 3 | [`ROADMAP.md`](ROADMAP.md) | P0–P11 phase outcomes |
| 4 | [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Evidence matrix (repo vs device) |
| 5 | [`ART_QA_PERCEPTION_AUDIT.md`](ART_QA_PERCEPTION_AUDIT.md) · [`art_qa/art_qa_audit.json`](art_qa/art_qa_audit.json) | Art ship gate + findings |
| 6 | [`HALLMARK_HUD_AUDIT.md`](HALLMARK_HUD_AUDIT.md) | HUD / settings chrome findings |
| 7 | [`WEAPON_SYSTEM_DESIGN.md`](WEAPON_SYSTEM_DESIGN.md) | Cameras → shards → upgrade draft (not coin shop) |
| 8 | [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) | Systemic identity (P8–P11) |
| 9 | [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) | Store OWNER fields |
| 10 | [`CONTINUATION_PROMPT.md`](CONTINUATION_PROMPT.md) | Paste block for new sessions |
| — | **Workflow** | `.grok/workflows/continue-ss.rhai` — multi-agent continuation orchestrator |

---

## Product state (honest)

### Done on main (systems + presentation)

- Fixed-step sim, receipts, ten-city campaign, P8–P11 (director → story, city rules, challenges, mastery, unlock presentation)
- 194 RuntimeSprites; combat hierarchy/density (#81–#82); status rings + flood teal (#85); multi-frame probe (#86)
- Compact HUD + fullscreen (#88); Art QA package with **`ART_EVIDENCE_INSUFFICIENT`** (#84)
- Gameplay loop (design authority): **splash → start menu** (district / challenges / how-to) → **stationary camera poles** (procedural per-district spawn; never chase) + **revolving red scan cones (LOS)** → cone contact and camera destruction raise **Suspicion** → Suspicion-driven guards and imminent-threat targeting escalate pressure → predictive auto-fire and analog movement support combat → destroy cameras → **Data Shards + paced 3-choice upgrade draft** (optional integrity repair/regen choices in #149) → defeat the district authority → **Blind Spot compass when exit is off-screen** (#150) → extract. **No mid-run coin shop** (shards ≠ shop currency).

### Blocked on humans

| Gate | Owner | Evidence |
| --- | --- | --- |
| P2 device acceptance | Operator | Tip-matched `DEVICE_TEST_LOG` + extract receipt |
| P3 ART ship | Operator + owner | `ART_DEVICE_QA_CHECKLIST` + #3 ship note |
| P4 audio acceptance | Operator + owner | Rights confirmation + physical-device listening, routing, interruption, and dense-mix notes |
| P5 store | Owner | Live privacy/support URLs, screenshots, ASC |
| P6 TestFlight | All above | RC binary |

### Device-smoke (not acceptance)

- 2026-07-25: iPhone 17 Pro `00008150-000A6C120CB8401C` — deploy OK on `8578b1a`+
- Operator notes drove HUD compact + fullscreen; settings restyle (#89)

---

## Dual lanes

### A — Launch (default for ship)

Follow [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) in order. Agents may **board-hygiene** and **code UX** only; never invent device logs, URLs, or audio.

### B — Agent (inventory-first only)

Allowed when launch is waiting on humans:

1. Board tip SHA / open PR hygiene
2. HUD/settings/chrome polish using `VisualDesignTokens`
3. Inventory-first presentation (`OptionalSpriteFrameCycle`, existing projectors)
4. `make art-qa-check` honesty; never set `ART_SHIP_APPROVED` without `device_evidence_paths`
5. `make launch-gate-check` honesty; demote stale READY after tip moves; never invent READY
6. No city 11; no hidden damage/HP scaling; no parallel render/density systems

Forbidden without explicit inventory:

- New PNG pipelines / re-export city packs
- Fake ART_SHIP_APPROVED
- System-sound audio

---

## Recommended next (priority)

1. **Operator:** [`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md) — mechanical suite + live extract + ART eyes on current tip
2. **Owner:** store URLs + screenshots; populate `docs/audio/rights/` ledger with **private** evidence (public repo stays opaque); `make audio-rights-check` until PASS
3. **Agent (while waiting):** board/gate honesty after tip-matched evidence only; never invent READY

---

## Gates (repo — not ship)

```bash
make art-qa-check assets-check sprite-chroma-check animation-check weapon-vfx-check
make director-check city-state-check build-engine-check coordination-check story-check
make interactables-check landmark-check clearing-builds-check city-rules-check
make challenge-contracts-check unlockables-check test
make emulator-test   # when App/Game presentation touched
DEVELOPMENT_TEAM=<team> make device-smoke   # deploy + process liveness (auto UDID)
DEVELOPMENT_TEAM=<team> make device-test    # smoke + on-device XCUITests + receipt
```

See [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md) — automation ≠ ART/extract acceptance.

---

## Workflow

| Name | Path | Use |
| --- | --- | --- |
| `continue-ss` | [`.grok/workflows/continue-ss.rhai`](../.grok/workflows/continue-ss.rhai) | Inventory tip + dual-lane status; parallel audits; synthesize next agent package |

```text
/continue-ss
# or
/workflow continue-ss
```

Optional args: `#{ lane: "launch" | "agent" | "audit" }` (default `audit`).

---

## Authority boundaries (unchanged)

```text
SurveillanceCore  → combat truth, content, receipts
SpriteKit         → projection only
SwiftUI           → HUD / lifecycle / settings
versions.json     → version registry (match project.yml)
```
