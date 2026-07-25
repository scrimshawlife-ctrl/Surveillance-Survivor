# Continuation prompt — Surveillance Survivor

```yaml
version: 1.1.1
status: active
last_updated: 2026-07-25
tip_at_write: de0f632
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
6. docs/ART_QA_COMBAT_READABILITY_AUDIT.md (presentation hierarchy)

## Tip reality
- main through #82 (combat readability + PresentationQualityTier density)
- Receipt schema v11 (challenge + upgrade offer bias)
- Ten cities projected; mastery store; Daily/Weekly challenges; presentation unlocks
- Combat z-order / palette / density soft-out on existing projectors (no parallel render path)
- Adaptive audio catalog only (no stems without ElevenLabs license)
- Emulator ≠ device; #2/#3 not closed by sim green

## Dual lanes
### Launch (operator — do not fake)
- Device ART QA → close #3 (use checklist in ART_PRODUCTION_READINESS + combat-readability lines)
- DEVICE_TEST_LOG for tip de0f632 (include challenge/mastery + combat readability if exercised)
- Store privacy/support URLs + ASC fields (APP_STORE_METADATA.md OWNER rows)
- ElevenLabs license → Audio Batch 1 (never system-sound placeholders)
- TestFlight internal once device + store fields ready

### Systemic / polish (agent — prefer emulator-first)
P8–P11 engineering largely green. Prefer:
1. Launch-prep docs/checklists stay accurate after each merge
2. Optional P7 art (multi-frame guards, RF overlays) only with inventory-first REUSE
3. No city 11; no hidden damage/HP scaling
4. Reuse PresentationPipeline / PresentationQualityTier / VisualAssetMap / CombatLimits — do not invent parallel presentation systems

## Constraints
- SurveillanceCore owns combat truth
- No hidden damage/HP scaling; no invented receipt narrative
- No city 11; merge-when-green squash (or squash after green if auto-merge disabled)
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
| Written for tip | `de0f632` (#82) |
| First executable step | Operator device QA **or** owner store/audio fields |
| Operator blockers | #3, device log, store URLs, ElevenLabs |
