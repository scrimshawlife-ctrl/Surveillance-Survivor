# Post-merge audit program design (C → D → B → A)

**Date:** 2026-08-05  
**Product:** Surveillance Survivor  
**Status:** Design approved (brainstorm)  
**Tip context at design:** `main` after #156 (UrbanDress / satellite / 1.5× arenas) and #159 (prompted sprites, 341 PNGs); open PRs none; launch overall **LAUNCH_BLOCKED**  
**Device residual tip (not HEAD):** `f2406fc` mechanical + live Louisville  
**Gameplay anchor:** `0a2219e`  

## 1. Purpose

Run four **separate** audits that together answer: *after the urban + sprite merges, what is true, what is broken, and what is honestly left for TestFlight residual?*

This is **not** a feature build. It is an evidence and honesty program. It must not invent READY, store clearance, audio rights clearance, or tip-matched device acceptance.

## 2. Decomposition and sequence

| Order | ID | Name | Audience | Decision unlocked |
| ---: | --- | --- | --- | --- |
| 1 | **C** | Repo / agent hygiene | Agents + owner | Is the board / remotes / worktree map honest? |
| 2 | **D** | Architecture / sim-isolation | Engineers | Is Core still combat/collision authority after #156/#159? |
| 3 | **B** | Presentation / art | Operator + art | Is HEAD readable/flash-safe enough for residual ART re-attest (not a code emergency)? |
| 4 | **A** | Post-merge ship residual | Owner + operator | What is the honest path to TestFlight residual freeze / go-no-go? |

**Sequence is mandatory:** C → D → B → A.  
A **only summarizes** C/D/B findings; it does not re-run their full methods.

**Rejected alternatives:** parallel four-writers (board races); single mega-audit mixing audiences; umbrella-only thin checklists without residual scoreboard.

## 3. Shared program rules

Apply to every audit:

1. **Tip freeze** at start of each audit execution:  
   `git rev-parse HEAD` and short SHA; `git status --short`. Dirty tree explained or rejected as ship evidence.  
2. **Machine honesty ≠ ship-ready:** `make launch-gate-check` (and peers) exit 0 means *honest*, not READY.  
3. **Never invent:** READY, `ART_SHIP_APPROVED` on a new tip, store URLs, rights ledger verified, tip-matched device_acceptance.  
4. **Simulation ownership:** `SurveillanceCore` owns combat, collision AABBs, damage, spawns, content layout. SpriteKit / presentation / textures never redefine hit timing or paths.  
5. **Findings format** (every report):

   | Severity | Claim | Evidence (path / SHA / command) | Disposition |
   | --- | --- | --- | --- |
   | High / Medium / Low / Info | … | … | fix / owner / accept risk / N/A |

6. **Non-claims section** required in every report.  
7. **Shared tip:** Prefer the same product tip for the whole program when possible. If tip moves mid-program, freeze the new tip and note which audits re-ran.

### Baseline machine pack (minimum, each audit start)

```bash
git fetch origin --prune
git rev-parse HEAD
git rev-parse --short HEAD
git status --short
make version-check repo-status-check launch-gate-check art-qa-check assets-check
```

Scoped extras: **C** + `gh pr list` / remotes / worktrees; **D** + isolation searches / cited tests; **B** + `weapon-vfx-check` / `animation-check` / operator checklist; **A** + residual playbook + gate table.

## 4. Deliverables map

| Artifact | Path |
| --- | --- |
| This design | `docs/superpowers/specs/2026-08-05-post-merge-audit-program-design.md` |
| Program index (implementation) | `docs/audits/README.md` |
| C report | `docs/CONTINUATION_REPORT_YYYY-MM-DD_hygiene_audit.md` |
| D report | `docs/CONTINUATION_REPORT_YYYY-MM-DD_architecture_isolation_audit.md` |
| B report | `docs/CONTINUATION_REPORT_YYYY-MM-DD_presentation_art_audit.md` |
| A report | `docs/CONTINUATION_REPORT_YYYY-MM-DD_ship_residual_audit.md` |

Optional later (only if C finds stale boards): focused docs PR. Isolation/asset **blocking bugs** become **separate fix plans**, not silent audit scope creep.

## 5. Audit C — Repo / agent hygiene

### 5.1 In scope

- `docs/REPO_STATUS.md`, `docs/CONTINUATION_PLAN.md`, `docs/CONTINUATION_PROMPT.md` claims vs git/gh  
- Open PRs / issues vs board tables  
- Merged remotes still on `origin`; retired bootstrap names (`agent/iphone-bootstrap`, `agent/prabu-openclaw`)  
- `git worktree list` vs “active lanes” narrative  
- Local branches with gone upstream (inventory; prune optional)  
- Documented tip ancestor of HEAD; launch gate tips vs residual docs  

### 5.2 Out of scope

- Art readability (B), Core isolation (D), ship go/no-go body (A) beyond “board claims X”

### 5.3 Method

1. Tip freeze + baseline machine pack.  
2. `gh pr list --state open`; `gh issue list --state open`.  
3. `git branch -r --merged origin/main`.  
4. `git worktree list`.  
5. Diff board language to machine truth → findings table.  
6. Write C report + non-claims.

### 5.4 Success criteria

- Every open-PR / tip / lane claim is true or marked stale with evidence.  
- No “active bootstrap” or phantom open PRs.  
- Reproducible by another agent in ≤30 minutes.

## 6. Audit D — Architecture / sim-isolation

### 6.1 In scope

**Ownership map**

| Layer | Owns | Must not own |
| --- | --- | --- |
| `Sources/SurveillanceCore` | Sim time, entities, AABB collision, damage, spawns, content (`districts.json`, perimeter margin) | Pixel art, frame indices as hit logic |
| `Game/Presentation` (`UrbanDress*`) | Pure dress from `WorldLayout` | Mutating sim state |
| `Game/Rendering` | Projection, terrain carpet, frame cycles | Combat resolution |
| `Game/Scenes` | Input, camera scale (e.g. 1.38) | Authoritative range/damage |

**Anti-pattern search (minimum)**

- `SKPhysics` / physics contact for combat or extract  
- Presentation writing entity health / sim positions / projectile paths  
- Sprite size or frame index used as hit radius or damage timing  
- Non-deterministic RNG in dress builder (prefer none)

**Post-merge contracts**

- 1.5× arenas + `navigablePerimeterMargin` = **sim/content**  
- Terrain carpet / pale ground = **presentation**  
- `OptionalSpriteFrameCycle.probeLimit` = **presentation**  

**Tests to cite:** `SimulationTests` (layout/perimeter); `UrbanDressBuilderTests`; `WorldProjectorUrbanDressTests`.

### 6.2 Out of scope

Subjective art quality; board remotes; TF residual scoreboard; refactors beyond findings.

### 6.3 Method

1. Tip freeze + baseline pack.  
2. Inventory #156/#159 touch points (presentation vs Core).  
3. Run documented ripgrep pack; record hits.  
4. Read `UrbanDressBuilder.build`, `DistrictGenerator.generate`, projector ground/roads.  
5. Findings: isolation **pass/fail**; High = combat-truth violation.

### 6.4 Success criteria

- Explicit pass/fail on “Core owns combat truth.”  
- Sim content changes listed separately from pure presentation.  
- Zero unexplained physics-combat paths (or High findings).

## 7. Audit B — Presentation / art

### 7.1 In scope

**Machine**

- `make assets-check` (expect 341 RuntimeSprites ↔ catalog parity at design tip)  
- `make weapon-vfx-check`, `make animation-check`  
- `make art-qa-check` / `docs/art_qa/art_qa_audit.json` vs HEAD  
- Existing chroma / opaque-corner scripts if present  

**Systems**

- UrbanDress layers (roads, sidewalks, buildings, props)  
- Satellite camera 1.38 readability  
- Terrain carpet (256, full, nearest) + pale ground contrast  
- Multi-frame banks; reduced-motion / reduced-flash gaps flagged  

**Operator checklist** (device preferred; simulator weaker — label strength)

- Player / guard / boss readable at combat range  
- LPR / suspicion / projectiles distinct  
- Blind Spot extract readable  
- Flash safety on telegraphs/pulses  
- City sample: full ten cities **or** documented subset (e.g. Wichita, Louisville, Tulsa + two dense cities)

### 7.2 Out of scope

New art generation; combat balance; promoting `art_ship` READY.

### 7.3 Method

1. Tip freeze + asset/art gates.  
2. Fill checklist with `pass` / `fail` / `not_run` / `blocked_no_device`.  
3. Mark prior `ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES` as **stale for HEAD** if tip ≠ approval tip.  
4. Findings: **code/art defect before re-attest** vs **ready for operator re-attest**.

### 7.4 Success criteria

- Clear binary recommendation for residual ART re-attest.  
- Machine asset gates green or listed failures.  
- No silent reuse of pre-#156/#159 ART approval as tip-matched.

## 8. Audit A — Post-merge ship residual

### 8.1 In scope

- Consume C/D/B report summaries only.  
- Residual authority: `docs/launch/TESTFLIGHT_RC_RESIDUAL.md`, `docs/launch/launch_gates.json`, `docs/launch/AGENT_LAUNCH_PLAYBOOK.md`.  
- Gate scoreboard:

  | Gate | Machine status | Tip | Blocker | Owner |
  | --- | --- | --- | --- | --- |
  | device_acceptance | … | … | … | … |
  | art_ship | … | … | … | … |
  | store_metadata | … | … | … | … |
  | audio_product | … | … | … | … |
  | testflight_rc | … | … | … | … |

- Evidence vs HEAD: device suite tips, live extracts, sim screenshots, rights scaffold.  
- Ordered next actions (human vs agent).  
- **RC cut allowed ≠ upload.**

### 8.2 Out of scope

App Store Connect actions; private rights archive fill; declaring READY without residual criteria.

### 8.3 Method

1. Run launch honesty gates; capture output.  
2. Import C/D/B findings that block ship.  
3. One-page go/no-go: freeze now or not; list L of blockers.  
4. Write A report (owner-facing).

### 8.4 Success criteria

- Owner can decide freeze / next humans from one doc.  
- Consistent with machine `LAUNCH_BLOCKED` unless residual criteria truly met (they are not claimed by this design).  
- Zero invented READY.

## 9. Program index (implementation artifact)

`docs/audits/README.md` shall link:

- This design  
- Execution order C→D→B→A  
- Shared tip-freeze + machine pack  
- Paths to the four reports (once written)  
- Pointer to residual playbook and `REPO_STATUS`

Index is navigation only; it does not duplicate gate truth.

## 10. Error handling and honesty failures

| Situation | Response |
| --- | --- |
| Board claims open PR that is merged | C finding High; fix in hygiene PR or note until fixed |
| Isolation anti-pattern found | D High; stop claiming presentation-only; open fix plan |
| Device unavailable for B | Mark checklist `blocked_no_device`; do not invent pass |
| Tip moves mid-program | Re-freeze; re-run machine pack; note which audits invalidated |
| Pressure to mark READY | Refuse; cite residual playbook and non-claims |

## 11. Testing / verification of the program itself

The program is verified when:

1. Four reports exist with findings tables and non-claims.  
2. A report cites C/D/B (or records “not yet run” only during partial execution — final A requires C/D/B complete).  
3. `make repo-status-check launch-gate-check` still honest after any board hygiene PR.  
4. No report claims launch READY without residual criteria.

## 12. Implementation plan boundary (next skill)

After this design is approved in-repo by the user:

1. Invoke **writing-plans** to produce `docs/superpowers/plans/2026-08-05-post-merge-audit-program.md` with task-level steps for index + C + D + B + A.  
2. Execution follows that plan only.  
3. Product code changes only if a **separate** fix plan is written for a High finding.

## 13. Non-goals (program)

- TestFlight upload  
- New cities, weapons, or systemic content  
- Regenerating the 341-sprite set  
- Collapsing four audiences into one vague “status update”

## 14. Approval record

| Item | Status |
| --- | --- |
| Program sequence C→D→B→A + thin index | Approved (user) |
| Shared tip-freeze and no-READY rules | Approved (user) |
| Audit C design | Approved (user) |
| Audit D design | Approved (user, “continue as recommended”) |
| Audit B design | Approved (user, “continue as recommended”) |
| Audit A design | Approved (user, “continue as recommended”) |
| Packaging: one program design spec | Approved (user, recommended) |
