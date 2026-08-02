# Agent launch playbook

**Audience:** agents and board hygiene.  
**Machine truth:** [`launch_gates.json`](launch_gates.json) + `make launch-gate-check`.  
**Humans fill evidence.** Agents never invent green.

Related: design [`docs/superpowers/specs/2026-07-26-launch-path-design.md`](../superpowers/specs/2026-07-26-launch-path-design.md) · human steps [`docs/LAUNCH_OPERATOR_PACKET.md`](../LAUNCH_OPERATOR_PACKET.md) · board [`docs/REPO_STATUS.md`](../REPO_STATUS.md).

---

## 1. Purpose

This playbook tells agents how to maintain launch gate honesty: promote and demote statuses in `docs/launch/launch_gates.json`, keep boards (`REPO_STATUS` and continue-ss inventory) aligned with the checker, and refuse to invent ship-ready state.

**Agents and the board** treat the machine file as source of truth for “are we ship-blocked, and on what?” **Humans** fill evidence slots—device logs, ART checklist rows, live store URLs, audio rights/listening acceptance, GitHub #3 ship notes. Agents prepare structure, enforce tip match, demote when the tip moves, and promote to `READY` only when the honesty checker would pass.

Success for this system is an **honest blocked state**, not a green dashboard. Running `make launch-gate-check` must always yield truth: either correctly blocked with named human owners and reasons, or green only when required evidence paths exist on disk and are tip-aligned. Never fake pass. Checker **exit 0** means the file is honest; overall may still be `LAUNCH_BLOCKED`. Exit 0 is **not** permission to claim the game is ship-ready.

Do not copy full ART or release protocols into this file. Point operators at existing checklists. This document is procedure for agents only.

---

## 2. Machine truth

| Artifact | Role |
| --- | --- |
| [`docs/launch/launch_gates.json`](launch_gates.json) | Single source of machine truth: per-gate `status`, `tip_sha_short`, `evidence_paths`, `reason`, `owner`, `depends_on`; optional derived `overall` |
| `make launch-gate-check` | Runs `python3 scripts/validate_launch_gates.py`; schema + honesty rules |
| Checker stdout | Derived overall (`LAUNCH_BLOCKED` / `LAUNCH_READY`) plus one line per gate |
| `python3 scripts/test_validate_launch_gates.py` | Unit tests for the validator (fixtures under `scripts/testdata/launch/`) |
| `make art-qa-check` | Owns `art_qa_audit.json` `ship_gate` honesty; launch checker couples to it for `art_ship` |

### Gates (ordered IDs)

| ID | Owner | Meaning |
| --- | --- | --- |
| `device_acceptance` | operator | Tip-matched full device pass + extract receipt |
| `art_ship` | operator (+ owner on GitHub #3) | Device ART checklist; ART ship flip only with evidence |
| `store_metadata` | owner | Live privacy/support URLs, SKU fields, screenshot plan filled |
| `audio_product` | owner | License + Batch 1 product stems (never system sounds) |
| `testflight_rc` | shared | RC cut **allowed** only when all priors are `READY` (not “uploaded”) |

### Status enum

`BLOCKED` · `EVIDENCE_INSUFFICIENT` · `READY` · `N_A`

- **`READY`** requires non-empty `evidence_paths`, every path present on disk, and `tip_sha_short` equal to current checkout short SHA (`git rev-parse --short HEAD`). No automatic tip lag.
- **`N_A`:** allowed in schema for intentional product skip; unused at seed—do not invent N_A to dodge blockers.
- **Dependencies:** `art_ship` depends on `device_acceptance`. `testflight_rc` depends on `device_acceptance`, `art_ship`, `store_metadata`, `audio_product`. Do not set a gate `READY` while a dependency is not `READY` (checker: `DEPENDENCY`).

### Overall vs checker exit

| Concept | Meaning |
| --- | --- |
| `LAUNCH_BLOCKED` | Any required gate is not `READY` (or `N_A`) |
| `LAUNCH_READY` | All required gates `READY` (or `N_A`) and tip-aligned |
| Checker exit **0** | File is **honest** (schema + rules hold)—may still print `overall=LAUNCH_BLOCKED` |
| Checker exit **1** | Schema break, missing paths, READY without evidence, stale tip, dependency violation, or `ART_INCONSISTENT` |

Refresh `overall` / `updated_utc` in the JSON when you edit gates so boards and humans see the same derived state as checker stdout. Prefer matching checker output; do not hand-write `LAUNCH_READY` while any gate is not ready.

### Error classes (agent repair guide)

| Code | Meaning | Agent action |
| --- | --- | --- |
| `SCHEMA` | Missing keys / bad enum | Fix structure; do not invent READY to clear |
| `MISSING_PATH` | Evidence path file absent | Point only at paths that exist; create docs only when humans provided content |
| `READY_WITHOUT_EVIDENCE` | READY with empty paths | Demote or add real paths |
| `STALE_TIP` | READY tip ≠ current short SHA | Demote to `EVIDENCE_INSUFFICIENT` (see §5) |
| `DEPENDENCY` | READY while a dependency is not READY | Demote the dependent gate or wait for priors |
| `ART_INCONSISTENT` | `art_ship` READY conflicts with art-qa honesty | Align with `make art-qa-check`; never flip ART without rules |

---

## 3. Human evidence surfaces

Agents prepare and enforce pointers. Humans write the content. Link each gate only to the surfaces below—do not invent parallel evidence homes.

| Gate ID | Primary human evidence surface(s) | What “enough” looks like (human-owned) |
| --- | --- | --- |
| `device_acceptance` | [`docs/DEVICE_TEST_LOG.md`](../DEVICE_TEST_LOG.md) · ordered steps in [`docs/LAUNCH_OPERATOR_PACKET.md`](../LAUNCH_OPERATOR_PACKET.md) · matrix in [`docs/RELEASE_READINESS.md`](../RELEASE_READINESS.md) | Tip-matched full device acceptance on current checkout: signed Debug play, full extract, **COPY RECEIPT JSON** pasted, observations recorded for **this** short SHA—not deploy-only smoke and not an older SHA |
| `art_ship` | [`docs/ART_DEVICE_QA_CHECKLIST.md`](../ART_DEVICE_QA_CHECKLIST.md) (combat + city readability on device) · device log combat/readability sections · owner ship yes/no on **GitHub #3** · machine audit [`docs/art_qa/art_qa_audit.json`](../art_qa/art_qa_audit.json) | Checklist completed for tip; non-empty device evidence paths in the ART audit when promoting; `ship_gate` may move to `ART_SHIP_APPROVED` / `ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES` **only** under existing art-qa rules so `make art-qa-check` passes. Launch `art_ship` READY must not contradict ART insufficient/approved honesty |
| `store_metadata` | [`docs/APP_STORE_METADATA.md`](../APP_STORE_METADATA.md) · residual: [`TESTFLIGHT_RC_RESIDUAL.md`](TESTFLIGHT_RC_RESIDUAL.md) §A | OWNER rows filled: live HTTPS privacy policy URL, live HTTPS support URL, SKU, copyright, age rating, game subcategory, screenshot plan from **release** iPhone build (not README hero). Agents **never** invent or paste fake store URLs |
| `audio_product` | [`docs/AUDIO_ASSET_MANIFEST.json`](../AUDIO_ASSET_MANIFEST.json) · [`docs/AUDIO_PLAN.md`](../AUDIO_PLAN.md) · [`docs/AUDIO_ASSET_PRODUCTION_BIBLE.md`](../AUDIO_ASSET_PRODUCTION_BIBLE.md) · [`DEVICE_TEST_LOG.md`](../DEVICE_TEST_LOG.md) · residual: §B + freeze-tip listening | 68/68 integrated assets plus owner rights confirmation and tip-matched physical-device listening/routing/interruption/mix evidence. Repository integration alone is **not** READY. **Never** system-sound placeholders |
| `testflight_rc` | All of the above as priors; RC cut policy in operator packet / release readiness · residual: [`TESTFLIGHT_RC_RESIDUAL.md`](TESTFLIGHT_RC_RESIDUAL.md) | Allowed only when `device_acceptance`, `art_ship`, `store_metadata`, and `audio_product` are all `READY`. This gate means “RC cut is allowed,” not “already uploaded to TestFlight.” Do not mark READY to mean “we hope to upload” |

**Worksheet vs READY:** Non-READY gates may list worksheet paths that exist (e.g. empty template log, open store metadata). Empty `evidence_paths` is OK for blocked gates. **READY always needs real, tip-matched evidence paths that exist on disk.**

---

## 4. May / must not

Copied and expanded from design §4.3. Global rule: **agents never invent `READY`, `ART_SHIP_APPROVED`, or store URLs.**

### Agents may

1. **Read gates → update boards.** After `make launch-gate-check`, update `REPO_STATUS` “blocked on” / launch rows from machine status and checker stdout (overall + per-gate one-liners). continue-ss inventory/audit should **read and report** gates; v1 does **not** auto-edit the JSON inside the workflow.
2. **After tip moves: demote.** Any gate still `READY` for an old short SHA → set `EVIDENCE_INSUFFICIENT` (or leave non-READY statuses as-is), set `reason` that tip moved, clear or annotate evidence, set `tip_sha_short` to current tip or null per honesty, run checker until **PASS** (honest blocked is fine).
3. **After humans paste real evidence: set `READY` only if `launch-gate-check` would pass.** Populate `evidence_paths` with repo-relative paths that exist, set `tip_sha_short` to `git rev-parse --short HEAD`, write an accurate `reason`/attestation note, then run the checker. If it fails, fix or demote—do not leave a lying READY.
4. **Point operators at existing checklists.** Link `LAUNCH_OPERATOR_PACKET`, device log, ART checklist, store worksheet, audio docs—no full copy of ART protocol into agent replies or this playbook.
5. **Set status down freely.** Demote is always safer than silent green. Prefer demote over inventing a docs-only tip-lag exception (operators may re-attest in the device log; agents do **not** invent that exception).

### Agents must not

- Set **`READY`** without non-empty `evidence_paths` **and** tip match to current checkout short SHA.
- Set **`ART_SHIP_APPROVED`** (or approved-with-notes) in `docs/art_qa/art_qa_audit.json` without satisfying existing art-qa rules and `make art-qa-check`.
- Fill **store URLs**, invent **device receipts**, invent **extract JSON**, invent **ElevenLabs / product stems**, or invent **GitHub #3 ship approval**.
- Claim **`LAUNCH_READY`** or ship-ready product state because the checker exited 0 while overall is still `LAUNCH_BLOCKED`.
- Use **`N_A`** to hide open work, or require **`LAUNCH_READY`** for CI merge (CI only requires honesty via `validate` / `launch-gate-check`).
- Auto-keep prior device/ART evidence across binary or presentation-changing commits without operator re-attest in the evidence surfaces.

---

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

---

## 5. After tip moves

Evidence is **tip-matched**, not once-forever. Deploy smoke or acceptance on an old SHA does not keep `device_acceptance` (or other READY gates) green after commits that change the binary or presentation.

| Gate was | Checker | Agent action |
| --- | --- | --- |
| `READY` on old tip | **FAIL** `STALE_TIP` until fixed | Demote to `EVIDENCE_INSUFFICIENT`, reason tip moved, clear or annotate evidence paths |
| `BLOCKED` / `EVIDENCE_INSUFFICIENT` | **PASS** if otherwise honest | Optionally refresh `reason` / `tip_sha_short` / `updated_utc` |

### Procedure

1. Resolve tip: `git rev-parse --short HEAD`.
2. Open `docs/launch/launch_gates.json`. For every gate with `status` == `READY` whose `tip_sha_short` ≠ current tip: set `status` to `EVIDENCE_INSUFFICIENT`, update `reason` (e.g. tip moved; re-run device/ART evidence for new SHA), and either clear `evidence_paths` or leave worksheet pointers with an explicit note that they are not tip-matched acceptance.
3. Cascade: if you demote `device_acceptance`, demote dependents that were `READY` (`art_ship`, and if needed `testflight_rc`) so dependencies stay honest.
4. Align `art_ship` with ART audit if the tip moved under ART rules (do not leave launch `art_ship` READY while art-qa is insufficient).
5. Set `updated_utc` (UTC ISO-8601) and set `overall` to match derived state (almost always `LAUNCH_BLOCKED` after demote).
6. Run until clean:

```bash
make launch-gate-check
```

Expected after honest demote: exit **0**, `overall=LAUNCH_BLOCKED`, no `STALE_TIP`. Prefer agent demote over silent green or leaving the tree red.

**Docs-only tip lag:** pure-docs commits may keep prior device evidence **only if an operator explicitly re-attests** in the device log. Agents **do not** invent that exception; default is demote.

---

## 6. After human evidence

When a human pastes real evidence into the surfaces in §3, an agent may promote gates carefully.

### Promote procedure (any gate)

1. Confirm evidence is **for this tip** (short SHA in logs/checklists matches `git rev-parse --short HEAD`), not historical smoke.
2. Confirm every evidence file path exists and is repo-relative.
3. Confirm dependencies are already `READY` if you are promoting a dependent gate.
4. Edit the gate: `status` → `READY`, `tip_sha_short` → current short SHA, `evidence_paths` → non-empty real paths, `reason` → short attestation (what was proven).
5. Refresh `updated_utc` and derived `overall` only after you know the full set of gate statuses.
6. Run `make launch-gate-check`. **Promote is complete only if exit 0.** If FAIL, demote or fix paths—never leave READY that the checker rejects.
7. Update boards (§7).

### `art_ship` special case

`art_ship` → `READY` is only honest if ART package rules would allow approval:

1. `device_acceptance` must already be `READY` (dependency).
2. Device ART checklist and device log entries exist for the tip; non-empty device evidence paths.
3. Updating `docs/art_qa/art_qa_audit.json` (`ship_gate`, `device_evidence_paths`, tip fields) is allowed **only under existing art-qa rules**—same bar as `scripts/validate_art_qa_package.py` / `make art-qa-check`. Do not invent `ART_SHIP_APPROVED`.
4. Run both:

```bash
make art-qa-check
make launch-gate-check
```

If art-qa fails, do not claim launch `art_ship` READY. Launch checker treats ART flip rules as owned by art-qa-check; conflicting READY yields `ART_INCONSISTENT`.

### `store_metadata` / `audio_product`

Promote only after OWNER content is real in-repo (live URLs written by humans; licensed stems present). Point `evidence_paths` at those docs/assets. Never fabricate URL strings or audio files to clear the gate.

### `testflight_rc`

Set `READY` only when all four priors are `READY` and tip-aligned. Meaning: RC cut is **allowed**. Do not set READY merely because someone wants a TestFlight build, and do not imply upload completed.

---

## 7. Board hygiene

Boards display machine truth; they do not override it.

### `docs/REPO_STATUS.md`

After any gate edit or whenever continue work prioritizes launch:

1. Run `make launch-gate-check` and capture stdout (overall + per-gate lines).
2. Update launch / “blocked on” rows so **overall** matches checker (`LAUNCH_BLOCKED` or `LAUNCH_READY`).
3. Update **per-gate** status, owner, and short reason from the JSON and stdout—not from memory or aspirational ship narrative.
4. Manual edit is OK in v1; no required codegen. Never write board text that claims READY while `launch_gates.json` says otherwise.

### continue-ss / inventory

- Priority **launch**: inventory/audit should read `launch_gates.json` (or run the checker) and report human blockers.
- v1: **read + report** only; **no auto-edit** of the JSON inside the workflow. Agents editing gates do so in an explicit doc task with this playbook, then re-run the checker.

### Operator packet and continuation docs

Human ordered steps remain in `LAUNCH_OPERATOR_PACKET.md`. Agents keep authority maps pointing at this playbook and the machine file when those docs list launch authority. Do not replace human packet content with agent-only procedure.

---

## 8. Commands

From repo root:

```bash
# Honesty check (PASS + LAUNCH_BLOCKED is normal and correct)
make launch-gate-check

# Validator unit tests (fixtures; no device required)
python3 scripts/test_validate_launch_gates.py -v

# ART package honesty (owns ART_SHIP_APPROVED rules; couple when editing art_ship)
make art-qa-check

# Current tip for READY tip_sha_short
git rev-parse --short HEAD
```

`make validate` includes `launch-gate-check` (honesty only). It does **not** require `LAUNCH_READY`.

### Typical agent loop

```bash
git rev-parse --short HEAD
# edit docs/launch/launch_gates.json (demote or honest promote)
make launch-gate-check
# if art_ship or art_qa_audit.json touched:
make art-qa-check
# then refresh docs/REPO_STATUS.md from checker stdout
```

---

## Quick reference

| Do | Don't |
| --- | --- |
| Demote freely when tip moves | Invent READY / ART_SHIP_APPROVED / store URLs |
| Promote only when checker would pass | Treat checker PASS as ship approval |
| Point humans at DEVICE_TEST_LOG, ART checklist, APP_STORE_METADATA, audio docs | Replace those surfaces with agent fiction |
| Keep REPO_STATUS = checker stdout | Board override of machine gates |
| Keep art_ship consistent with art-qa-check | art_ship READY + ART_EVIDENCE_INSUFFICIENT |
