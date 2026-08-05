# Graphics & playability field audit design

**Date:** 2026-08-05  
**Product:** Surveillance Survivor  
**Status:** Design approved (brainstorm)  
**Trigger:** Partner secondhand report — “game looks fucked up” (no structured symptom list)  
**Tip context at design:** `main` after #156 (UrbanDress / satellite 1.38 / 1.5× arenas), #159 (prompted sprites / terrain carpet), #160 (enemy walks / event clips / transient FX); open PRs none; launch **LAUNCH_BLOCKED**  
**Prior related audits:** B presentation/art (machine PASS, device blocked); D isolation PASS (no SKPhysics combat); A ship residual (do not freeze READY)

## 1. Purpose

Run a **tip-frozen dual-lane field audit** (graphics + playability) that:

1. Explains likely causes of partner reaction with **evidence**, not vibes alone.  
2. Separates **looks wrong** from **plays wrong**.  
3. Ranks defects and recommends a fix order.  
4. Never invents READY, ART_SHIP tip-match, store, or rights clearance.

This is an **investigation + report** program, not a feature build. Code fixes spawn **separate** plans only for proven S0/S1 defects.

## 2. Problem framing

Recent presentation stack landed without a **device ART re-attest on HEAD**:

| Change | Risk class |
| --- | --- |
| #156 UrbanDress + camera 1.38 + larger arenas | Scale, density, street paint, landmark alpha |
| #159 Prompted sprites + pale full terrain carpet | Contrast, busy ground, wardrobe inconsistency |
| #160 Walk cycles + event clips + transient effects | Flicker, FX clutter, wrong layering, reduced-motion |

Audit B already marked operator checklist `blocked_no_device` and ART approval **stale**. Partner feedback is consistent with that gap; it is not treated as proof of a Core combat regression unless play session shows one.

## 3. Approach (locked)

**Dual-lane field audit on HEAD (Approach 1).**

Rejected:

- Graphics-only deep dive (misses feel).  
- Residual mechanical suite alone (can PASS while visuals fail).  

## 4. Scope

### 4.1 Lane G — Graphics

**In**

- Silhouette / entity contrast on pale carpet and UrbanDress  
- Camera scale 1.38 and 1.5× arena readability at combat range  
- Terrain carpet (full 256 nearest): busy, muddy, or featureless  
- Black boxes, opaque corners, magenta, missing alpha  
- Player/guard walk shimmer, wardrobe discontinuity, feet baselining  
- Transient FX clutter (telegraph under boss, impacts over shots, redaction attachment)  
- Layering / z-order failures  
- City sample readability (minimum cities below)

**Out**

- Generating replacement art sets in this audit (unless a later plan is opened)  
- Claiming art_ship READY  

### 4.2 Lane P — Playability

**In**

- Stick appear/reach, landscape usability  
- Combat readability: LPR cones, suspicion, projectiles, threats  
- Ability to survive first minute without “unfair” instant death (subjective note + evidence)  
- Softlocks: stuck in geometry, pause/draft stuck, spawn issues  
- Blind Spot / extract clarity  
- Control-blocking hitch or freeze  
- Whether presentation FX **obscure** play-critical info  

**Out**

- Balance redesign, new weapons, city systems  
- Introducing SKPhysics combat (forbidden; isolation law)  
- Claiming device_acceptance READY  

## 5. Method

### 5.1 Tip freeze

At audit start:

```bash
git fetch origin --prune
git rev-parse HEAD
git rev-parse --short HEAD
git status --short
```

Record full SHA, short SHA, branch, dirty explanation. Prefer clean tree for evidence.

### 5.2 Machine honesty pack

```bash
make version-check repo-status-check launch-gate-check art-qa-check
make assets-check animation-check weapon-vfx-check
```

Optional: `make sprite-chroma-check` if available.

Paste gate overall (expect **LAUNCH_BLOCKED**) and asset counts (expect ~365 PNGs post-#160 unless tip moved).

### 5.3 Known-risk checklist (machine + doc)

Pre-fill findings candidates from:

- Player walk wardrobe / multi-outfit frames (Batch 6 receipt notes)  
- Walk banks 4f vs target [6,10]  
- Effect sizes chosen “by eye” (Batch 6 receipt)  
- ART approval tip ≠ HEAD  
- Pale carpet + full coverage visual density  
- Satellite zoom combat readability (older tip only)  

Mark each: **confirmed** / **not observed** / **not tested**.

### 5.4 Play session script (~10–15 minutes)

Minimum path (same tip, notes with timestamps):

1. Launch → splash → start menu → BEGIN RUN  
2. Move with dynamic stick; note lag/reach  
3. Engage combat: observe cones, fire, guards approaching  
4. Take damage if safe; observe damage/defeat presentation if triggered  
5. Observe LPR poles (scan loop) and any camera disable/redaction if available  
6. Note extract / Blind Spot if reachable in window  
7. Pause / settings / resume once  

**Cities:** at least **three** — Wichita, Louisville, plus one dense (e.g. NYC / SF / Atlanta). Full ten optional.

**Platform:** physical iPhone preferred. Simulator allowed if labeled **weaker evidence**.

### 5.5 Capture

For each defect:

| Field | Content |
| --- | --- |
| ID | G-01, P-01, … |
| Lane | G or P (or both) |
| Severity | S0 blocking softlock/crash · S1 unreadable combat · S2 ugly/confusing · S3 polish |
| Symptom | What partner would notice |
| Repro | City, tip, steps |
| Evidence | screenshot path / note / sim only |
| Likely system | UrbanDress / carpet / camera / walk bank / FX / input / Core? |
| Disposition | fix presentation · fix content · Core investigation · residual operator · accept risk |

### 5.6 Triage rules

- Prefer **presentation** fixes when isolation holds.  
- **Core** only if softlock, wrong collision, or unfair sim behavior is reproduced.  
- Do **not** “fix” combat feel with SKPhysics.  
- S0/S1 presentation defects → separate fix plan after report.  
- S2/S3 may batch or defer to ART residual.

## 6. Deliverables

| Artifact | Path |
| --- | --- |
| This design | `docs/superpowers/specs/2026-08-05-graphics-playability-field-audit-design.md` |
| Implementation plan (after plan skill) | `docs/superpowers/plans/2026-08-05-graphics-playability-field-audit.md` |
| Field report | `docs/CONTINUATION_REPORT_YYYY-MM-DD_graphics_playability_field_audit.md` |
| Partner-facing summary (optional section in report) | Non-jargon top 5 issues |

Link report from `docs/audits/README.md` when written.

## 7. Report structure (required)

1. Tip freeze + platform  
2. Machine pack summary  
3. Known-risk checklist results  
4. Session log (cities, duration)  
5. Findings table (G and P)  
6. Ranked top 5  
7. Recommended next (owner / operator / agent)  
8. **Non-claims** (no READY, no tip-matched ART ship, no rights/store clearance)

## 8. Success criteria

- Dual lanes both addressed (even if one is “no P defects observed”).  
- At least three cities attempted or blocked with reason.  
- Every S0/S1 has repro + disposition.  
- Partner can read top 5 without reading Core code.  
- Isolation law reaffirmed (no SKPhysics combat path introduced or recommended).

## 9. Error handling

| Situation | Response |
| --- | --- |
| No device available | Run simulator script; label weaker; still complete report |
| Crash / softlock | S0; capture logs; stop session; file Core vs presentation hypothesis |
| Cannot repro partner words | Report “not observed on tip X”; keep known-risk open items |
| Pressure to ship | Refuse READY; cite residual audits A/B |

## 10. Relationship to prior audits

| Prior | Use |
| --- | --- |
| Audit B | Machine baseline; stale ART; empty device checklist — this audit **fills field eyes** |
| Audit D | Isolation PASS — start from presentation/content, not physics rewrite |
| Audit A | Ship residual still blocked — this audit may add **why ART re-attest is urgent** |
| Prabu #160 | Animation integration present; evaluate **quality**, not re-open integration scope unless broken |

## 11. Non-goals

- Mass sprite regeneration during the audit  
- TestFlight upload or gate READY flips  
- Full ten-city formal ART package unless time allows  
- Balancing weapon DPS or guard speeds  

## 12. Approval record

| Item | Status |
| --- | --- |
| Dual-lane (graphics + playability) | Approved |
| Secondhand partner trigger (no symptom taxonomy) | Approved (option D) |
| Sim-first allowed if device unavailable | Approved |
| No READY invention; separate fix plans for S0/S1 | Approved |
