# TestFlight RC residual closeout design

**Date:** 2026-08-02  
**Product:** Surveillance Survivor (`scrimshawlife-ctrl/Surveillance-Survivor`)  
**Status:** Design approved (brainstorm)  
**Approach:** Residual closeout playbook (A) — operator/owner playbook + gate promotion rules; no new gate IDs; no `ship_freeze.json`; no TF upload automation  

**Predecessor:** [`2026-07-26-launch-path-design.md`](2026-07-26-launch-path-design.md) (gate machine). This design **extends** that system for the last residual path to **RC cut allowed**.

---

## 1. Purpose, success, non-goals

### Purpose

Close the last honest path from current `LAUNCH_BLOCKED` residual state to **TestFlight RC cut allowed**, by specifying:

1. An explicit **ship SHA freeze** ritual (documented in the device log; not a new machine file)
2. Exact **READY criteria** for remaining gates
3. Who does what (owner / operator / agent) and in what order
4. When agents may promote or must demote

### Success definition for “done” (product residual)

| Outcome | Meaning |
| --- | --- |
| **In scope done** | All launch priors READY at the frozen tip; `testflight_rc` READY; overall may be `LAUNCH_READY` |
| **RC cut allowed** | Humans may cut a release candidate archive/build for TestFlight |
| **Out of scope** | Archive uploaded to App Store Connect, TF group assignment, public App Store submit |

### Success definition for implementing *this design*

Residual playbook written and linked (freeze templates, per-gate criteria, agent promote rules).  
**Not** required: any gate READY, rights PASS, or `LAUNCH_READY`.

### Non-goals

- App Store Connect upload, ASC submit, marketing, pricing
- New game systems, cities, weapons, audio generation
- New gate IDs or a `ship_freeze.json` artifact
- Replacing the 2026-07-26 gate system (extend only)
- Inventing rights clearance, listening pass, copyright confirmation, or owner screenshot accept
- Requiring `LAUNCH_READY` for CI merge

### Authority to extend (not replace)

| Artifact | Role |
| --- | --- |
| `docs/launch/launch_gates.json` | Machine gate status |
| `docs/launch/AGENT_LAUNCH_PLAYBOOK.md` | Agent promote/demote law |
| `docs/LAUNCH_OPERATOR_PACKET.md` | Human ordered steps |
| `docs/audio/rights/*` + `OWNER_EVIDENCE_PACKET.md` | Audio clearance |
| `docs/APP_STORE_METADATA.md` / store screenshots | Store residual |
| `docs/DEVICE_TEST_LOG.md` / `device_evidence/` / `art_qa/` | Device + ART |

---

## 2. Ship freeze + residual order

### 2.1 Ship SHA freeze (human ritual)

**When:** After intended RC content is on the ship branch/tip and **before** any gate is promoted to READY for that RC.

**Owner or operator records** a **Ship freeze** block in `docs/DEVICE_TEST_LOG.md`:

- Full SHA and short SHA
- Date/time UTC
- App version / build
- Intent label (e.g. `tf-rc-0.1.0-b1`)
- `git status --short` snapshot (default: clean tree; dirt must be explained)

**Rules:**

| Rule | Effect |
| --- | --- |
| Freeze tip = promotion tip | Every READY gate’s `tip_sha_short` must equal current `git rev-parse --short HEAD`, and that HEAD must be the frozen SHA |
| Docs-only commits after freeze | Break freeze; re-freeze at new tip |
| Binary/presentation after freeze | Re-freeze + re-run residual device/listening per §3 |
| Agents never invent freeze | Promote only after a freeze block exists for the current tip |

No `ship_freeze.json` in this design.

### 2.2 Residual work order

```text
[Freeze ship SHA]
        │
        ├─► Owner track (parallel)
        │     A. Store residual → store_metadata READY
        │     B. Audio rights + listening → audio_product READY
        │
        └─► Operator track (parallel when phone free)
              C. Tip-match device_acceptance READY
              D. Tip-match art_ship READY (depends on C)

        └─► Shared
              E. testflight_rc READY only when A–D all READY
              F. Humans cut RC (outside “allowed” boundary of this design)
```

**Ordering constraints:**

1. Freeze first — no READY promotes for the RC without freeze block on current tip.
2. Owner A and B may proceed in parallel.
3. Operator C before D (`art_ship` depends on `device_acceptance`).
4. E last — `testflight_rc` is dependency + tip match only.
5. Partial progress allowed — honest non-READY statuses while freeze is open; demote if tip moves.

### 2.3 Ownership matrix

| Step | Owner | Agent may |
| --- | --- | --- |
| Freeze block | operator or owner | Record only if human stated freeze; never invent |
| Store residual | owner | Promote after §3 criteria met |
| Audio rights + listening | owner (+ operator for listening) | Promote after `audio-rights-check` PASS + tip-matched listening notes |
| Device tip-match | operator | Promote after §3 criteria met |
| ART tip-match | operator | Promote only with art-qa honesty + dependency |
| `testflight_rc` | shared | Promote only when all priors READY + tip match |

---

## 3. Per-gate READY criteria (residual)

Common READY requirements (unchanged honesty):

- Non-empty `evidence_paths`; every path exists on disk
- `tip_sha_short` equals current short SHA and equals freeze short SHA
- Dependencies READY (`art_ship` → `device_acceptance`; `testflight_rc` → all four priors)
- `make launch-gate-check` PASS (honest)

### 3.1 `store_metadata` → READY

**Already complete (do not re-open as blockers):**

- Live privacy policy HTTPS and support HTTPS (zero-state Pages)
- SKU `SS-IOS-001`, game subcategory Action
- Worksheet + simulator screenshot candidate pack under `docs/store_screenshots/`

**Still required before READY:**

1. **Copyright confirmed** in `APP_STORE_METADATA.md` / `STORE_OWNER_INTAKE.md` (owner accepts proposed string or writes the legal string).
2. **Screenshots accepted for Connect prep** — exactly one of:
   - Owner accepts simulator candidates in `docs/store_screenshots/` for RC listing prep, **or**
   - Tip-matched physical/release stills replace or supplement that pack with updated manifest.

**Does not block this gate for RC cut allowed:**

- Age rating questionnaire completion in App Store Connect
- ASC privacy questionnaire submission  
  (These remain worksheet items for public submit; RC cut allowed ≠ public submit.)

**Minimum evidence paths:**  
`docs/APP_STORE_METADATA.md`, `docs/STORE_OWNER_INTAKE.md`, `docs/store_screenshots/manifest.json` (and claimed PNGs).

**Agents must not:** invent copyright confirmation or owner screenshot accept.

### 3.2 `audio_product` → READY

**Both** required:

1. **`make audio-rights-check` PASS** — all shipping assets cleared per existing fail-closed validator. Ledger scaffold with `pending_evidence` is **not** sufficient.
2. **Tip-matched physical-device listening notes** in `DEVICE_TEST_LOG.md` on the **frozen** tip, covering at least:
   - speaker balance
   - headphones or second route
   - silent mode
   - interruption recovery
   - route change
   - dense-combat mix / clipping

**Minimum evidence paths:**  
audio manifest, rights ledger, rights README or owner evidence packet, `DEVICE_TEST_LOG.md` (listening section for freeze tip).

**Agents must not:** set `rights_status=cleared`, invent private digests, or claim listening without a freeze-tip log block.

### 3.3 `device_acceptance` → READY

On the **frozen** tip:

| Freeze tip relative to prior evidence | Required re-work |
| --- | --- |
| No App/Game/Sources/Resources (binary/presentation) change since last full mechanical suite + live extract | Operator **attests** in log that full re-play is not required; still run **device-smoke + physical launch-smoke** on freeze tip; cite prior live extract paths honestly |
| Any App/Game/Sources/Resources or shipping asset change since last full suite | Full mechanical suite (`device-smoke`, `device-test`, `device-accept`, physical `launch-smoke`) **and** one **live** extract receipt on freeze tip |
| Only docs/gates/board changes | Smoke + physical launch-smoke on freeze tip; prior live extract + ART approval remain cited; reason names freeze tip and attestation |

**Always for READY:** freeze tip recorded; evidence paths and reason honestly bind acceptance to this freeze.

**Not READY from:** smoke alone, force-extract alone, or old tip without freeze attestation.

### 3.4 `art_ship` → READY

Depends on `device_acceptance` READY.

| Condition | Required |
| --- | --- |
| Operator already set `ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES` and freeze has no presentation/visual binary change since ART approval tip | Operator re-attests “ART still holds at freeze tip” in log; launch `art_ship` READY with art_qa approved-with-notes (or upgraded); non-empty device evidence paths |
| Presentation or visual binary change since ART approval tip | Re-run ART checklist eyes on freeze tip; update art_qa + log |

Nonblocking notes (walk frame density, formal 4-weapon matrix) **do not** block launch `art_ship` READY if operator already approved-with-notes and re-attests.

### 3.5 `testflight_rc` → READY

- `device_acceptance`, `art_ship`, `store_metadata`, and `audio_product` are all READY
- Same freeze tip on this gate
- Reason must state: RC cut allowed at `<shortsha>`; not uploaded
- Evidence paths may list priors’ primary evidence docs plus the freeze log section

**Does not mean:** archive uploaded, TF group assigned, or ASC submit.

### 3.6 Demotion

Any commit that changes `HEAD` short SHA after READY:

- Demote all READY gates to `EVIDENCE_INSUFFICIENT` (leave already non-READY as-is)
- Reason: tip moved; re-freeze required
- Prefer demote over tip-lag exceptions (existing playbook law)

---

## 4. Implementation surface (docs/playbooks only)

### 4.1 Deliverables when this design is implemented

| Artifact | Change |
| --- | --- |
| `docs/launch/TESTFLIGHT_RC_RESIDUAL.md` | **New** operator-facing residual closeout: freeze ritual, store/audio/device/ART checklists, RC-allowed meaning |
| `docs/launch/AGENT_LAUNCH_PLAYBOOK.md` | Residual promote rules: freeze required; pointers to per-gate criteria; demote on tip move |
| `docs/LAUNCH_OPERATOR_PACKET.md` | Point residual steps at freeze + residual doc; refresh next human residual |
| `docs/CONTINUATION_PLAN.md` / `docs/REPO_STATUS.md` | Board hygiene: residual path cites residual doc |
| `docs/APP_STORE_METADATA.md` / `docs/STORE_OWNER_INTAKE.md` | Residual checklist language: copyright confirm + screenshot accept; RC vs public submit |
| `docs/audio/rights/OWNER_EVIDENCE_PACKET.md` | Cross-link: rights PASS + listening on freeze tip |
| `docs/DEVICE_TEST_LOG.md` | **Ship freeze** + **Listening (freeze tip)** template sections |
| `docs/launch/launch_gates.json` | Promote/demote **only** when human evidence is real — not as part of empty doc implementation |

### 4.2 Explicitly not in design implementation

- Filling private audio digests or setting assets cleared
- Flipping any gate READY without human evidence
- TestFlight upload scripts
- Mandatory physical screenshot recapture (optional if owner accepts sim pack)

### 4.3 Validation after doc implementation

```bash
make launch-gate-check   # honest; may remain LAUNCH_BLOCKED
make release-docs-check
make repo-status-check
make audio-rights-check  # BLOCKED until owner evidence
```

---

## 5. Failure modes and testing

### 5.1 Failure modes

| Failure | Response |
| --- | --- |
| Promote READY without freeze block | Forbidden by playbook; demote if found |
| Rights scaffold treated as clearance | `audio-rights-check` remains fail-closed until cleared |
| Screenshot accept then binary art change | Re-freeze; re-accept or recapture |
| Listening notes on old tip | Invalid for `audio_product` READY; re-run on freeze tip |
| Only smoke after binary-moved freeze | Do not READY `device_acceptance`; require full suite + live extract |
| `testflight_rc` READY while a prior is not | Checker `DEPENDENCY` failure; demote RC |
| Tip moves after `LAUNCH_READY` | Demote all READY gates; overall `LAUNCH_BLOCKED` |

### 5.2 Testing for residual doc work

- No new unit tests required for approach A (unless a later design adds validators).
- Manual walkthrough: every READY criterion points at an existing path or a named human action.
- Existing honesty checks must stay PASS (overall may stay `LAUNCH_BLOCKED`).

### 5.3 Definition of done (layers)

| Layer | Done means |
| --- | --- |
| Design implementation | Residual playbook + freeze templates + playbook/operator/board links committed |
| Product residual (humans) | Freeze + store residual + rights PASS + listening + tip-match device/ART |
| RC cut allowed | All five gates READY at freeze tip; overall `LAUNCH_READY` |
| Out of scope | Archive upload, TF group, ASC submit |

### 5.4 End-state flow

```text
Freeze SHA
  → store READY ‖ audio READY (rights + listening)
  → device_acceptance READY → art_ship READY
  → testflight_rc READY
  → human may cut RC
```

---

## 6. Current residual snapshot (context at design time)

Honest at design writing (tip may advance; re-read gates):

| Gate | Typical residual status |
| --- | --- |
| `device_acceptance` | EVIDENCE_INSUFFICIENT — mechanical + live extracts filed; not tip-matched READY |
| `art_ship` | EVIDENCE_INSUFFICIENT — ART approved with nonblocking notes; launch READY awaits tip-match + device READY |
| `store_metadata` | EVIDENCE_INSUFFICIENT — URLs + SKU + sim screenshots; copyright + screenshot accept open |
| `audio_product` | BLOCKED — ledger scaffolded pending; private verified evidence + listening open |
| `testflight_rc` | BLOCKED — depends on priors |
| Overall | `LAUNCH_BLOCKED` |

---

## 7. Approval record

| Item | Value |
| --- | --- |
| Brainstorm scope | Last mile to TestFlight RC cut allowed |
| Done means | RC cut allowed only (not upload) |
| Weight | Operator playbook + gate promotion rules |
| Ship SHA | Explicit freeze then promote |
| Approach | A — residual playbook (no ship_freeze.json) |
| Sections approved | §1–§5 (2026-08-02) |
