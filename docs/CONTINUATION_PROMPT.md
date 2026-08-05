# Continuation prompt — Surveillance Survivor

```yaml
version: 1.3.1
status: active
last_updated: 2026-08-05
tip_at_write: re-read HEAD
board_tip: ee8a95a
implementation_tip_device: f2406fc
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

## Tip reality (2026-08-05)
- re-read `git rev-parse --short HEAD` before acting
- Board tip at write: ee8a95a (#158 hygiene on #157 prompts); device residual tip: f2406fc
- Dynamic stick at press: 44a204f; #153 playability on main
- Open PRs: #155 Prabu suspend (CI green); #156 urban arena (baseline refresh owed); #159 prompted sprites
- Urban lane worktree: `.worktrees/feat/urban-arena-presentation` @ 17117b1 — not on main until #156 merges
- #148 rights package on main — make audio-rights-check expected BLOCKED until private evidence
- Mechanical device PASS + live Louisville on f2406fc; Tulsa extract on 44a204f; suite logs under docs/device_evidence/run_logs/
- Non-device baseline on tip: 273 package / 417 simulator / 14 UI (#155 → 418)
- ship_gate ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES (operator 2026-08-01)
- LAUNCH_BLOCKED until store + audio product (+ tip-matched launch READY)
- Gameplay: splash → start menu → dynamic stick anywhere; predictive auto-fire;
  stationary LPR cones; Suspicion; paced drafts (optional repair); authority →
  Blind Spot compass → extract
- No mid-run coin shop; no system-sound audio; emulator ≠ device
- Collaboration: topic branches off main; do not resume agent/prabu-openclaw

## Dual lanes
### Launch (operator/owner — do not fake)
1. store OWNER live URLs + screenshots (NEXT primary)
2. audio rights ledger evidence + physical-device listening notes
3. optional tip-match launch READY at frozen ship SHA
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
| First step | Owner store URLs + audio rights ledger |
