# Graphics & playability field audit — 2026-08-05

**Audit:** dual-lane field (G graphics + P playability)  
**Trigger:** Partner secondhand — “game looks fucked up” (no symptom taxonomy)  
**Design:** [`docs/superpowers/specs/2026-08-05-graphics-playability-field-audit-design.md`](superpowers/specs/2026-08-05-graphics-playability-field-audit-design.md)  
**Plan:** [`docs/superpowers/plans/2026-08-05-graphics-playability-field-audit.md`](superpowers/plans/2026-08-05-graphics-playability-field-audit.md)

## Tip freeze

- full: `25e2ddef9c35bdacab3ea7c91a73fca821820507` (design commit present; product tip includes #160)
- short: `25e2dde` at machine pack (re-read after this report commits)
- branch: `main`
- status: plan file untracked at pack start
- frozen_at_utc: `2026-08-05T23:23:36Z`
- platform: **code + machine + doc evidence** (device/sim play **not run** this session — weaker on “feel”)

## Machine pack summary

| Check | Result |
| --- | --- |
| version-check | OK 0.1.0+1 |
| repo-status-check | PASS (ancestor) |
| launch-gate-check | PASS overall=**LAUNCH_BLOCKED** |
| art-qa-check | PASS package; ship_gate ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES @ **stale** commit `0a2a627` |
| assets-check | **365** RuntimeSprites |
| animation-check | PASS — 28 clips, 26 non-missing |
| weapon-vfx-check | PASS — 20 assets, 6 runtime roles |

Gates: device_acceptance `f2406fc` EVIDENCE_INSUFFICIENT · art_ship `d87be47` EVIDENCE_INSUFFICIENT · store/audio/testflight blocked as before.

## Known-risk checklist

| Risk | Status | Notes |
| --- | --- | --- |
| ART approval not tip-matched to HEAD | **confirmed** | art_qa JSON still `0a2a627` |
| Full terrain carpet density (256, α 0.88) | **confirmed (code)** | `WorldProjector.renderGround` + `coverage: .full` |
| Terrain stamps parented to wrong node | **confirmed (code) S1** | see G-01 |
| Player walk wardrobe / height shimmer | **confirmed (docs)** | Batch 6 receipt: frame1 ~485px vs ~340px others, multi-outfit |
| Walk banks 4f vs target [6,10] | **confirmed (docs/manifest)** | guards/boss/player shortfall |
| FX sizes by eye (72–220 wu) | **confirmed (docs)** | Batch 6 receipt; not device-tuned |
| Satellite camera 1.38 | **code present** | `GameScene.satelliteCameraScale`; device OK only on older tip |
| 1.5× arenas + perimeter margin | **code present** | larger empty ring + more tile stamps |
| Transient FX layer noise | **possible** | #160; not play-observed this session |
| SKPhysics combat | **not present** | isolation still clean |
| Softlock / broken stick | **not tested** | play session blocked |

## Session log

| City | Platform | Duration | Notes |
| --- | --- | --- | --- |
| — | device | blocked_no_device | No physical session this run |
| — | simulator | not_run | Code audit prioritized after G-01 discovery |

Partner complaint treated as **secondhand**; highest-confidence defect is **code-proven** parenting bug (G-01), not a guess.

## Findings

| ID | Lane | Sev | Symptom | Repro / evidence | Likely system | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| **G-01** | G | **S1** | Sidewalks / curb paint may vanish under nearly opaque terrain carpet; layer stack “fucked”; possible z-fight / visual chaos | `stampTerrainLayer` `.full` does `root.addChild(node)` instead of `parent.addChild(node)` at `WorldProjector.swift` ~613; `.edgeAccents` correctly uses `parent`. `renderGround` passes `into: ground`. | WorldProjector terrain carpet (#159 merge with UrbanDress) | **fix presentation** — parent stamps to `parent`; add regression test that urban-ground owns full-coverage tiles |
| **G-02** | G | **S1** | Floor busy / noisy / “wallpaper” at combat scale | Full carpet α **0.88**, baseSize 256, step 0.98 over **1.5×** bounds + perimeter margin → huge tile counts | WorldProjector + district scale | Tune α/coverage after G-01; optional sparse mid-field if still busy |
| **G-03** | G | **S1** | Player “pops” / changes outfit while walking | Batch 6 receipt: independent illustrations, height ~485 vs ~340 | Player walk banks (#159) | Regenerate consistent walk sheets; feet lock |
| **G-04** | G | **S2** | Short choppy walks (guards/boss/player) | 4 frames vs target [6,10] | Animation banks | Optional denser banks (Prabu residual) |
| **G-05** | G | **S2** | FX blobs too large / flashy / mis-layered | Sizes 72–220 wu; ground vs overlay depths | TransientEffectProjector | Device-tune after G-01; reduced-flash |
| **G-06** | G | **S2** | Zoomed-out combat hard to read | camera scale 1.38 permanent | GameScene | Device confirm; maybe scale knob later |
| **P-01** | P | **S2** | Combat may *feel* worse if visuals bury cones/entities | Depends G-01/G-02/G-05 | Presentation obscuring play info | Fix G first; retest play |
| **P-02** | P | **S?** | Softlock / stick / unfair death | **not tested** | unknown | Device/sim play session required |
| **P-03** | P | **S2** | Possible hitch from tile node explosion | Full carpet over large bounds | WorldProjector perf | Profile after G-01; pool/cull if needed |

## Partner-facing top 5 (plain language)

1. **Broken ground layering (G-01)** — street tiles are attached to the wrong parent, so sidewalks and paint can get buried under the floor texture. This alone can make the arena look “destroyed” or wrong.  
2. **Very busy floor (G-02)** — after #159 the whole arena is carpeted with nearly solid tiles on a bigger map.  
3. **Player walk looks glitchy (G-03)** — walk frames don’t match each other (size/outfit), so the character hops and changes clothes.  
4. **Zoomed-out view (G-06)** — camera is permanently pulled back; everything is smaller.  
5. **New effects may pile on (G-05)** — telegraphs/impacts/fields just wired in #160; sizes not device-tuned.

Playability is **not cleared** — no live session this run. First fix graphics layering, then re-play.

## Ranked fix order

1. **G-01** — `parent.addChild` for `.full` terrain + unit test (small, high impact)  
2. **G-03** — player walk bank consistency (art)  
3. **G-02** — carpet density/α after parenting fixed  
4. **Device/sim field re-pass** (this checklist with eyes) → fill P-02  
5. **G-05 / G-04 / G-06** tune as needed  

## Recommended next

| Owner | Action |
| --- | --- |
| **Agent** | Implement G-01 fix + regression test (separate focused PR) |
| **Operator** | Device play after G-01: re-run dual checklist; ART re-attest |
| **Prabu / art** | G-03 player walk regeneration; optional denser walks |
| **Owner** | Residual store/rights unchanged (still LAUNCH_BLOCKED) |

## Isolation note

No SKPhysics combat path. G-01 is pure presentation parenting. Do not “fix” feel with physics bodies.

## Non-claims

- No READY / art_ship tip-match / store / rights clearance  
- No full device or simulator play session this audit  
- Partner words not reproduced live — code defect still **actionable**  
- No mass art regen performed  

## Method limits

This run is **strong on code-proven G-01**, **medium on documented art risks**, **weak on live playability**. A follow-up device pass should update findings P-02 and severity of G-02/G-05.
