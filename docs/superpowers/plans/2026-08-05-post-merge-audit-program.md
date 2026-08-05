# Post-Merge Audit Program (C→D→B→A) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Execute the approved post-merge audit program and produce four tip-honest reports plus a navigation index, without inventing READY or changing product combat rules.

**Architecture:** Sequential evidence program. Shared tip freeze and machine honesty pack, then four independent reports (hygiene → architecture isolation → presentation/art → ship residual). Audit A only summarizes C/D/B. Product code fixes are out of band (separate plans if High findings require them).

**Tech Stack:** git, gh, make validators (`launch-gate-check`, `repo-status-check`, `art-qa-check`, `assets-check`, `weapon-vfx-check`, `animation-check`), ripgrep, markdown reports under `docs/`.

**Spec:** [`docs/superpowers/specs/2026-08-05-post-merge-audit-program-design.md`](../specs/2026-08-05-post-merge-audit-program-design.md)

## Global Constraints

- Sequence is mandatory: **C → D → B → A** (do not write A conclusions before C/D/B reports exist).
- Never invent READY, `ART_SHIP_APPROVED` for HEAD, store clearance, or audio rights clearance.
- Simulation ownership: Core owns combat/collision; presentation/assets never redefine hits.
- Tip freeze at the start of each task: record full + short SHA; dirty tree explained or rejected as ship evidence.
- Findings table columns: Severity | Claim | Evidence | Disposition.
- Every report ends with **Non-claims**.
- Prefer one product tip for the whole program; if tip moves, re-freeze and note which tasks re-ran.
- Do not push, merge, or change launch gates to READY in this plan.
- Small focused commits; do not mix audit reports with unrelated refactors.

## File map

| Path | Responsibility |
| --- | --- |
| `docs/audits/README.md` | Program index: order, shared commands, links to design + four reports |
| `docs/CONTINUATION_REPORT_<DATE>_hygiene_audit.md` | Audit C deliverable |
| `docs/CONTINUATION_REPORT_<DATE>_architecture_isolation_audit.md` | Audit D deliverable |
| `docs/CONTINUATION_REPORT_<DATE>_presentation_art_audit.md` | Audit B deliverable |
| `docs/CONTINUATION_REPORT_<DATE>_ship_residual_audit.md` | Audit A deliverable |
| `docs/REPO_STATUS.md` / `CONTINUATION_PLAN.md` | Only if Task C finds stale claims (optional Task C2) |
| Design (read-only) | `docs/superpowers/specs/2026-08-05-post-merge-audit-program-design.md` |
| Residual authority (read-only) | `docs/launch/TESTFLIGHT_RC_RESIDUAL.md`, `docs/launch/launch_gates.json`, `docs/launch/AGENT_LAUNCH_PLAYBOOK.md` |

**Date token:** Use calendar date of execution as `YYYY-MM-DD` in report filenames (example: `2026-08-05`).

**Shared tip-freeze block** (paste into every report header):

```markdown
**Tip freeze**
- full: `<git rev-parse HEAD>`
- short: `<git rev-parse --short HEAD>`
- branch: `<git branch --show-current>`
- status: `<git status --short | head -20 or "(clean)">`
- frozen_at_utc: `<date -u +%Y-%m-%dT%H:%M:%SZ>`
```

**Shared machine pack** (run and paste exit/summary into reports):

```bash
git fetch origin --prune
git rev-parse HEAD
git rev-parse --short HEAD
git status --short
make version-check
make repo-status-check
make launch-gate-check
make art-qa-check
make assets-check
```

---

### Task 1: Program index

**Files:**
- Create: `docs/audits/README.md`

**Interfaces:**
- Consumes: design spec paths and report filename conventions above
- Produces: navigation entry point for agents executing Tasks 2–5

- [ ] **Step 1: Create `docs/audits/` and write README**

Create `docs/audits/README.md` with exactly these sections (fill tip after freeze in Task 2 if unknown):

```markdown
# Post-merge audit program

**Design:** [`docs/superpowers/specs/2026-08-05-post-merge-audit-program-design.md`](../superpowers/specs/2026-08-05-post-merge-audit-program-design.md)  
**Plan:** [`docs/superpowers/plans/2026-08-05-post-merge-audit-program.md`](../superpowers/plans/2026-08-05-post-merge-audit-program.md)  
**Order:** C hygiene → D architecture → B presentation/art → A ship residual  

## Shared rules

1. Tip-freeze before each audit; dirty tree explained or rejected as ship evidence.
2. Machine gate exit 0 means honest, not READY.
3. Never invent READY, store clearance, or audio rights clearance.
4. Core owns combat truth; presentation projects only.

## Shared machine pack

```bash
git fetch origin --prune
git rev-parse HEAD && git rev-parse --short HEAD
git status --short
make version-check repo-status-check launch-gate-check art-qa-check assets-check
```

## Reports

| Order | Audit | Report |
| ---: | --- | --- |
| 1 | C Hygiene | `docs/CONTINUATION_REPORT_YYYY-MM-DD_hygiene_audit.md` (link when written) |
| 2 | D Architecture | `docs/CONTINUATION_REPORT_YYYY-MM-DD_architecture_isolation_audit.md` |
| 3 | B Presentation/art | `docs/CONTINUATION_REPORT_YYYY-MM-DD_presentation_art_audit.md` |
| 4 | A Ship residual | `docs/CONTINUATION_REPORT_YYYY-MM-DD_ship_residual_audit.md` |

## Residual authority

- [`docs/launch/TESTFLIGHT_RC_RESIDUAL.md`](../launch/TESTFLIGHT_RC_RESIDUAL.md)
- [`docs/launch/launch_gates.json`](../launch/launch_gates.json)
- Board: [`docs/REPO_STATUS.md`](../REPO_STATUS.md)
```

- [ ] **Step 2: Commit index**

```bash
git add docs/audits/README.md
git commit -m "docs(audits): add post-merge audit program index"
```

---

### Task 2: Audit C — Repo / agent hygiene

**Files:**
- Create: `docs/CONTINUATION_REPORT_YYYY-MM-DD_hygiene_audit.md`
- Read: `docs/REPO_STATUS.md`, `docs/CONTINUATION_PLAN.md`, `docs/CONTINUATION_PROMPT.md`
- Optional later: modify boards only in Task 2b if High board lies

**Interfaces:**
- Consumes: shared tip freeze + machine pack
- Produces: C report path linked from `docs/audits/README.md`

- [ ] **Step 1: Tip freeze and machine pack**

Run the shared machine pack. Save outputs to the report (or quote key lines). Record tip freeze block.

- [ ] **Step 2: Collect collaboration truth**

```bash
gh pr list --state open --limit 20
gh issue list --state open --limit 20
git branch -r --merged origin/main | sed 's/^[[:space:]]*//' | grep -v 'origin/main$' | grep -v HEAD || true
git branch -r --no-merged origin/main | sed 's/^[[:space:]]*//' | grep -v HEAD | head -40
git worktree list
git branch -vv | grep ': gone]' | head -40 || true
```

- [ ] **Step 3: Diff board claims**

Manually check each of these against Step 2 output:

1. `docs/REPO_STATUS.md` — **\`main\` tip**, Open PRs table, Worktrees table, Open PRs phase cell  
2. `docs/CONTINUATION_PLAN.md` — Open PRs line, parallel lane claims, board tip  
3. `docs/CONTINUATION_PROMPT.md` — `board_tip`, Open PRs bullets  

For each false claim, add a findings row (Severity High if it implies open work or wrong tip for ship decisions).

- [ ] **Step 4: Write C report**

Create `docs/CONTINUATION_REPORT_YYYY-MM-DD_hygiene_audit.md`:

```markdown
# Hygiene audit — YYYY-MM-DD

**Audit:** C (repo / agent hygiene)  
**Program:** post-merge audit program C→D→B→A  

## Tip freeze
(paste block)

## Machine pack summary
(repo-status-check / launch-gate-check overall / assets-check one-liners)

## Collaboration inventory
### Open PRs
### Open issues
### Merged remotes still present
### Unmerged remotes (sample / count)
### Worktrees
### Local branches with gone upstream (count + sample)

## Board vs truth
| Doc | Claim | Actual | Match? |
| --- | --- | --- | --- |
| REPO_STATUS tip | … | … | Y/N |
| REPO_STATUS open PRs | … | … | Y/N |
| … | … | … | … |

## Findings
| Severity | Claim | Evidence | Disposition |
| --- | --- | --- | --- |

## Recommended actions
1. …
2. …

## Non-claims
- No product READY
- No art quality judgment (Audit B)
- No isolation judgment (Audit D)
- No ship freeze decision (Audit A)
```

- [ ] **Step 5: Link report from index**

Update `docs/audits/README.md` Reports table with the real C filename as a relative link.

- [ ] **Step 6: Commit C**

```bash
git add docs/CONTINUATION_REPORT_*_hygiene_audit.md docs/audits/README.md
git commit -m "docs(audit): C hygiene audit report post-merge"
```

- [ ] **Step 7 (optional Task 2b): Board fix PR content**

Only if C has High board lies. Edit `docs/REPO_STATUS.md`, `docs/CONTINUATION_PLAN.md`, `docs/CONTINUATION_PROMPT.md` to match git/gh. Run `make repo-status-check`. Commit:

```bash
git add docs/REPO_STATUS.md docs/CONTINUATION_PLAN.md docs/CONTINUATION_PROMPT.md
git commit -m "docs: tip-honest boards after hygiene audit C"
```

Do not flip any launch gate READY.

---

### Task 3: Audit D — Architecture / sim-isolation

**Files:**
- Create: `docs/CONTINUATION_REPORT_YYYY-MM-DD_architecture_isolation_audit.md`
- Read: `Game/Presentation/UrbanDressBuilder.swift`, `Sources/SurveillanceCore/DistrictGenerator.swift`, `Game/Rendering/WorldProjector.swift`, `Game/Rendering/OptionalSpriteFrameCycle.swift`, `Game/Scenes/GameScene.swift` (camera scale), tests under `Tests/`

**Interfaces:**
- Consumes: tip freeze (prefer same tip as C)
- Produces: isolation pass/fail + findings for A/B

- [ ] **Step 1: Tip freeze + machine pack**

Re-run tip freeze. If short SHA ≠ C freeze tip, note tip move and re-run machine pack.

- [ ] **Step 2: Ownership inventory**

Document in the report a short table:

| Layer | Paths | Owns | Must not own |
| --- | --- | --- | --- |
| Core | `Sources/SurveillanceCore/**` | sim, AABBs, content | pixels / frames as hits |
| Presentation | `Game/Presentation/**` | UrbanDress from layout | mutating RunState |
| Rendering | `Game/Rendering/**` | sprites, terrain carpet, frame cycles | combat resolution |
| Scenes | `Game/Scenes/**` | input, camera 1.38 | authoritative damage |

- [ ] **Step 3: Anti-pattern search pack**

Run from repo root and capture hit counts (and first 20 lines if any):

```bash
# Physics combat risk
rg -n "SKPhysics|physicsBody|contactTestBitMask|collisionBitMask|SKPhysicsWorld" Game/ App/ --glob '*.swift' || true

# Presentation mutating sim-ish APIs (review every hit manually)
rg -n "RunState|SimulationEngine|applyDamage|hitRadius|projectile" Game/Presentation --glob '*.swift' || true

# Frame/pixel as combat (review)
rg -n "size\.width|texture\.size|frameName|probeLimit" Game/Rendering/EntityProjector.swift Game/Rendering/OptionalSpriteFrameCycle.swift || true

# Dress determinism / RNG
rg -n "Random|rng|arc4random|Float\.random|Double\.random" Game/Presentation --glob '*.swift' || true

# Navigable perimeter / scale (content)
rg -n "navigablePerimeterMargin|1\.5|satelliteCameraScale" Sources/SurveillanceCore Game/ --glob '*.swift' || true
```

For each unexpected hit that implies combat-from-presentation, Severity **High**.

- [ ] **Step 4: Contract reads**

Read and summarize (3–8 lines each) in the report:

1. `DistrictGenerator.generate` — bounds expansion / perimeter  
2. `UrbanDressBuilder.build` — pure from `WorldLayout`  
3. `WorldProjector` ground/roads — presentation-only carpet vs dress  
4. `OptionalSpriteFrameCycle` — presentation frame probe only  
5. Tests that encode contracts:  
   - `Tests/SurveillanceCoreTests/SimulationTests.swift` (wichita/perimeter expectations)  
   - `Tests/SurveillanceSurvivorTests/UrbanDressBuilderTests.swift`  
   - `Tests/SurveillanceSurvivorTests/WorldProjectorUrbanDressTests.swift`

- [ ] **Step 5: Isolation verdict**

Write explicit:

```markdown
## Isolation verdict
- Core owns combat truth: PASS | FAIL
- UrbanDress is pure projection input: PASS | FAIL
- Asset frames do not drive hit timing: PASS | FAIL
```

- [ ] **Step 6: Write D report + link + commit**

Use findings table + non-claims (no art beauty, no ship READY). Update `docs/audits/README.md` link. Commit:

```bash
git add docs/CONTINUATION_REPORT_*_architecture_isolation_audit.md docs/audits/README.md
git commit -m "docs(audit): D architecture isolation audit post-merge"
```

---

### Task 4: Audit B — Presentation / art

**Files:**
- Create: `docs/CONTINUATION_REPORT_YYYY-MM-DD_presentation_art_audit.md`
- Read: `docs/art_qa/art_qa_audit.json`, `docs/ART_DEVICE_QA_CHECKLIST.md` (if present), asset trees under `Resources/`

**Interfaces:**
- Consumes: tip freeze; D isolation PASS expected before treating presentation as “only art”
- Produces: re-attest recommendation for A

- [ ] **Step 1: Tip freeze + asset/art machine pack**

```bash
# shared pack plus:
make weapon-vfx-check
make animation-check
make art-qa-check
# optional if scripts exist:
make sprite-chroma-check 2>/dev/null || true
```

Record counts:

```bash
find Resources/RuntimeSprites -name '*.png' | wc -l
find Resources/Assets.xcassets -name '*.imageset' | wc -l
```

Expect design tip parity **341** unless tip changed (then record actuals).

- [ ] **Step 2: Catalog parity check**

```bash
python3 - <<'PY'
from pathlib import Path
rs = {p.stem for p in Path("Resources/RuntimeSprites").glob("*.png")}
cat = {p.name.replace(".imageset","") for p in Path("Resources/Assets.xcassets").glob("*.imageset")}
print("runtime", len(rs), "catalog", len(cat))
print("only_runtime", sorted(rs-cat)[:30])
print("only_catalog", sorted(cat-rs)[:30])
assert not (rs-cat) and not (cat-rs), "parity broken"
print("parity OK")
PY
```

If assertion fails: Severity High finding; do not claim assets integrated.

- [ ] **Step 3: Operator checklist table**

In the B report, include:

| Item | Device | Simulator | Result | Notes |
| --- | --- | --- | --- | --- |
| Player readable at combat range | | | pass/fail/not_run/blocked_no_device | |
| Guards/boss distinct | | | | |
| LPR cones / suspicion readable | | | | |
| Projectiles / VFX multi-frame visible | | | | |
| Blind Spot extract readable | | | | |
| UrbanDress streets/buildings legible | | | | |
| Satellite zoom 1.38 combat OK | | | | |
| Terrain carpet not featureless / not noisy | | | | |
| Pale ground entity contrast | | | | |
| Flash safety (telegraph/pulse) | | | | |
| Reduced-motion / reduced-flash coverage gaps | | | | |

City sample: full 10 **or** documented subset (list IDs).

If no device: mark device column `blocked_no_device`; simulator results weaker.

- [ ] **Step 4: Stale ART approval check**

Compare `docs/art_qa/art_qa_audit.json` (and REPO_STATUS ship_gate language) approval tip to freeze tip.

```markdown
## ART approval tip match
- prior ship_gate: ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES (operator 2026-08-01)
- approval tip vs freeze tip: MATCH | STALE
- recommendation: re-attest on HEAD before residual art_ship READY
```

- [ ] **Step 5: B verdict**

```markdown
## Presentation/art verdict
- Machine assets: PASS | FAIL
- Ready for operator ART re-attest on freeze tip: YES | NO (if NO, list code/art defects)
```

- [ ] **Step 6: Write B report + link + commit**

```bash
git add docs/CONTINUATION_REPORT_*_presentation_art_audit.md docs/audits/README.md
git commit -m "docs(audit): B presentation and art audit post-merge"
```

---

### Task 5: Audit A — Ship residual scoreboard

**Files:**
- Create: `docs/CONTINUATION_REPORT_YYYY-MM-DD_ship_residual_audit.md`
- Read: C/D/B reports, `docs/launch/TESTFLIGHT_RC_RESIDUAL.md`, `docs/launch/launch_gates.json`, `docs/REPO_STATUS.md`

**Interfaces:**
- Consumes: C, D, B reports (must exist)
- Produces: owner-facing go/no-go list L

- [ ] **Step 1: Tip freeze + launch honesty**

```bash
make launch-gate-check
make repo-status-check
make art-qa-check
```

Paste machine gate table into A report.

- [ ] **Step 2: Import prior audits**

Summarize each in ≤5 bullets:

- C: board honesty / remotes / worktrees  
- D: isolation verdict  
- B: machine assets + re-attest recommendation  

- [ ] **Step 3: Gate scoreboard**

Fill completely (no blank owners):

| Gate | Machine status | Tip / note | Blocker | Owner |
| --- | --- | --- | --- | --- |
| device_acceptance | | | | Operator/agent residual |
| art_ship | | | | Operator re-attest + residual |
| store_metadata | | | | Owner |
| audio_product | | | | Owner rights + listening |
| testflight_rc | | | | Shared after priors READY |
| **Overall** | LAUNCH_BLOCKED (expected) | freeze tip | residual list L | Shared |

- [ ] **Step 4: Evidence vs HEAD**

| Evidence | Tip | Valid for HEAD freeze? |
| --- | --- | --- |
| Mechanical suite | e.g. f2406fc | yes/no + why |
| Live Louisville extract | | |
| Live Tulsa extract | | |
| Urban device-smoke notes | | |
| Sim store screenshots | | |
| Audio rights ledger | scaffold only | no until verified |

- [ ] **Step 5: Ordered next actions + go/no-go**

```markdown
## Go / no-go
- Freeze ship SHA at HEAD now?: NO | YES (only if residual criteria met — default NO)
- RC cut allowed?: only when all gates READY (not claimed)
- Upload?: never claimed by this audit

## List L — blockers before residual freeze READY path
1. …
2. …

## Ordered next
1. Operator: …
2. Owner: …
3. Agent: only after artifacts; never invent READY
```

- [ ] **Step 6: Non-claims + write + commit**

Include: RC cut ≠ upload; scaffold ≠ rights PASS; pre-merge ART approval ≠ tip-matched HEAD.

```bash
git add docs/CONTINUATION_REPORT_*_ship_residual_audit.md docs/audits/README.md
git commit -m "docs(audit): A ship residual audit post-merge"
```

- [ ] **Step 7: Final program verification**

```bash
test -f docs/audits/README.md
ls docs/CONTINUATION_REPORT_*_hygiene_audit.md
ls docs/CONTINUATION_REPORT_*_architecture_isolation_audit.md
ls docs/CONTINUATION_REPORT_*_presentation_art_audit.md
ls docs/CONTINUATION_REPORT_*_ship_residual_audit.md
make repo-status-check
make launch-gate-check
```

Expected: four reports present; launch overall still **LAUNCH_BLOCKED** unless residual truly changed (it should not from docs-only audits).

---

## Spec coverage checklist (plan self-review)

| Spec section | Task |
| --- | --- |
| Program sequence C→D→B→A | Tasks 2–5 order |
| Shared tip freeze + machine pack | Global + each task Step 1 |
| Index `docs/audits/README.md` | Task 1 |
| Audit C method/deliverable | Task 2 |
| Audit D anti-patterns + verdict | Task 3 |
| Audit B assets + checklist + stale ART | Task 4 |
| Audit A scoreboard + list L | Task 5 |
| No READY invention | Global Constraints + each Non-claims |
| Fixes out of band | Global Constraints; Task 2b boards only |

**Placeholder scan:** none intentional.  
**Type consistency:** N/A (docs program). Report filename date token is the only variable; use real `YYYY-MM-DD` at execution.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-05-post-merge-audit-program.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — this session, executing-plans style with checkpoints  

Which approach?
