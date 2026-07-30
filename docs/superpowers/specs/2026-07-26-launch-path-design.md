# Launch path design — machine-honest operator gates

> **Historical design snapshot (2026-07-26).** Audio-production examples below describe the pre-integration gate model. Current reality is 68/68 assets integrated; `audio_product` remains blocked on rights confirmation and physical-device listening/routing/interruption/mix evidence. See `docs/AUDIO_PLAN.md` and `docs/LAUNCH_OPERATOR_PACKET.md`.

**Date:** 2026-07-26  
**Product:** Surveillance Survivor  
**Status:** Design approved (brainstorm); implementation not started  
**Approach:** Gate manifest + `make launch-gate-check` (automation-first)

---

## 1. Purpose and non-goals

### Purpose

A machine-checkable **launch gate system** that agents treat as source of truth for “are we ship-blocked, and on what?” Humans fill evidence; agents never invent green.

Primary reader: **agents and board hygiene**. Humans fill evidence slots agents prepare and enforce.

Success definition: **honest blocked state**. Running the checker always yields a true status—either correctly blocked with named human owners, or green only when required evidence fields are present and tip-aligned. Never fake pass.

### In scope

- Gate schema (`docs/launch/launch_gates.json`)
- `make launch-gate-check` honesty rules (`scripts/validate_launch_gates.py`)
- Thin agent-facing playbook that points at existing operator docs
- Light hooks: `REPO_STATUS` / continue-ss read gates; never override without evidence
- Seeded honest-blocked initial content
- Validator self-tests (fixtures)

### Out of scope

- Product / game code changes
- Inventing device logs, store URLs, ElevenLabs stems, or `ART_SHIP_APPROVED` without tip-matched paths
- Replacing `DEVICE_TEST_LOG` / ART checklist / store worksheet content wholesale
- Full TestFlight upload automation
- Requiring `LAUNCH_READY` for CI merge (would redline every PR while humans are blocked)

### Success for *this* work (not the game ship)

Design + plan implemented when: `make launch-gate-check` is green on the tree with overall **`LAUNCH_BLOCKED`**, agents have a playbook, and boards cite the machine file—**not** when the game ships to TestFlight.

---

## 2. Context and constraints

Existing authority (keep; do not replace):

| Doc | Role |
| --- | --- |
| [`docs/LAUNCH_OPERATOR_PACKET.md`](../../LAUNCH_OPERATOR_PACKET.md) | Ordered **human** steps |
| [`docs/RELEASE_READINESS.md`](../../RELEASE_READINESS.md) | Full evidence matrix |
| [`docs/DEVICE_TEST_LOG.md`](../../DEVICE_TEST_LOG.md) | Physical observations + receipt JSON |
| [`docs/ART_DEVICE_QA_CHECKLIST.md`](../../ART_DEVICE_QA_CHECKLIST.md) | Device ART readability |
| [`docs/art_qa/art_qa_audit.json`](../../art_qa/art_qa_audit.json) | ART `ship_gate` + `make art-qa-check` |
| [`docs/APP_STORE_METADATA.md`](../../APP_STORE_METADATA.md) | Store OWNER fields |
| [`scripts/validate_art_qa_package.py`](../../../scripts/validate_art_qa_package.py) | ART honesty pattern to mirror |

Known product honesty rule: `ART_EVIDENCE_INSUFFICIENT` until tip-matched device evidence. Launch gates must stay consistent with that rule.

---

## 3. Gate model and states

### 3.1 Machine file

**Path:** `docs/launch/launch_gates.json`  
**Role:** Single source of machine truth for launch blockers.

### 3.2 Gates (ordered)

| ID | Owner | Meaning |
| --- | --- | --- |
| `device_acceptance` | operator | Tip-matched full device pass + extract receipt |
| `art_ship` | operator (+ owner on GitHub #3) | Device ART checklist; ART ship flip only with evidence |
| `store_metadata` | owner | Live privacy/support URLs, SKU fields, screenshot plan filled |
| `audio_product` | owner | License + Batch 1 product stems (never system sounds) |
| `testflight_rc` | shared | RC cut **allowed** only when all priors are `READY` (not “uploaded”) |

### 3.3 Per-gate fields

| Field | Type | Notes |
| --- | --- | --- |
| `status` | enum | `BLOCKED` \| `EVIDENCE_INSUFFICIENT` \| `READY` \| `N_A` |
| `tip_sha_short` | string \| null | Tip this evidence applies to; required when `READY` |
| `evidence_paths` | string[] | Repo-relative paths; required non-empty when `READY` |
| `reason` | string | Human-readable why not ready (or attestation note) |
| `owner` | enum | `operator` \| `owner` \| `shared` |
| `depends_on` | string[] | Gate IDs that must be `READY` first |

**`N_A`:** Allowed in schema for intentional product skip; **unused at seed**.

### 3.4 Dependencies

- `art_ship` depends on `device_acceptance`
- `testflight_rc` depends on `device_acceptance`, `art_ship`, `store_metadata`, `audio_product`
- `store_metadata` and `audio_product` have no gate dependencies (owner track; may proceed in parallel with device work for worksheet fill-out, but RC still waits)

### 3.5 Honesty rules

1. **`READY` requires** non-empty `evidence_paths`, every path exists on disk, and `tip_sha_short` equals the **current checkout** short SHA (`git rev-parse --short HEAD`). **No automatic tip lag.**
2. **`art_ship` → `READY`** is only honest if existing ART package rules would allow approval: non-empty device evidence paths exist, and agents must not set `art_qa_audit.json` `ship_gate` to `ART_SHIP_APPROVED` without satisfying `make art-qa-check`. Launch checker treats ART flip rules as **owned by art-qa-check**; launch file must not claim `art_ship` READY in a way that contradicts ART insufficient/approved honesty (`ART_INCONSISTENT` if it does).
3. Agents may set status **down** freely (e.g. tip moved → demote to `EVIDENCE_INSUFFICIENT`). Agents may set **up** to `READY` only when the checker would pass.
4. **Stale tip:** if any gate is `READY` for a short SHA that is not the current checkout tip → checker **fails** with `STALE_TIP` until demoted or re-evidenced. Prefer agent demote over silent green.
5. **Docs-only tip lag exception:** pure-docs commits may keep prior device evidence **only if an operator explicitly re-attests** in the device log. Agents **do not** invent that exception; default is demote.

### 3.6 Derived overall status

Not free-form in the JSON as an agent-editable lie surface; either stored as derived field refreshed by agents after check, or computed only by the checker stdout.

| Overall | When |
| --- | --- |
| `LAUNCH_BLOCKED` | Any required gate is not `READY` |
| `LAUNCH_READY` | All required gates `READY` and tip-aligned |

Checker **exit 0** means the file is **honest**, not that launch is ready.  
`LAUNCH_BLOCKED` + honest schema = **PASS**.  
Lying or malformed = **FAIL**.

---

## 4. Checker, make target, agent surface

### 4.1 Machine checker

| Piece | Spec |
| --- | --- |
| Script | `scripts/validate_launch_gates.py` |
| Make | `make launch-gate-check` |
| Input | `docs/launch/launch_gates.json` |
| Pattern | Mirror `scripts/validate_art_qa_package.py` |

**Exit 0:** Schema valid and honesty rules hold (including overall `LAUNCH_BLOCKED`).  
**Exit 1:** Schema break, missing paths, `READY` without evidence, stale tip on any `READY` gate, dependency violation, or `art_ship` claims READY while ART honesty would fail.

**Stdout:** Always print derived overall (`LAUNCH_BLOCKED` / `LAUNCH_READY`) plus per-gate one-liners.

**Tip resolution:** Current checkout short SHA via `git rev-parse --short HEAD` (worktree-safe). Do not require remote `main` unless an agent is explicitly claiming main-only readiness in a separate policy (v1: checkout tip only).

**ART coupling:** For `art_ship`, enforce consistency with art-qa package (subprocess to existing validator and/or shared path checks). Do not duplicate a second ART approval invent path.

### 4.2 `make validate` policy

| Decision | Choice |
| --- | --- |
| Add `launch-gate-check` to `validate` | **Yes** — same class as `art-qa-check` (honesty always) |
| Require `LAUNCH_READY` in CI | **No** |

### 4.3 Agent playbook

**Path:** `docs/launch/AGENT_LAUNCH_PLAYBOOK.md`

Agents **may**:

1. Read gates → update `REPO_STATUS` “blocked on” from machine status  
2. After tip moves: demote stale `READY` → `EVIDENCE_INSUFFICIENT` + reason  
3. After humans paste real evidence: set `READY` **only if** `launch-gate-check` would pass  
4. Point operators at existing checklists (no full copy of ART protocol into the playbook)

Agents **must not**:

- Set `READY` without paths + tip match  
- Set `ART_SHIP_APPROVED` in art audit without existing art-qa rules  
- Fill store URLs or invent receipts  

### 4.4 Human packet relationship

| Doc | Role after this lands |
| --- | --- |
| `LAUNCH_OPERATOR_PACKET.md` | Still the **ordered human** steps 1–5; add pointer to machine truth |
| `docs/launch/launch_gates.json` | **Machine** status + evidence pointers |
| `AGENT_LAUNCH_PLAYBOOK.md` | How agents maintain gates + boards |
| Evidence docs | Unchanged surfaces |

### 4.5 continue-ss / board hooks

- continue-ss priority **launch**: inventory/audit should read `launch_gates.json` (or run checker) and report human blockers  
- v1: **read + report** gates; **no auto-edit** of JSON inside the workflow  
- `REPO_STATUS`: agent updates rows from checker output (manual edit OK; no required codegen in v1)

---

## 5. Tip churn, errors, seed, rollout

### 5.1 Tip churn

| Gate was | Checker | Agent action |
| --- | --- | --- |
| `READY` on old tip | **FAIL** `STALE_TIP` until fixed | Demote to `EVIDENCE_INSUFFICIENT`, reason tip moved, clear or annotate evidence |
| `BLOCKED` / `EVIDENCE_INSUFFICIENT` | **PASS** if otherwise honest | Optionally refresh `reason` / tip field |

Evidence is **tip-matched**, not once-forever. Deploy smoke on an old SHA does not keep `device_acceptance` green after binary/presentation-changing commits.

### 5.2 Error classes

| Code | Meaning | Exit |
| --- | --- | --- |
| `SCHEMA` | Missing keys / bad enum | 1 |
| `MISSING_PATH` | Evidence path file absent | 1 |
| `READY_WITHOUT_EVIDENCE` | READY with empty paths | 1 |
| `STALE_TIP` | READY tip ≠ current short SHA | 1 |
| `DEPENDENCY` | READY while a dependency is not READY | 1 |
| `ART_INCONSISTENT` | `art_ship` READY conflicts with art-qa honesty | 1 |
| (none) | Honest file; overall may be `LAUNCH_BLOCKED` | **0** |

### 5.3 Initial seed (day-0)

No gate starts `READY`.

| Gate | status | tip | evidence | reason (sketch) |
| --- | --- | --- | --- | --- |
| `device_acceptance` | `EVIDENCE_INSUFFICIENT` | current tip | optional pointer to device log (smoke-only) | No tip-matched full extract acceptance |
| `art_ship` | `EVIDENCE_INSUFFICIENT` | current / art audit tip | — | Align with `ART_EVIDENCE_INSUFFICIENT` |
| `store_metadata` | `BLOCKED` | — | `docs/APP_STORE_METADATA.md` | OWNER URLs / SKU / screenshots open |
| `audio_product` | `BLOCKED` | — | audio docs | No licensed product stems |
| `testflight_rc` | `BLOCKED` | — | — | Depends on priors |

JSON should include metadata: `schema_version`, `updated_utc`, optional `overall` derived field if agents refresh it after check.

### 5.4 Rollout order (implementation)

1. Schema + seed JSON + validator + Makefile target  
2. Wire into `validate` (honesty only)  
3. Agent playbook + pointers from `LAUNCH_OPERATOR_PACKET` / continuation docs  
4. `REPO_STATUS` + continue-ss read path  
5. **Not** changing product binary or inventing approvals  

### 5.5 Testing the checker

- Fixture-driven tests for the Python validator: each error class, one honest-blocked PASS, one full READY PASS with temp evidence files  
- No physical device required  
- Fixture location default: `scripts/testdata/launch/` (or `docs/launch/fixtures/`)

---

## 6. File map

| Path | Action |
| --- | --- |
| `docs/launch/launch_gates.json` | Create — seeded honest-blocked |
| `docs/launch/AGENT_LAUNCH_PLAYBOOK.md` | Create — agent rules |
| `scripts/validate_launch_gates.py` | Create — honesty checker |
| `scripts/testdata/launch/` (or equivalent) | Create — validator fixtures |
| `Makefile` | Edit — `launch-gate-check`; add to `validate` |
| `docs/LAUNCH_OPERATOR_PACKET.md` | Edit — pointer + make target |
| `docs/CONTINUATION_PLAN.md` / `CONTINUATION_PROMPT.md` | Edit — authority row |
| `docs/REPO_STATUS.md` | Edit — cite overall + per-gate |
| `.grok/workflows/continue-ss.rhai` | Light edit — inventory reads launch gates |
| `docs/superpowers/specs/2026-07-26-launch-path-design.md` | This design |

**Unchanged as primary evidence surfaces:**  
`DEVICE_TEST_LOG.md`, `ART_DEVICE_QA_CHECKLIST.md`, `APP_STORE_METADATA.md`, `art_qa/art_qa_audit.json`, `validate_art_qa_package.py`.

### Component flow

```
Human fills evidence docs
        ↓
Agent (optional) promotes/demotes launch_gates.json
        ↓
make launch-gate-check  ← honesty (CI via validate)
        ↓
REPO_STATUS / continue-ss  ← display + prioritize launch lane
        ↓
art-qa-check  ← still owns ART_SHIP_APPROVED rules
```

---

## 7. Open decisions (defaults locked for v1)

| ID | Topic | Default |
| --- | --- | --- |
| D1 | Tip for READY match | Current checkout short SHA |
| D2 | Docs-only tip lag | No auto-keep; operator re-attest only |
| D3 | `N_A` status | In schema; unused at seed |
| D4 | Validator fixtures | `scripts/testdata/launch/` preferred |
| D5 | continue-ss depth | Read + report; no auto-edit JSON in v1 |

---

## 8. Explicit non-goals (restate)

- No game code changes  
- No fake ART approval  
- No store URL invention  
- No requiring `LAUNCH_READY` for CI merge  
- No city 11, parallel render systems, or ElevenLabs generation as part of this design  

---

## 9. Implementation plan note

After user reviews and approves this written spec, invoke **writing-plans** to produce a step-by-step implementation plan. Do not implement until that plan exists and is approved per project process.

---

## 10. Spec self-review (at write time)

| Check | Result |
| --- | --- |
| Placeholders / TBD | None intentional; open decisions have defaults |
| Internal consistency | Checker PASS ≠ LAUNCH_READY; ART rules stay with art-qa-check; tip policy consistent |
| Scope | Single package: gates + checker + docs hooks; no product binary |
| Ambiguity | Tip = checkout HEAD; docs-only lag not automatic; overall derived |
| Contradictions | None found vs APPROACH 1 and approved sections 1–5 |
