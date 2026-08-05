# Graphics & Playability Field Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a tip-frozen dual-lane (graphics + playability) field audit report that explains partner “looks fucked up” feedback with evidence and ranked fixes, without inventing READY.

**Architecture:** Freeze HEAD → machine honesty pack → known-risk checklist → play session (device preferred, sim labeled weaker) → findings table S0–S3 → single report + audits index link.

**Tech Stack:** git, make validators, optional simulator/device, markdown report under `docs/`.

**Spec:** [`docs/superpowers/specs/2026-08-05-graphics-playability-field-audit-design.md`](../specs/2026-08-05-graphics-playability-field-audit-design.md)

## Global Constraints

- Dual lanes: **G graphics** and **P playability** — both required in the report.
- Never invent READY / ART_SHIP tip-match / store / rights clearance.
- No SKPhysics combat fixes; Core owns hits.
- Prefer presentation/content dispositions unless S0 softlock/unfair sim proven.
- Tip freeze at start; re-note if tip moves mid-audit.
- Simulator evidence must be labeled **weaker** than device.

## File map

| Path | Role |
| --- | --- |
| Create: `docs/CONTINUATION_REPORT_YYYY-MM-DD_graphics_playability_field_audit.md` | Main deliverable |
| Modify: `docs/audits/README.md` | Link report |
| Optional: `docs/REPO_STATUS.md` | Suggested next only if S0/S1 block residual |
| Read: Batch 6 receipt, Audit B, ART checklists, `GameScene` camera, WorldProjector ground |

---

### Task 1: Tip freeze + machine pack

**Files:** (notes only until report write)

- [ ] **Step 1: Freeze tip**

```bash
git fetch origin --prune
git rev-parse HEAD
git rev-parse --short HEAD
git status --short
```

- [ ] **Step 2: Machine pack**

```bash
make version-check repo-status-check launch-gate-check art-qa-check
make assets-check animation-check weapon-vfx-check
# optional
make sprite-chroma-check 2>/dev/null || true
```

Record: overall LAUNCH_BLOCKED, asset PNG count, animation clip summary, art_qa ship_gate + commit_short.

- [ ] **Step 3: Known-risk prefill**

From docs/receipts, list candidates (wardrobe, 4f walks, effect sizes by eye, pale carpet, camera 1.38, stale ART tip) for confirmation during play.

---

### Task 2: Play session

- [ ] **Step 1: Platform**

Prefer device (`DEVELOPMENT_TEAM=… make device-smoke` or install). If unavailable: iOS Simulator; label weaker.

- [ ] **Step 2: Script (~10–15 min)**

Per city (Wichita, Louisville, + one dense): splash → BEGIN RUN → stick move → combat observe → damage if possible → LPR → pause/resume → note extract if reached.

- [ ] **Step 3: Capture defects**

Assign G-## / P-##, severity S0–S3, repro, evidence path or “note only”.

---

### Task 3: Write report + link + commit

- [ ] **Step 1: Write** `docs/CONTINUATION_REPORT_YYYY-MM-DD_graphics_playability_field_audit.md` using design §7 structure.

- [ ] **Step 2: Partner-facing top 5** (non-jargon).

- [ ] **Step 3: Update** `docs/audits/README.md` with link.

- [ ] **Step 4: Optional board** Suggested next if S0/S1.

- [ ] **Step 5: Commit**

```bash
git add docs/CONTINUATION_REPORT_*_graphics_playability_field_audit.md docs/audits/README.md
git commit -m "docs(audit): graphics and playability field audit after partner feedback"
```

- [ ] **Step 6: Verify**

```bash
make repo-status-check launch-gate-check
test -f docs/CONTINUATION_REPORT_*_graphics_playability_field_audit.md
```

---

## Spec coverage

| Spec | Task |
| --- | --- |
| Tip freeze + machine pack | Task 1 |
| Dual G/P lanes | Task 2–3 |
| Session script + 3 cities | Task 2 |
| Findings + top 5 + non-claims | Task 3 |
| No READY / no SKPhysics | Global |

## Execution note

If device unavailable, complete Tasks 1 + 3 with simulator or **code/doc evidence-only** for known risks, and mark play session `blocked_no_device` / `sim_only` honestly.
