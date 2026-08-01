# Continuation prompt — Surveillance Survivor

```yaml
version: 1.3.0
status: active
last_updated: 2026-08-01
tip_at_write: re-read HEAD
implementation_tip_device: 44a204f
workflow: continue-ss
```

## Preferred: run the workflow

```text
/continue-ss
# or with lane:
# workflow continue-ss with args #{ lane: "launch" | "agent" | "audit" }
```

Workflow path: `.grok/workflows/continue-ss.rhai`  
Plan authority: [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md)  
Board: [`REPO_STATUS.md`](REPO_STATUS.md)

---

## Prompt (paste if not using workflow)

```text
You are continuing Surveillance Survivor at:
  /Users/appliedalchemylabs/Documents/Surveillance-Survivor

## Authority (read first)
1. AGENTS.md
2. docs/CONTINUATION_PLAN.md
3. docs/REPO_STATUS.md
4. docs/OPERATOR_PHONE_SESSION.md
5. docs/LAUNCH_OPERATOR_PACKET.md
6. docs/launch/launch_gates.json
7. docs/launch/AGENT_LAUNCH_PLAYBOOK.md
8. docs/device_evidence/ (live extract summaries)
9. docs/ART_DEVICE_QA_CHECKLIST.md
10. docs/RELEASE_READINESS.md · docs/APP_STORE_METADATA.md
11. docs/audio/rights/README.md
12. docs/WEAPON_SYSTEM_DESIGN.md (cameras → shards → upgrade draft, not coin shop)

## Tip reality (2026-08-01)
- re-read `git rev-parse --short HEAD` before acting
- Implementation tip for device evidence: 44a204f (dynamic stick at press)
- #153 playability on main: repairs, draft pacing, Blind Spot compass, HUD
- #148 rights package on main — make audio-rights-check expected BLOCKED until private evidence
- Mechanical device PASS on 7c400e7; live extracts Louisville (7c400e7) + Tulsa (44a204f) filed
- Non-device baseline: 273 package / 416 simulator / 14 UI
- ship_gate ART_EVIDENCE_INSUFFICIENT until ART checklist ship call
- LAUNCH_BLOCKED until ART + store + audio product (extracts alone do not READY)
- Gameplay: splash → start menu → dynamic stick anywhere; predictive auto-fire;
  stationary LPR cones; Suspicion; paced drafts (optional repair); authority →
  Blind Spot compass → extract
- No mid-run coin shop; no system-sound audio; emulator ≠ device

## Dual lanes
### Launch (operator/owner — do not fake)
1. ART_DEVICE_QA_CHECKLIST pass/fail for current binary tip (NEXT operator step)
2. store OWNER live URLs + screenshots
3. audio rights ledger evidence + physical-device listening notes
4. TestFlight only when launch gates READY

### Agent
- Board hygiene; inventory-first presentation; tokenized UI chrome only
- make art-qa-check honesty; never invent ART_SHIP_APPROVED
- make launch-gate-check honesty; never invent READY
- make audio-rights-check honesty; never invent cleared rights
- No city 11; no hidden damage/HP scaling

## Gates
make launch-gate-check art-qa-check repo-status-check release-docs-check
make audio-check assets-check test
# make audio-rights-check  # expect BLOCKED until evidence
make emulator-test when App/Game presentation touched
```

| Field | Value |
| --- | --- |
| Tip | re-read `git rev-parse --short HEAD` |
| Device evidence tip | `44a204f` (+ prior `7c400e7`) |
| First step | Operator ART checklist · or owner store/rights offline |
