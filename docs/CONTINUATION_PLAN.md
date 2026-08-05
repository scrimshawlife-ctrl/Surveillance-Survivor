# Continuation plan — Surveillance Survivor

**As of:** 2026-08-05  
**App:** `0.1.0` build `1` (pre-alpha)  
**HEAD (board):** re-read `git rev-parse --short HEAD` (board tip `cab9900` / #159 sprites + #156 urban; device residual `f2406fc`)  
**Gameplay anchor:** `0a2219e` (#145 playability) · **Playability stack:** #153 on main  
**Overall launch:** **LAUNCH_BLOCKED** (honest) · **Art ship:** **ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES** (operator 2026-08-01; re-attest owed on new tip)  
**Open PRs:** none  
**Audit:** [`CONTINUATION_REPORT_2026-08-04_prabu_hygiene.md`](CONTINUATION_REPORT_2026-08-04_prabu_hygiene.md)

**continue-ss priority:** residual closeout per [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md) (ART re-attest on HEAD → freeze ship SHA → store + audio rights + tip-match READY) → TestFlight only when all gates READY. Post-merge audits C–A filed 2026-08-05. No READY invention.

**Presentation on main:** UrbanDress + satellite 1.38 + 1.5× arenas (#156) and prompted **341** sprites/VFX/animation frames (#159). Worktrees for those lanes may be removed.

---

## Authority map (read in this order)

| Priority | Doc | Role |
| ---: | --- | --- |
| 0 | [`AGENTS.md`](../AGENTS.md) | Engineering law, dual lanes, inventory-first |
| 1 | [`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md) | Phone session script (mechanical done; ART residual) |
| 1b | [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) | Human ordered launch path |
| 1c | [`launch/launch_gates.json`](launch/launch_gates.json) · [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) | Machine gates + promote rules |
| 1d | [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md) | Residual freeze + RC cut allowed path |
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
| Non-device QA | 273 package / 431 simulator-hosted / 14 UI journeys |
| Art inventory | **341** runtime PNGs + catalog parity; multi-frame VFX/animation banks |

### Device evidence already on disk

| Tip | Where | Evidence |
| --- | --- | --- |
| `f2406fc` | **main** residual | Mechanical suite re-pin + **live Louisville** (device_acceptance gate tip) |
| `44a204f` | **main** history | Dynamic stick + **live Tulsa** |
| `7c400e7` | **main** history | Full mechanical suite (smoke, 14 UI, force-extract, launch-smoke) + Louisville path |
| `541627b` | **main** (via #156) | Live Tulsa on UrbanDress binary (not residual freeze; not gate tip) |
| `51d3780` / `0d8242c` | **main** history | Device-smoke (satellite zoom / two-way streets) during urban lane |

Receipts under [`device_evidence/`](device_evidence/): live extract JSON (`*_f2406fc`, `*_44a204f`, `*_7c400e7`, `*_541627b`, `*_latest`); archived suite transcripts [`run_logs/2026-08-01_7c400e7_mechanical_suite/`](device_evidence/run_logs/2026-08-01_7c400e7_mechanical_suite/); automation PASS [`automation_runs/2026-07-26_ef7d271_passed/`](device_evidence/automation_runs/2026-07-26_ef7d271_passed/).

Device: iPhone 17 Pro `00008150-000A6C120CB8401C`, iOS 26.3.1, team `X9M969D8M3`.

**Frame notes (live):** residual extracts often p50/p95 ≈ 16.67 ms; some runs p95 elevated — note only, not a READY flip.

### Presentation (on main via #156 + #159) — operator feedback + status

| Item | Result |
| --- | --- |
| Satellite camera 1.38 | **Pass** (zoom appropriate; tracks; combat good) — on main |
| UrbanDress streets/buildings | **On main** (#156); ART re-attest on HEAD still owed |
| Prompted sprites / VFX / animation | **On main** (#159); 341 PNGs + catalog; frame probe limit 16 |
| Terrain carpet + pale ground | **On main** (entity contrast for prompted set) |

### Machine gates

| Gate | Status | Blocker |
| --- | --- | --- |
| `device_acceptance` | EVIDENCE_INSUFFICIENT | Mechanical + live extracts filed; not READY (ART residual; tip-match rules for READY) |
| `art_ship` | EVIDENCE_INSUFFICIENT | art_qa **APPROVED_WITH_NONBLOCKING_NOTES**; launch READY needs tip-match + `device_acceptance` READY |
| `store_metadata` | EVIDENCE_INSUFFICIENT | URLs + SKU live; 6 sim screenshot candidates; physical/release + copyright open |
| `audio_product` | BLOCKED | Ledger scaffolded (`pending_evidence`); private verified evidence + listening still open |
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
| 3 | Operator | [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) ship call | **Done** (approved for now → art_qa nonblocking notes) |
| 4 | Owner | Live privacy + support HTTPS, SKU, copyright, subcategory, release screenshots | **Partial** — URLs/SKU/Action + sim candidates; physical/release + copyright open |
| 5 | Owner | Private audio evidence → ledger; `make audio-rights-check` PASS; device listening notes | **Open** |
| 6 | Shared | TestFlight RC only when gates READY | **Blocked** |

Agents **never** invent READY, ART_SHIP_APPROVED, store URLs, or rights clearance.

### B — Agent (only while launch waits)

Allowed:

1. Board hygiene (`REPO_STATUS`, gate tip reasons) after real evidence  
2. Inventory-first presentation / tokenized chrome (isolated worktree for new lanes)  
3. Honest gate demotion after tip moves  
4. Small UX fixes proven on device (e.g. stick placement — already shipped)  
5. Perf investigation for frame max spikes **only** if operator confirms hitching  
6. **Do not** invent ART_SHIP READY or tip-matched device_acceptance without residual criteria  

Forbidden without explicit inventory/approval:

- City 11, new weapons, PNG re-export pipelines  
- Fake ship gates  
- System-sound audio  
- Scope expansion “because simulator is green”

---

## Recommended next (priority)

### 1. Owner/operator — TestFlight RC residual (primary)

Follow [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md): freeze ship SHA, then store residual, audio rights+listening, tip-match device/ART. Promote gates only per residual criteria. RC cut allowed ≠ upload.

### 2. Owner — store + rights (within residual closeout)

ART is operator-approved with nonblocking notes (2026-08-01).

| Item | Doc |
| --- | --- |
| Privacy + support live HTTPS | [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) |
| SKU, copyright, age, subcategory | same |
| Screenshots from release/device build | Sim candidates in [`store_screenshots/`](store_screenshots/); prefer ship-SHA physical recapture |
| Opaque evidence IDs in ledger | [`audio/rights/OWNER_EVIDENCE_PACKET.md`](audio/rights/OWNER_EVIDENCE_PACKET.md) · [`EVIDENCE_CHECKLIST.md`](audio/rights/EVIDENCE_CHECKLIST.md) |
| Validate | `make audio-rights-check` until PASS (scaffold is not PASS) |

### 3. Agent — after owner artifacts / ship SHA freeze

| When | Action |
| --- | --- |
| Store pack complete | Promote `store_metadata` READY only with owner accept or tip-matched physical stills + copyright confirm |
| Rights ledger verified | Promote `audio_product` only if validator PASS + listening notes tip-matched |
| Frozen ship SHA | Tip-match promote `device_acceptance` + launch `art_ship` READY if evidence still valid |
| All READY | `testflight_rc` allow RC cut — do not invent upload |

### 4. Optional agent residual (low priority)

- **Done:** #155, #156, #159 merged to main  
- ART re-attest + optional device suite on HEAD (`bdf78cc`) before residual READY  


- Frame receipt sampling now excludes draft/post-run UI hitch frames (shipped); re-check max on next live extract  
- Mechanical suite re-run when **binary** tip moves after stick/ART-related code  
- Board tip field vs implementation tip hygiene (`repo-status-check`)  
- Owner may delete stale merged remotes (see Prabu hygiene audit)  

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
docs/launch/TESTFLIGHT_RC_RESIDUAL.md, docs/launch/launch_gates.json,
docs/device_evidence/, docs/OPERATOR_PHONE_SESSION.md.
Re-pin: git rev-parse --short HEAD.
Primary path: residual freeze + RC cut allowed per TESTFLIGHT_RC_RESIDUAL.md.
State: playability + dynamic stick + UrbanDress + prompted 341 sprites on main (bdf78cc);
mechanical device PASS on f2406fc; live extracts Louisville + Tulsa filed.
Open PRs: none.
Art: ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES (operator 2026-08-01) — re-attest on HEAD.
Open: freeze ship SHA; ART re-attest; owner copyright + Connect screenshot accept;
audio rights private evidence (scaffold is not clearance) + listening;
tip-match launch READY. RC cut allowed ≠ upload.
Never invent store READY or rights clearance.
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
