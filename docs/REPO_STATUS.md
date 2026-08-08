# Repository status audit

**As of:** 2026-08-07  
**`main` tip:** re-read `git rev-parse --short HEAD`. Board tracks open visual remediation **#161** (CI green, merge-ready). Sprites **365**. Package ~273 / sim ~448 / UI 14 (re-read HEAD).  
**App version:** `0.1.0` build `1`  
**Plan:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) · **Workflow:** `/continue-ss`  
**Audit:** [`CONTINUATION_REPORT_2026-08-04_prabu_hygiene.md`](CONTINUATION_REPORT_2026-08-04_prabu_hygiene.md)  
**Device:** [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md) · [`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md) · [`device_evidence/`](device_evidence/)  
**Launch packet:** [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) · residual: [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md)

---

## Worktrees / concurrent lanes

| Lane | Path / branch | Tip | Status |
| --- | --- | --- | --- |
| **Primary / ship residual** | checkout `main` | re-read HEAD | #156–#160 on main; residual closeout **human-gated** (ART re-attest after #161) |
| **Visual remediation** | `fix/visual-p0-wrong-subject-and-empty-gate` | `0a6aa76` | [#161](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/161) CI green · MERGEABLE |
| Urban / sprite worktrees | removed 2026-08-05 | — | Merged #156/#159 trees pruned after integration |

**Rule:** one branch + one worktree per active change. Do not force-push collaborator branches.

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| [#161](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/161) | **Visual P0/P1/P2 remediation + empty-content CI gate** — wrong-subject landmarks (Louisville/NYC), Tulsa wiped haze, LPR baked-beam strip, magenta residual zero, Oakland crane, combat pixel pass; `sprite-content-check` pure stdlib. **CI green · merge-ready.** |

## Recently merged

| PR | Title |
| ---: | --- |
| [#160](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/160) | Batch 6 enemy walk + clip/effect integration (Prabu) |
| [#159](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/159) | Wire prompted sprite set, weapon VFX, animation frames (341 PNGs + catalog) |
| [#156](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/156) | Urban arena dress, satellite zoom, larger maps |
| [#155](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/155) | Cover that suspended playback stays suspended (Prabu) |
| [#158](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/158) | Prabu work audit and board hygiene |
| [#157](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/157) | Sprite generation prompts: 194 sprites + weapon VFX + animation clips (Prabu) |
| [#154](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/154) | TestFlight RC residual closeout docs |
| [#153](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/153) | integrate playability stack (hardening + #149 + #150) |
| [#152](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/152) | lifecycle/audio/save hardening (via #153) |
| [#150](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/150) | Blind Spot wayfinding + HUD (Prabu; via #153) |
| [#149](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/149) | integrity recovery + draft pacing (Prabu; via #153) |
| [#151](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/151) | Claude Code read-only command allowlist (Prabu) |
| [#148](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/148) | audio rights chain-of-title package + fail-closed validator |
| [#147](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/147) | post-gameplay docs reconcile and QA baseline |
| [#145](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/145) | make the game playable: combat, input, escalation, and a title screen (Prabu) |
| [#146](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/146) | fix PR #145 CI compilation, trim JSON churn, and refresh QA counts |

## Phase snapshot

| Phase | Status |
| --- | --- |
| P2 device | Full mechanical suite **PASS** + live Louisville on `f2406fc`; residual: re-freeze to **HEAD** for READY, ART re-attest (new art tip), listening |
| P3 ART | **`ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES`** (operator 2026-08-01 on older tip) — **re-attest owed** after #156/#159/#160/#161 art tips |
| P4 audio | 68/68 integrated; ledger **scaffolded**; `audio-rights-check` **BLOCKED**; #155 suspend on main |
| P5 store | Privacy/support **live**; SKU **SS-IOS-001** + Action; 6 sim screenshot candidates; copyright + physical accept open |
| P6 TF | Blocked on priors READY |
| Presentation | UrbanDress + satellite 1.38 (#156); prompted art (#159); **#160** walk/clips/effects; **#161** identity/empty-gate remediation (open) |
| Input | **Dynamic stick** (`44a204f`) |
| Playability | #145 + #153 |
| Non-device QA | **273** package / **448** simulator-hosted / **14** UI |
| Assets | `assets-check` **365** PNGs + **empty-content gate** (`sprite-content-check`); animation-check PASS; weapon-vfx PASS |
| Open PRs | **#161** (visual remediation; CI green) |

## Suggested next (engineering todo)

### Now (merge + honesty)

1. **Merge [#161](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/161)** visual remediation when owner is ready (CI green).
2. **Operator ART re-attest on post-merge HEAD** — [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) · [`OPERATOR_ART_REATTEST_2026-08-05.md`](OPERATOR_ART_REATTEST_2026-08-05.md) (covers #156/#159/#160/#161).
3. **Device tip-match READY** — re-freeze mechanical + live extract to HEAD; [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md).

### Soon (P7 polish / optional)

4. Player walk **wardrobe/outfit** regen (feet locked; uniform 414×596 with `player_damage_*`).
5. High-density scan-cone alpha (G-07) if cone wash returns on device — presentation only.
6. Combat still art-director pass if flat code-pixel read is too sparse mid-fight.

### Owner / launch residual

7. Copyright + store screenshots; audio rights residual (`make audio-rights-check`).
8. Physical-device audio listening acceptance.

### Done recently (do not re-open)

- G-01 parenting · G-02 carpet α · G-03 feet normalize
- Level-audit **P0** wrong-subject landmarks + wiped Tulsa haze + LPR baked beams (#161)
- Empty/wiped **sprite-content-check** CI gate (stdlib, no Pillow)
- Magenta residual under transparent zeroed on known plate leftovers

```bash
# Honesty
make launch-gate-check art-qa-check repo-status-check release-docs-check assets-check sprite-content-check

# Mechanical re-check after art/presentation tip:
DEVELOPMENT_TEAM=X9M969D8M3 make device-test
DEVELOPMENT_TEAM=X9M969D8M3 make device-accept
DEVELOPMENT_TEAM=X9M969D8M3 make launch-smoke
```

## Hygiene snapshot (2026-08-05 post-merge)

| Area | State |
| --- | --- |
| Open PRs | **1** (#161) |
| `main` | `e73a14b` (audit program + art tip parent bdf78cc) |
| Assets | 341 RuntimeSprites = 341 imagesets |
| Launch overall | **LAUNCH_BLOCKED** (honest) |

### Safe remote deletes (merged into `main`) — **already deleted 2026-08-05**; list retained as historical

```text
origin/art/prompted-sprite-refresh          #159
origin/feat/urban-arena-presentation        #156
origin/mechanics/audio-session              #155
origin/chore/permission-allowlist           #151
origin/docs/audio-rights-package            #148
origin/docs/tf-rc-residual-closeout         #154
origin/feat/blind-spot-wayfinding           #150
origin/feat/integrity-and-draft-pacing      #149
origin/jcode/integrate-prabu-playability    #153
origin/jcode/lifecycle-audio-save-hardening #152
origin/fix/automation-tests-push-trigger
origin/agent/audio-batch1-runtime-bank
origin/agent/iphone-bootstrap
origin/agent/prabu-openclaw
origin/agent/wp2b-disabled-sensor-freeze
origin/codex/debug-hardening-presentation-regression
origin/cursor/versioning-closure-a2c8
```

## Latest increments (2026-08-05)

- **Hygiene:** deleted `origin/prabu/animation-integration-and-isolation`; removed merged urban/sprite worktrees
- **#160 merged:** Batch 6 enemy walk + clip/effect integration; baseline **448**; sprites **365**; no SKPhysics
- **Prabu handoff** largely closed by #160
- Post-merge audits C→D→B→A executed
- **#159 / #156 / #155** on main (art, urban, audio suspend)


## Art ship gate

| Field | Value |
| --- | --- |
| `ship_gate` | **ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES** (operator 2026-08-01; pre-#156/#159 tip) |
| Check | `make art-qa-check` |
| Note | Re-attest recommended on `bdf78cc` before treating launch art_ship as tip-matched |

## Launch gates (machine)

| Field | Value |
| --- | --- |
| Overall | **LAUNCH_BLOCKED** |
| Check | `make launch-gate-check` |
| Manifest | [`launch/launch_gates.json`](launch/launch_gates.json) |
| Agent playbook | [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) |

| Gate | Status | Tip / note |
| --- | --- | --- |
| device_acceptance | EVIDENCE_INSUFFICIENT | `f2406fc` — mechanical + live extracts; not READY; not tip-matched to HEAD |
| art_ship | EVIDENCE_INSUFFICIENT | art_qa approved w/ notes on older tip; READY needs re-attest + tip-match + device_acceptance READY |
| store_metadata | EVIDENCE_INSUFFICIENT | URLs + SKU + sim screenshots; not READY |
| audio_product | BLOCKED | pending_evidence scaffold; rights + listening |
| testflight_rc | BLOCKED | shared |

*Statuses must match `launch_gates.json`. Checker exit 0 means honest, not ship-ready.*

## Latest increments (2026-08-07)

- **#161 (open, CI green):** visual P0/P1/P2 remediation — Louisville twin spires, NYC scaffold shed, Tulsa refinery haze, LPR beam strip, plate residual zero, Oakland crane, combat pixel pass; `make sprite-content-check` / empty-content gate in `assets-check` (pure stdlib). Receipts: [`art/VISUAL_P0_REMEDIATION_2026-08-07.md`](art/VISUAL_P0_REMEDIATION_2026-08-07.md), [`art/VISUAL_P2_REMEDIATION_2026-08-07.md`](art/VISUAL_P2_REMEDIATION_2026-08-07.md).
- **Docs refresh:** README sprite baseline **365**, validation commands, frontiers; ROADMAP/CONTINUATION_PLAN board tip; this file open-PR + todo.

