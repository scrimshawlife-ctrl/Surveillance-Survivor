# Continuation prompt — Surveillance Survivor

```yaml
version: 1.2.0
status: active
last_updated: 2026-07-25
tip_at_write: c379ef2
workflow: continue-ss
```

## Preferred: run the workflow

```text
/continue-ss
# or with lane:
# workflow continue-ss with args #{ lane: "audit" }
```

Workflow path: `.grok/workflows/continue-ss.rhai`  
Plan authority: [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md)

---

## Prompt (paste if not using workflow)

```text
You are continuing Surveillance Survivor at:
  /Users/appliedalchemylabs/Documents/Surveillance-Survivor

## Authority (read first)
1. AGENTS.md
2. docs/CONTINUATION_PLAN.md
3. docs/LAUNCH_OPERATOR_PACKET.md
4. docs/launch/launch_gates.json
5. docs/launch/AGENT_LAUNCH_PLAYBOOK.md
6. docs/REPO_STATUS.md
7. docs/ROADMAP.md · docs/RELEASE_READINESS.md
8. docs/ART_QA_PERCEPTION_AUDIT.md · docs/art_qa/art_qa_audit.json
9. docs/HALLMARK_HUD_AUDIT.md
10. docs/WEAPON_SYSTEM_DESIGN.md  (cameras → shards → upgrade draft, not coin shop)

## Tip reality
- main through #88 compact HUD + fullscreen; #89 settings aesthetic may be open
- ship_gate ART_EVIDENCE_INSUFFICIENT until tip-matched device ART
- P8–P11 systems live; presentation polish advanced
- Gameplay: stationary LPR scan cones; destroy cameras → Data Shards + 3-choice upgrade; boss → Blind Spot
- No mid-run coin shop; no system-sound audio; emulator ≠ device

## Dual lanes
### Launch (operator/owner — do not fake)
docs/LAUNCH_OPERATOR_PACKET.md:
1. device-smoke (done recently — not acceptance)
2. ART_DEVICE_QA_CHECKLIST + DEVICE_TEST_LOG extract
3. store OWNER URLs + screenshots
4. ElevenLabs → audio Batch 1
5. TestFlight when unblocked

### Agent
- Board hygiene; inventory-first presentation; tokenized UI chrome only
- make art-qa-check honesty; never invent ART_SHIP_APPROVED
- make launch-gate-check honesty; demote stale READY after tip moves; never invent READY
- No city 11; no hidden damage/HP scaling

## Gates
make launch-gate-check art-qa-check assets-check animation-check weapon-vfx-check test
make emulator-test when App/Game touched
```

| Field | Value |
| --- | --- |
| Tip | re-read `git rev-parse --short HEAD` |
| First step | `/continue-ss` or operator packet step 2 |
