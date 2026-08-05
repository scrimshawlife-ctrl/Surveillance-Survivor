# Continuation prompt — Surveillance Survivor

```yaml
version: 1.3.2
status: active
last_updated: 2026-08-05
tip_at_write: re-read HEAD
board_tip: 8818fc6
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
- Board tip at write: 8818fc6 (#159 prompted sprites + #156 urban arena)
- Device residual tip: f2406fc (mechanical + Louisville live; not tip-matched to HEAD)
- Open PRs: none (#160 animation integration merged)
- Post-merge audits C–A filed 2026-08-05 (docs/audits/README.md)
- #160: enemy walks + clips + TransientEffectProjector; isolation grep clean; no READY claim
- Assets: 365 RuntimeSprites; animation-check PASS; weapon-vfx PASS
- Presentation: UrbanDress + satellite 1.38 + prompted art + wired multi-frame banks
- Dynamic stick: 44a204f; playability #153; audio suspend #155
- Non-device baseline: 273 package / 447 simulator / 14 UI
- ship_gate ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES (operator 2026-08-01) — re-attest owed after #160
- LAUNCH_BLOCKED until store + audio product (+ tip-matched launch READY)
- Gameplay: splash → start menu → dynamic stick; predictive auto-fire;
  stationary LPR cones; Suspicion; paced drafts; authority → Blind Spot compass → extract
- No mid-run coin shop; no system-sound audio; emulator ≠ device
- Collaboration: topic branches off main; do not resume agent/prabu-openclaw

## Dual lanes
### Launch (operator/owner — do not fake)
1. ART re-attest on current HEAD (urban + prompted sprites)
2. store OWNER live URLs + screenshots
3. audio rights ledger evidence + physical-device listening notes
4. freeze ship SHA; optional tip-match launch READY
5. TestFlight only when launch gates READY

### Agent (while launch waits)
1. Board hygiene after real evidence
2. Do not invent READY / rights / store clearance
3. Prefer small focused changes with tests
```
