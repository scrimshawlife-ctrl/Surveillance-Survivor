# Continuation prompt — Surveillance Survivor

```yaml
version: 1.1.2
status: active
last_updated: 2026-07-25
tip_at_write: a8ba94c
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
5. docs/RELEASE_READINESS.md · docs/APP_STORE_METADATA.md
6. docs/ART_QA_PERCEPTION_AUDIT.md · docs/art_qa/art_qa_audit.json

## Tip reality
- main through #85 (status rings, flood teal, Art QA package, optional frame probe)
- ship_gate ART_EVIDENCE_INSUFFICIENT until tip-matched device ART QA
- Receipt schema v11; P10/P11 systems live; 10 cities; mastery + challenges
- Adaptive audio catalog only (no stems without ElevenLabs license)
- Emulator ≠ device; #2/#3 not closed by sim green
- Guard multi-frame: OptionalSpriteFrameCycle probe wired; still inventory only

## Dual lanes
### Launch (operator — do not fake)
- DEVICE_TEST_LOG + ART_DEVICE_QA_CHECKLIST for current tip SHA
- Store privacy/support URLs + ASC fields
- ElevenLabs license → Audio Batch 1 (never system-sound placeholders)
- TestFlight once device + store fields ready

### Agent (prefer inventory-first)
1. Keep boards current after merges
2. No city 11; no hidden damage/HP scaling
3. Reuse PresentationPipeline / PresentationQualityTier / VisualAssetMap / OptionalSpriteFrameCycle
4. Do not invent guard multi-frame PNGs — attach inventory then probe auto-cycles
5. Optional P7 art only with REUSE matrix

## Constraints
- SurveillanceCore owns combat truth
- No audio stems without owner license
- Squash merge after CI green

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
| Written for tip | `a8ba94c` (+ guard probe PR when merged) |
| First executable step | **Operator device QA** (agent lane largely exhausted without art/device) |
| Operator blockers | #3, device log, store URLs, ElevenLabs |
