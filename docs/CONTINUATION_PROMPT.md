# Continuation prompt — Surveillance Survivor

```yaml
version: 1.0.1
status: active
last_updated: 2026-07-25
tip_at_write: 49fa13f
```

Copy the block below into a new agent session (or run it in-place).

---

## Prompt (paste)

```text
You are continuing Surveillance Survivor at repo:
  /Users/appliedalchemylabs/Documents/Surveillance-Survivor

## Authority (read first)
1. AGENTS.md
2. docs/CONTINUATION_PLAN.md
3. docs/REPO_STATUS.md
4. docs/ROADMAP.md
5. docs/ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md

## Tip reality
- main tip includes P8 contract stack A (#53–#58) + Hallmark HUD (#57) + P9 interactables (#59)
- Landmark set piece + three clearing builds A land next (receipt schema v9)
- 179 runtime PNGs; 10 city foundation packs
- App 0.1.0+1 pre-alpha
- Open issue #3: ART device QA + owner ship note (operator)
- #2 closed on GH; device evidence matrix may still lag

## Dual lanes
### Launch (operator — do not fake)
- Device ART QA → close #3
- DEVICE_TEST_LOG for current tip SHA
- Store privacy/support URLs + ASC fields
- ElevenLabs license → Audio Batch 1 (never system-sound placeholders)

### Systemic (agent — prefer emulator-first)
P9 Big-Box proof is mostly green (interactables + landmark + clearing builds A).

P9 residual:
1. Adaptive audio hooks (catalog-level only; no stems without license)
2. Physical-device performance receipt — operator
3. Optional presentation of landmark zones in WorldProjector (non-blocker)

Then P10 ten-city systemic projection (rule-level identity, not textures only).

## Constraints (non-negotiable)
- SurveillanceCore owns combat truth; SpriteKit projection only
- Deterministic seed reproducibility
- No hidden damage/health scaling
- Receipts never invent narrative events
- No city 11
- Emulator ≠ device; do not close #2/#3 from sim green
- merge-when-green squash; no force-push to main
- Inventory-first REUSE for art; no mock residents/LPR baked terrain; no system-sound audio

## Required gates before PR
make version-check
make audio-check weapon-vfx-check animation-check
make director-check city-state-check build-engine-check coordination-check story-check
make interactables-check landmark-check clearing-builds-check
make test
make emulator-test   # when presentation/app touched
# full: make validate

## Recommended first commit this session
If landmark + clearing builds already on main:
  - adaptive audio hooks (catalog only)
  - or start P10 rule projection scaffolding for one non-Wichita district
  - refresh CONTINUATION_PROMPT tip SHA after each merge

Then: commit branch, open PR, merge when green, refresh boards to tip.

## Stop conditions
- Do not regenerate audio without owner license
- Do not claim device acceptance from emulator
- Do not expand to ten-city systemic projection until P9 residual is acknowledged
```

---

## Execution notes

| Field | Value |
| --- | --- |
| Written for tip | `49fa13f` (+ landmark/clearing PR when merged) |
| First executable step | Adaptive audio hooks (catalog) or P10 scaffolding |
| Operator blockers | #3, device log, store, ElevenLabs |
