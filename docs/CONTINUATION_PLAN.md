# Continuation plan — Surveillance Survivor

**As of:** 2026-08-01  
**App:** `0.1.0` build `1` (pre-alpha)  
**HEAD (board):** re-read `git rev-parse --short HEAD` (recent: `b9cc76e` docs / `44a204f` dynamic stick)  
**Gameplay anchor:** `0a2219e` (#145 playability) · **Playability stack:** #153 on main  
**Overall launch:** **LAUNCH_BLOCKED** (honest) · **Art ship:** **ART_EVIDENCE_INSUFFICIENT**  
**Open PRs:** none  

**continue-ss priority:** finish **operator ART checklist** → **owner store + audio rights** → TestFlight only when gates flip with tip-matched evidence.

---

## Authority map (read in this order)

| Priority | Doc | Role |
| ---: | --- | --- |
| 0 | [`AGENTS.md`](../AGENTS.md) | Engineering law, dual lanes, inventory-first |
| 1 | [`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md) | Phone session script (mechanical done; ART residual) |
| 1b | [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) | Human ordered launch path |
| 1c | [`launch/launch_gates.json`](launch/launch_gates.json) · [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) | Machine gates + promote rules |
| 2 | [`REPO_STATUS.md`](REPO_STATUS.md) | Live tip / PR board |
| 3 | [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) · [`device_evidence/`](device_evidence/) | Device + live extract receipts |
| 4 | [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) | Operator eyes (still open) |
| 5 | [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Evidence matrix |
| 6 | [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) | Store OWNER fields |
| 7 | [`audio/rights/README.md`](audio/rights/README.md) | Fail-closed rights (`make audio-rights-check`) |
| 8 | [`ROADMAP.md`](ROADMAP.md) · [`WEAPON_SYSTEM_DESIGN.md`](WEAPON_SYSTEM_DESIGN.md) | Phases + combat identity |
| 9 | [`CONTINUATION_PROMPT.md`](CONTINUATION_PROMPT.md) | Paste block for new sessions |
| — | Workflow | `.grok/workflows/continue-ss.rhai` |

---

## Snapshot (honest)

### Playable product on main

| Area | State |
| --- | --- |
| Core / campaign | Fixed-step sim, ten cities, P8–P11 systems, mastery/challenges |
| Combat loop | Stationary LPR + scan cones → Suspicion → guards; predictive auto-fire; analog speed |
| Upgrades | Paced 3-choice drafts; integrity repair/regen (`emergencyRepair`, `redundantSystems`) |
| Boss / extract | Integrity bar; Blind Spot **compass** off-screen; live extract proven |
| Input | **Dynamic stick** — appears at press point anywhere on the field (`44a204f`) |
| Shell | Splash → start menu → BEGIN RUN; launch-smoke on device |
| Audio bank | 68/68 runtime-integrated; missing assets stay silent |
| Art inventory | 194 runtime PNGs; machine art gate not ship-approved |
| Non-device QA | 273 package / 416 simulator-hosted / 14 UI journeys |

### Device evidence already on disk (2026-08-01)

| Tip | Evidence |
| --- | --- |
| `7c400e7` | Full mechanical suite (smoke, 14 UI, force-extract, launch-smoke) + **live Louisville extract** |
| `44a204f` | Dynamic-stick build + **live Tulsa extract** (campaign → Dayton unlocked) |
| Receipts | [`device_evidence/live_extract_summary_44a204f.json`](device_evidence/live_extract_summary_44a204f.json) · `*_7c400e7.json` · `*_latest.json` |

Device: iPhone 17 Pro `00008150-000A6C120CB8401C`, iOS 26.3.1, team `X9M969D8M3`.

**Frame notes (live):** p50/p95 ≈ 16.67 ms (at budget); max spikes ~200 ms — optional later polish, not a launch-gate invention.

### Machine gates

| Gate | Status | Blocker |
| --- | --- | --- |
| `device_acceptance` | EVIDENCE_INSUFFICIENT | Mechanical + live extracts filed; not READY (ART residual; tip-match rules for READY) |
| `art_ship` | EVIDENCE_INSUFFICIENT | No completed ART checklist + ship call |
| `store_metadata` | BLOCKED | Owner URLs, SKU, screenshots |
| `audio_product` | BLOCKED | Rights ledger empty (`audio-rights-check` → 68 blockers); physical listening notes |
| `testflight_rc` | BLOCKED | Depends on all priors READY |
| **Overall** | **LAUNCH_BLOCKED** | Checker exit 0 = honest, not ship-ready |

---

## Dual lanes

### A — Launch (default — humans)

Ordered path: [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md).

| Step | Owner | Work | Status |
| ---: | --- | --- | --- |
| 1 | Operator | Mechanical device suite | **Done** (`7c400e7`) |
| 2 | Operator | Live Blind Spot extract (non-force) | **Done** (Louisville + Tulsa) |
| 3 | Operator | [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) pass/fail + optional background/haptics/VO | **Open** |
| 4 | Owner | Live privacy + support HTTPS, SKU, copyright, subcategory, release screenshots | **Open** |
| 5 | Owner | Private audio evidence → ledger; `make audio-rights-check` PASS; device listening notes | **Open** |
| 6 | Shared | TestFlight RC only when gates READY | **Blocked** |

Agents **never** invent READY, ART_SHIP_APPROVED, store URLs, or rights clearance.

### B — Agent (only while launch waits)

Allowed:

1. Board hygiene (`REPO_STATUS`, gate tip reasons) after real evidence  
2. Inventory-first presentation / tokenized chrome  
3. Honest gate demotion after tip moves  
4. Small UX fixes proven on device (e.g. stick placement — already shipped)  
5. Perf investigation for frame max spikes **only** if operator confirms hitching  

Forbidden without explicit inventory/approval:

- City 11, new weapons, PNG re-export pipelines  
- Fake ship gates  
- System-sound audio  
- Scope expansion “because simulator is green”

---

## Recommended next (priority)

### 1. Operator — ART ship checklist (this week)

On tip **`44a204f`+** (re-pin SHA if binary moved):

1. Open [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md)  
2. One mid-run combat read (player / projectiles / cones / boss / Blind Spot + compass)  
3. Sample ≥3 cities for floor identity  
4. Reduced-motion / reduced-flash (already often ON in prefs)  
5. Ship call: yes / no + notes  

Hand results to agent → file in `DEVICE_TEST_LOG` → only then consider `art_ship` / `ART_SHIP_APPROVED` under playbook rules.

### 2. Owner — store + rights (parallel, no phone)

| Item | Doc |
| --- | --- |
| Privacy + support live HTTPS | [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) |
| SKU, copyright, age, subcategory | same |
| Screenshots from release/device build | after ART pass preferred |
| Opaque evidence IDs in ledger | [`audio/rights/EVIDENCE_CHECKLIST.md`](audio/rights/EVIDENCE_CHECKLIST.md) |
| Validate | `make audio-rights-check` until PASS |

### 3. Agent — only after operator/owner artifacts

| When | Action |
| --- | --- |
| ART checklist filled | Update log + art-qa evidence paths per playbook; run `make art-qa-check` |
| Store URLs live | Promote `store_metadata` only if paths + URLs real |
| Rights ledger verified | Promote `audio_product` only if validator PASS + listening notes tip-matched |
| All READY | `testflight_rc` allow RC cut — do not invent upload |

### 4. Optional agent residual (low priority)

- Frame receipt sampling now excludes draft/post-run UI hitch frames (shipped); re-check max on next live extract  
- Mechanical suite re-run when **binary** tip moves after stick/ART-related code  
- Board tip field vs implementation tip hygiene (`repo-status-check`)  

---

## Not recommended next

- New systemic content or city expansion before launch evidence  
- Claiming TestFlight readiness from live extracts alone  
- Closing audio rights without private archive  
- Marking `device_acceptance` READY without meeting playbook tip-match + residual checklist policy  

---

## Verification commands

```bash
# Honesty (expect LAUNCH_BLOCKED + ART_EVIDENCE_INSUFFICIENT)
make launch-gate-check art-qa-check repo-status-check release-docs-check

# Product / content
make version-check audio-check assets-check
# make audio-rights-check   # expect BLOCKED until ledger evidence

# Non-device QA
make test
# make emulator-test   # if App/Game presentation touched

# Device (team example)
DEVELOPMENT_TEAM=X9M969D8M3 make device-smoke
DEVELOPMENT_TEAM=X9M969D8M3 make device-test
DEVELOPMENT_TEAM=X9M969D8M3 make device-accept
DEVELOPMENT_TEAM=X9M969D8M3 make launch-smoke
```

---

## Session paste (new agent)

```text
Surveillance Survivor continuation.
Read: AGENTS.md, docs/CONTINUATION_PLAN.md, docs/REPO_STATUS.md,
docs/launch/launch_gates.json, docs/device_evidence/, docs/OPERATOR_PHONE_SESSION.md.
Re-pin: git rev-parse --short HEAD.
State: playability + dynamic stick on main; mechanical device PASS;
live extracts Louisville (7c400e7) + Tulsa (44a204f) filed.
Open: ART checklist eyes; owner store URLs; audio rights ledger + listening.
Never invent READY / ART_SHIP_APPROVED / store URLs.
```

Workflow: `/continue-ss` or `/workflow continue-ss` with optional `#{ lane: "launch" | "agent" | "audit" }`.

---

## Authority boundaries (unchanged)

```text
SurveillanceCore  → combat truth, content, receipts
SpriteKit         → projection only
SwiftUI           → HUD / lifecycle / settings / dynamic stick
versions.json     → version registry (match project.yml)
```
