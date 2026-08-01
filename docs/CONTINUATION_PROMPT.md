# Continuation prompt — Surveillance Survivor

```yaml
version: 1.2.2
status: active
last_updated: 2026-08-01
tip_at_write: re-read HEAD
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
3. docs/OPERATOR_PHONE_SESSION.md
4. docs/LAUNCH_OPERATOR_PACKET.md
5. docs/launch/launch_gates.json
6. docs/launch/AGENT_LAUNCH_PLAYBOOK.md
7. docs/REPO_STATUS.md
8. docs/ROADMAP.md · docs/RELEASE_READINESS.md
9. docs/ART_QA_PERCEPTION_AUDIT.md · docs/art_qa/art_qa_audit.json
10. docs/WEAPON_SYSTEM_DESIGN.md  (cameras → shards → upgrade draft, not coin shop)
11. docs/audio/rights/README.md  (fail-closed rights; make audio-rights-check)

## Tip reality
- re-read `git rev-parse --short HEAD` before acting
- #153 playability on main: integrity repair drafts, draft pacing, Blind Spot compass, HUD polish, lifecycle/audio/save harden
- #148 rights package on main — audio-rights-check expected BLOCKED until private evidence
- #151 Claude allowlist on main (agent ergonomics)
- Non-device baseline: 273 package / 416 simulator / 14 UI
- ship_gate ART_EVIDENCE_INSUFFICIENT until tip-matched device ART
- LAUNCH_BLOCKED until device + ART + store + audio product
- Gameplay: splash → start menu → analog move; predictive auto-fire; stationary LPR cones; Suspicion; paced drafts (optional repair); authority → Blind Spot compass → extract
- No mid-run coin shop; no system-sound audio; emulator ≠ device

## Dual lanes
### Launch (operator/owner — do not fake)
docs/OPERATOR_PHONE_SESSION.md then LAUNCH_OPERATOR_PACKET:
1. device-smoke / device-test / device-accept / launch-smoke on current tip
2. ART_DEVICE_QA_CHECKLIST + DEVICE_TEST_LOG live extract
3. store OWNER URLs + screenshots
4. Audio rights ledger evidence + physical-device listening
5. TestFlight when unblocked

### Agent
- Board hygiene; inventory-first presentation; tokenized UI chrome only
- make art-qa-check honesty; never invent ART_SHIP_APPROVED
- make launch-gate-check honesty; never invent READY
- make audio-rights-check honesty; never invent cleared rights
- No city 11; no hidden damage/HP scaling

## Gates
make launch-gate-check art-qa-check assets-check animation-check weapon-vfx-check test
make audio-check
# make audio-rights-check  # expect BLOCKED until evidence
make emulator-test when App/Game touched
```

| Field | Value |
| --- | --- |
| Tip | re-read `git rev-parse --short HEAD` |
| First step | Phone attached → `OPERATOR_PHONE_SESSION.md`; else owner store/rights offline |
