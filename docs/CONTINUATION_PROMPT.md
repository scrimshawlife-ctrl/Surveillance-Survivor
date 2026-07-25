# Continuation prompt — Surveillance Survivor

```yaml
version: 1.1.0
status: active
last_updated: 2026-07-25
tip_at_write: 52f8808
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
5. docs/P11_REPLAYABILITY.md · docs/P10_CITY_PROJECTION.md

## Tip reality
- main through #79 (presentation polish); P10 systems + offer bias done; P11 A–D + trail/floors/mutators on main
- Receipt schema v11 (challenge + upgrade offer bias)
- Ten cities projected; mastery store; Daily/Weekly challenges; presentation unlocks
- Adaptive audio catalog only (no stems without ElevenLabs license)
- Emulator ≠ device; #2/#3 not closed by sim green

## Dual lanes
### Launch (operator — do not fake)
- Device ART QA → close #3
- DEVICE_TEST_LOG for current tip SHA (include challenge/mastery if exercised)
- Store privacy/support URLs + ASC fields
- ElevenLabs license → Audio Batch 1 (never system-sound placeholders)
- TestFlight internal once device + store fields ready

### Systemic / polish (agent — prefer emulator-first)
P10–P11 engineering largely green. Prefer:
1. Launch-prep docs/checklists stay accurate after each merge
2. Optional P7 art (multi-frame guards, RF overlays) only with inventory-first REUSE
3. No city 11; no hidden damage/HP scaling

## Constraints
- SurveillanceCore owns combat truth
- No hidden damage/HP scaling; no invented receipt narrative
- No city 11; merge-when-green squash
- No audio stems without owner license

## Gates
make version-check audio-check weapon-vfx-check animation-check
make director-check city-state-check build-engine-check coordination-check story-check
make interactables-check landmark-check clearing-builds-check city-rules-check
make challenge-contracts-check unlockables-check sprite-chroma-check
make assets-check test
make emulator-test   # when presentation/app touched
```

---

## Execution notes

| Field | Value |
| --- | --- |
| Written for tip | `52f8808` (+ this PR when merged) |
| First executable step | Operator device QA OR board-hygiene / launch-prep only |
| Operator blockers | #3, device log, store, ElevenLabs |
