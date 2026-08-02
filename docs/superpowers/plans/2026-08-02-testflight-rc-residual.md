# TestFlight RC Residual Closeout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the residual closeout playbook so humans can freeze a ship SHA and finish store/audio/device/ART residuals until `testflight_rc` may honestly become READY (RC cut **allowed**, not uploaded).

**Architecture:** Docs-only extension of the existing launch-gate machine. One new operator residual guide (`TESTFLIGHT_RC_RESIDUAL.md`) is the human entry for freeze + checklists. Agent playbook, operator packet, store/audio/device worksheets, and board docs gain freeze rules and residual READY criteria. No new gate IDs, no `ship_freeze.json`, no Swift, no READY flips without human evidence.

**Tech Stack:** Markdown docs, existing Make honesty targets (`launch-gate-check`, `release-docs-check`, `repo-status-check`, `audio-rights-check`), git.

**Spec:** [`docs/superpowers/specs/2026-08-02-testflight-rc-residual-design.md`](../specs/2026-08-02-testflight-rc-residual-design.md)

## Global Constraints

- Do **not** invent device receipts, store URLs, copyright confirmation, screenshot accept, rights clearance, or listening pass.
- Do **not** set any gate `READY` or overall `LAUNCH_READY` unless human evidence already satisfies the design criteria and `make launch-gate-check` would PASS.
- Checker **PASS** ≠ ship-ready. Honest `LAUNCH_BLOCKED` must remain acceptable.
- No product/game Swift code changes in this plan.
- No `ship_freeze.json`; freeze lives in `DEVICE_TEST_LOG.md` only.
- Prefer small focused commits per task.
- Repo root: worktree in use (e.g. `/Users/appliedalchemylabs/Documents/Surveillance-Survivor`).

## File map

| Path | Responsibility |
| --- | --- |
| `docs/launch/TESTFLIGHT_RC_RESIDUAL.md` | **Create** — human residual closeout (freeze, checklists, RC-allowed meaning) |
| `docs/DEVICE_TEST_LOG.md` | **Modify** — Ship freeze + Listening (freeze tip) templates |
| `docs/launch/AGENT_LAUNCH_PLAYBOOK.md` | **Modify** — freeze-required residual promote rules |
| `docs/LAUNCH_OPERATOR_PACKET.md` | **Modify** — point residual at freeze + residual doc |
| `docs/APP_STORE_METADATA.md` | **Modify** — copyright + screenshot accept residual language (RC vs submit) |
| `docs/STORE_OWNER_INTAKE.md` | **Modify** — residual checkboxes aligned with design §3.1 |
| `docs/audio/rights/OWNER_EVIDENCE_PACKET.md` | **Modify** — freeze-tip listening cross-link |
| `docs/CONTINUATION_PLAN.md` | **Modify** — residual path authority |
| `docs/REPO_STATUS.md` | **Modify** — board points at residual doc |
| `docs/launch/launch_gates.json` | **Do not promote READY** in this plan; optional reason pointer only if needed |

---

### Task 1: Create residual closeout guide

**Files:**
- Create: `docs/launch/TESTFLIGHT_RC_RESIDUAL.md`

**Interfaces:**
- Produces: single human entry for freeze ritual + residual checklists A–E from design §2–§3
- Consumes: design spec; existing gate IDs and paths

- [ ] **Step 1: Confirm design tip and open files**

```bash
cd "$(git rev-parse --show-toplevel)"
git rev-parse --short HEAD
test -f docs/superpowers/specs/2026-08-02-testflight-rc-residual-design.md
ls docs/launch/AGENT_LAUNCH_PLAYBOOK.md docs/LAUNCH_OPERATOR_PACKET.md
```

Expected: short SHA printed; design and launch docs exist.

- [ ] **Step 2: Write `docs/launch/TESTFLIGHT_RC_RESIDUAL.md`**

Create the file with this structure and content (adapt only if paths moved; do not invent READY status):

```markdown
# TestFlight RC residual closeout

**Purpose:** Last human/agent steps from honest `LAUNCH_BLOCKED` to **RC cut allowed**.  
**Design:** [`docs/superpowers/specs/2026-08-02-testflight-rc-residual-design.md`](../superpowers/specs/2026-08-02-testflight-rc-residual-design.md)  
**Machine truth:** [`launch_gates.json`](launch_gates.json) · [`AGENT_LAUNCH_PLAYBOOK.md`](AGENT_LAUNCH_PLAYBOOK.md)  
**Does not mean:** App Store Connect upload, TF group assignment, or public submit.

## Success

When `device_acceptance`, `art_ship`, `store_metadata`, and `audio_product` are all `READY` at the frozen tip, agents may set `testflight_rc` to `READY`. Overall may become `LAUNCH_READY`. That only means humans **may cut** an RC — not that one was uploaded.

## 0. Freeze ship SHA (required first)

Record a **Ship freeze** block in [`DEVICE_TEST_LOG.md`](../DEVICE_TEST_LOG.md) using the template there:

- full SHA + short SHA
- UTC time
- app version / build
- intent label (e.g. `tf-rc-0.1.0-b1`)
- `git status --short` (prefer empty)

Rules:

- Every READY gate `tip_sha_short` must equal freeze short SHA and current `git rev-parse --short HEAD`.
- Any later commit breaks freeze — re-freeze before promoting again.
- Agents never invent a freeze block.

## Residual order

```text
Freeze
  ├─ Owner: store residual → store_metadata READY
  ├─ Owner: audio rights + listening → audio_product READY
  └─ Operator: device_acceptance READY → art_ship READY
Shared: testflight_rc READY only when all four priors READY
Human: cut RC (outside this doc)
```

Store and audio may run in parallel. `art_ship` waits on `device_acceptance`.

## A. Store residual (`store_metadata`)

Already done: live privacy/support URLs, SKU `SS-IOS-001`, Action subcategory, sim screenshot pack.

Still required:

1. Confirm copyright string in [`APP_STORE_METADATA.md`](../APP_STORE_METADATA.md) / [`STORE_OWNER_INTAKE.md`](../STORE_OWNER_INTAKE.md).
2. Accept sim candidates in [`store_screenshots/`](../store_screenshots/) **or** recapture physical/release stills at freeze tip and update manifest.

Does **not** block RC-allowed: age rating in Connect, ASC privacy questionnaire (public submit items).

Then agent may promote `store_metadata` READY with evidence paths to those docs + screenshot manifest.

## B. Audio residual (`audio_product`)

1. File private evidence per [`audio/rights/OWNER_EVIDENCE_PACKET.md`](../audio/rights/OWNER_EVIDENCE_PACKET.md) until `make audio-rights-check` **PASS**.
2. On freeze tip, complete **Listening (freeze tip)** in `DEVICE_TEST_LOG.md` (speaker, headphones/second route, silent mode, interruption, route change, dense mix).

Scaffold `pending_evidence` is **not** clearance. Agents never invent digests or `cleared`.

## C. Device tip-match (`device_acceptance`)

On freeze tip:

| Binary/presentation since last full suite + live extract | Required |
| --- | --- |
| Unchanged | Attest in log; run `device-smoke` + physical `launch-smoke`; cite prior extract |
| Changed | Full suite + one live extract on freeze tip |
| Docs-only | Smoke + physical launch-smoke; cite prior extract with freeze attestation |

Not READY from smoke or force-extract alone.

## D. ART tip-match (`art_ship`)

Requires `device_acceptance` READY.

- No visual/binary change since ART approval: re-attest ART still holds at freeze tip.
- Visual/binary change: re-run ART checklist eyes; update art_qa + log.

Nonblocking notes do not block READY if approved-with-notes and re-attested.

## E. RC allowed (`testflight_rc`)

All four priors READY at freeze tip. Reason: `RC cut allowed at <shortsha>; not uploaded`.

## Demotion

If HEAD short SHA moves after READY: demote all READY gates to `EVIDENCE_INSUFFICIENT`, reason tip moved / re-freeze.

## Validate

```bash
make launch-gate-check release-docs-check repo-status-check
make audio-rights-check   # PASS only after owner clearance
```
```

- [ ] **Step 3: Verify file is non-empty and linked design path resolves**

```bash
test -s docs/launch/TESTFLIGHT_RC_RESIDUAL.md
test -f docs/superpowers/specs/2026-08-02-testflight-rc-residual-design.md
rg -n "Ship freeze|store_metadata|audio_product|testflight_rc|not uploaded" docs/launch/TESTFLIGHT_RC_RESIDUAL.md
```

Expected: matches for freeze and all residual gate names; “not uploaded” present.

- [ ] **Step 4: Commit**

```bash
git add docs/launch/TESTFLIGHT_RC_RESIDUAL.md
git commit -m "docs: add TestFlight RC residual closeout guide"
```

---

### Task 2: Device log freeze + listening templates

**Files:**
- Modify: `docs/DEVICE_TEST_LOG.md`

**Interfaces:**
- Produces: empty templates operators paste into when freezing / listening
- Consumes: residual guide section 0 and B

- [ ] **Step 1: Insert Ship freeze template after the intro pin block (before `## Run identity`)**

After the paragraph ending with “rejected as release evidence.” and before `## Run identity`, insert:

```markdown
## Ship freeze (RC residual)

Use once per intended TestFlight RC tip. Required before any launch gate is promoted READY for that RC. See [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md).

```text
intent label (e.g. tf-rc-0.1.0-b1):
freeze date/time UTC:
full commit SHA:
short SHA:
app version / build:
git status --short:
freezer (operator/owner):
binary/presentation change since last full device suite + live extract: yes / no / unknown
notes:
```
```

- [ ] **Step 2: Insert Listening (freeze tip) template under Deployment evidence (top of that section)**

Immediately after the heading `## Deployment evidence`, insert:

```markdown
### Listening (freeze tip) — required for `audio_product` READY

Complete on the **frozen** short SHA. Simulator is not enough.

```text
freeze short SHA:
date and local time:
device model / iOS:
reviewer:
speaker balance usable: pass / fail
headphones or second route usable: pass / fail
silent mode behavior acceptable: pass / fail
interruption recovery (e.g. phone call / Siri) acceptable: pass / fail
route change recovery acceptable: pass / fail
dense-combat mix / clipping acceptable: pass / fail
mute + bus levels still work: pass / fail / n/a
notes:
```
```

- [ ] **Step 3: Confirm templates exist without inventing pass results**

```bash
rg -n "Ship freeze|Listening \(freeze tip\)" docs/DEVICE_TEST_LOG.md
rg -n "pass / fail" docs/DEVICE_TEST_LOG.md | head -20
```

Expected: templates present; no new filled “pass” claims for a freeze tip.

- [ ] **Step 4: Commit**

```bash
git add docs/DEVICE_TEST_LOG.md
git commit -m "docs: add ship freeze and freeze-tip listening templates"
```

---

### Task 3: Agent launch playbook residual rules

**Files:**
- Modify: `docs/launch/AGENT_LAUNCH_PLAYBOOK.md`

**Interfaces:**
- Produces: agent-facing freeze + residual READY rules
- Consumes: residual guide; design §3

- [ ] **Step 1: Add residual section after section 4 (May / must not) or as new section before “After tip moves”**

Insert a new section titled `## 4b. Residual closeout (TestFlight RC cut allowed)` with:

```markdown
## 4b. Residual closeout (TestFlight RC cut allowed)

**Human guide:** [`TESTFLIGHT_RC_RESIDUAL.md`](TESTFLIGHT_RC_RESIDUAL.md)  
**Design:** [`docs/superpowers/specs/2026-08-02-testflight-rc-residual-design.md`](../superpowers/specs/2026-08-02-testflight-rc-residual-design.md)

### Freeze required

Before promoting **any** gate to `READY` for an RC cut:

1. Confirm a **Ship freeze** block exists in `docs/DEVICE_TEST_LOG.md` for the current short SHA.
2. Confirm `git rev-parse --short HEAD` equals that freeze short SHA.
3. If missing or mismatched: do not promote; ask operator to freeze.

### Residual READY (summary — full criteria in residual guide)

| Gate | Promote READY only when |
| --- | --- |
| `store_metadata` | Live URLs + SKU/Action already true; **and** copyright confirmed; **and** owner accepted sim screenshots **or** tip-matched physical pack; age/ASC privacy do **not** block RC-allowed |
| `audio_product` | `make audio-rights-check` PASS **and** freeze-tip listening template filled pass/fail in device log |
| `device_acceptance` | Freeze tip + re-work table in residual guide (smoke+launch-smoke minimum; full suite+live extract if binary moved) |
| `art_ship` | `device_acceptance` READY; ART re-attest or re-eyes per residual guide; art-qa honesty holds |
| `testflight_rc` | All four priors READY; reason states RC cut allowed / not uploaded |

### Agents must not (residual)

- Invent freeze blocks, copyright confirm, screenshot accept, rights digests, listening passes.
- Promote `audio_product` from ledger scaffold alone.
- Promote `testflight_rc` to mean “uploaded to TestFlight.”
```

Also add to section 3 evidence table for `store_metadata` / `testflight_rc` a pointer:

- `store_metadata` surface: add “residual: [`TESTFLIGHT_RC_RESIDUAL.md`](TESTFLIGHT_RC_RESIDUAL.md) §A”
- `audio_product` surface: add “residual: §B + freeze-tip listening”
- `testflight_rc` surface: add “residual: [`TESTFLIGHT_RC_RESIDUAL.md`](TESTFLIGHT_RC_RESIDUAL.md)”

- [ ] **Step 2: Grep for residual keywords**

```bash
rg -n "4b. Residual|Freeze required|not uploaded|TESTFLIGHT_RC_RESIDUAL" docs/launch/AGENT_LAUNCH_PLAYBOOK.md
```

Expected: residual section and freeze rules present.

- [ ] **Step 3: Honesty check still passes**

```bash
make launch-gate-check
```

Expected: `PASS` with `overall=LAUNCH_BLOCKED` (or current honest overall); no READY invented.

- [ ] **Step 4: Commit**

```bash
git add docs/launch/AGENT_LAUNCH_PLAYBOOK.md
git commit -m "docs: agent playbook residual freeze and READY rules"
```

---

### Task 4: Operator packet + store + audio packet links

**Files:**
- Modify: `docs/LAUNCH_OPERATOR_PACKET.md`
- Modify: `docs/APP_STORE_METADATA.md`
- Modify: `docs/STORE_OWNER_INTAKE.md`
- Modify: `docs/audio/rights/OWNER_EVIDENCE_PACKET.md`

**Interfaces:**
- Produces: single path for humans from packet → residual guide; store residual checkboxes; audio freeze-tip listening note
- Consumes: Task 1 residual guide

- [ ] **Step 1: Update `LAUNCH_OPERATOR_PACKET.md` header “Next human residual”**

Replace residual one-liner with:

```markdown
**Next human residual:** freeze ship SHA + residual closeout — [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md) (store copyright/screenshot accept, audio rights+listening, tip-match device/ART). RC cut allowed only when gates READY — not upload.
```

In **Ordered steps**, before or as rewrite of steps 3–5, add a step 0b after pin:

```markdown
### 0b. Freeze ship SHA (RC residual)

When preparing a TestFlight RC, complete **Ship freeze** in [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) and follow [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md). Do not promote launch gates READY without that freeze.
```

In step 3 Store, add bullets:

```markdown
- Confirm copyright string (or write legal string)
- Accept sim screenshots for Connect prep **or** recapture on freeze tip
- Age rating / ASC privacy: required for public submit; **not** required for `store_metadata` READY for RC-allowed (see residual design)
```

In step 4 Audio, add:

```markdown
- After rights PASS: complete freeze-tip listening template in DEVICE_TEST_LOG
```

In step 5 TestFlight, state:

```markdown
Only after residual closeout makes all priors READY. `testflight_rc` READY = cut allowed, not uploaded. See residual guide.
```

- [ ] **Step 2: Update store intake residual checkboxes**

In `docs/STORE_OWNER_INTAKE.md`, replace “Still open” / gate posture with explicit residual rows:

```markdown
## Residual for `store_metadata` READY (RC cut allowed)

| Field | Status | Notes |
| --- | --- | --- |
| Copyright | **OPEN** until owner confirms | Proposed `© 2026 Zero State LLC` |
| Screenshot accept | **OPEN** until owner accepts sim pack or recaptures | Pack: `docs/store_screenshots/` |
| Age rating (Connect) | Open for public submit | **Does not block** RC-allowed gate |
| ASC privacy labels | Open for public submit | **Does not block** RC-allowed gate |

Owner accept line (fill when true):

```text
copyright confirmed (string):
screenshots accepted for RC listing prep: sim pack / physical pack / not yet
date:
```
```

In `docs/APP_STORE_METADATA.md` status summary / listing assets, align wording:

- Keep required marker string: `Truthful iPhone screenshots from release build` (release-docs-check).
- Add residual note: for **RC cut allowed**, owner may accept sim candidates **or** physical pack; public Connect may still prefer physical Release stills.

- [ ] **Step 3: Update `OWNER_EVIDENCE_PACKET.md` Validate section**

After the `make audio-rights-check` block, append:

```markdown
## Freeze-tip listening (launch residual)

Rights PASS alone does **not** make `audio_product` READY. After rights PASS, complete **Listening (freeze tip)** in [`docs/DEVICE_TEST_LOG.md`](../../DEVICE_TEST_LOG.md) on the frozen ship SHA. Residual path: [`docs/launch/TESTFLIGHT_RC_RESIDUAL.md`](../../launch/TESTFLIGHT_RC_RESIDUAL.md) §B.
```

- [ ] **Step 4: Validate release docs + launch gates**

```bash
make release-docs-check launch-gate-check
```

Expected: both PASS (honest blocked OK). If `release-docs-check` fails on missing marker `Truthful iPhone screenshots from release build`, restore that exact phrase in `APP_STORE_METADATA.md`.

- [ ] **Step 5: Commit**

```bash
git add docs/LAUNCH_OPERATOR_PACKET.md docs/APP_STORE_METADATA.md docs/STORE_OWNER_INTAKE.md docs/audio/rights/OWNER_EVIDENCE_PACKET.md
git commit -m "docs: wire operator packet, store residual, audio listening to RC guide"
```

---

### Task 5: Board + continuation plan hygiene

**Files:**
- Modify: `docs/CONTINUATION_PLAN.md`
- Modify: `docs/REPO_STATUS.md`

**Interfaces:**
- Produces: boards cite residual guide as primary next path
- Consumes: Task 1 path

- [ ] **Step 1: Update `CONTINUATION_PLAN.md`**

In authority map, add row after launch gates:

```markdown
| 1d | [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md) | Residual freeze + RC cut allowed path |
```

In recommended next, lead with residual closeout:

```markdown
### 1. Owner/operator — TestFlight RC residual (primary)

Follow [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md): freeze ship SHA, then store residual, audio rights+listening, tip-match device/ART. Promote gates only per residual criteria. RC cut allowed ≠ upload.
```

In paste prompt block at bottom, replace open line with residual path mention.

- [ ] **Step 2: Update `REPO_STATUS.md`**

In Suggested next:

```markdown
1. **Owner/operator:** freeze ship SHA + residual closeout ([`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md))
2. **Owner:** audio rights packet + freeze-tip listening; copyright + screenshot accept
3. **Agent:** promote READY only after freeze + evidence; never invent clearance
```

In Latest increments, one bullet: residual closeout guide landed (design + playbook).

Keep `**\`main\` tip:**` pattern valid (existing SHA ancestor of HEAD). Do **not** claim LAUNCH_READY.

- [ ] **Step 3: Board honesty checks**

```bash
make launch-gate-check repo-status-check release-docs-check
```

Expected: all PASS; overall still `LAUNCH_BLOCKED` unless human evidence already cleared gates (do not invent).

- [ ] **Step 4: Commit**

```bash
git add docs/CONTINUATION_PLAN.md docs/REPO_STATUS.md
git commit -m "docs: point board and continuation plan at RC residual path"
```

---

### Task 6: Final residual walkthrough (no READY invention)

**Files:**
- Read-only verification; optional reason-only edit to `docs/launch/launch_gates.json` if a pointer to residual doc is desired (must remain non-READY)

**Interfaces:**
- Produces: verification that design coverage is linked end-to-end

- [ ] **Step 1: End-to-end link check**

```bash
cd "$(git rev-parse --show-toplevel)"
for p in \
  docs/launch/TESTFLIGHT_RC_RESIDUAL.md \
  docs/superpowers/specs/2026-08-02-testflight-rc-residual-design.md \
  docs/launch/AGENT_LAUNCH_PLAYBOOK.md \
  docs/LAUNCH_OPERATOR_PACKET.md \
  docs/DEVICE_TEST_LOG.md \
  docs/STORE_OWNER_INTAKE.md \
  docs/audio/rights/OWNER_EVIDENCE_PACKET.md \
  docs/CONTINUATION_PLAN.md \
  docs/REPO_STATUS.md
 do test -f "$p" && echo "ok $p" || echo "MISSING $p"
done
rg -n "TESTFLIGHT_RC_RESIDUAL" docs/LAUNCH_OPERATOR_PACKET.md docs/launch/AGENT_LAUNCH_PLAYBOOK.md docs/CONTINUATION_PLAN.md docs/REPO_STATUS.md
```

Expected: all files ok; residual guide cited from packet, playbook, continuation, board.

- [ ] **Step 2: Design coverage grep**

```bash
rg -n "Ship freeze|copyright|screenshot accept|audio-rights-check|Listening \(freeze tip\)|not uploaded|tip moved" \
  docs/launch/TESTFLIGHT_RC_RESIDUAL.md \
  docs/launch/AGENT_LAUNCH_PLAYBOOK.md \
  docs/DEVICE_TEST_LOG.md
```

Expected: freeze, store residual, rights, listening, not uploaded, demotion language present across residual surfaces.

- [ ] **Step 3: Full honesty suite for residual docs**

```bash
make launch-gate-check release-docs-check repo-status-check
# Expect audio-rights still blocked until owner:
make audio-rights-check; test $? -ne 0 && echo "audio-rights still BLOCKED (expected)"
```

Expected: three PASS; audio-rights still non-zero unless owner already cleared.

- [ ] **Step 4: Confirm no gate wrongly READY**

```bash
python3 - <<'PY'
import json
from pathlib import Path
g=json.loads(Path("docs/launch/launch_gates.json").read_text())["gates"]
ready=[k for k,v in g.items() if v.get("status")=="READY"]
print("READY gates:", ready or "(none)")
assert not ready or True  # informational; only fail if unexpected without freeze
# This plan must not have introduced READY without freeze:
# if any READY, print warning for human review
if ready:
    print("WARNING: READY gates present — human must confirm freeze+evidence")
PY
```

- [ ] **Step 5: Final commit only if any leftover hygiene edits**

```bash
git status --short
# If dirty only with intentional residual pointer tweaks:
# git add … && git commit -m "docs: residual closeout hygiene pass"
# If clean: done
```

---

## Spec coverage checklist (plan self-review)

| Spec requirement | Task |
| --- | --- |
| Ship freeze ritual in device log | Task 2 |
| Residual order A–E | Task 1 |
| store READY criteria (copyright + screenshot accept; age not blocking RC) | Tasks 1, 4 |
| audio READY (rights PASS + freeze-tip listening) | Tasks 1, 2, 4 |
| device_acceptance re-work table | Task 1 |
| art_ship re-attest rules | Task 1 |
| testflight_rc = cut allowed not uploaded | Tasks 1, 3, 4 |
| Demotion on tip move | Tasks 1, 3 |
| Agent playbook residual rules | Task 3 |
| Operator packet wiring | Task 4 |
| Board / continuation | Task 5 |
| No READY invention / no ship_freeze.json / no Swift | Global constraints + Task 6 |
| Design implementation success ≠ LAUNCH_READY | Global constraints + Task 6 |

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-02-testflight-rc-residual.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — execute tasks in this session with checkpoints  

Which approach?
