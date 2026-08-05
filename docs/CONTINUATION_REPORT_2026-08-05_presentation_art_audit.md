# Presentation / art audit — 2026-08-05

**Audit:** B (presentation / art)  
**Program:** post-merge audit program C→D→B→A  
**Depends on:** D isolation **PASS** (presentation may be judged as art/projection, not combat-truth risk)

## Tip freeze

- short: `7b3a517` (after D commit; re-read at B commit)
- branch: `main`
- product context: post-#156 UrbanDress + post-#159 341 prompted sprites

## Machine pack summary

| Check | Result |
| --- | --- |
| assets-check | **341** RuntimeSprites validated |
| Catalog parity | **341** imagesets; only_runtime=[] only_catalog=[]; **PASS** |
| weapon-vfx-check | PASS — 20 assets, 3 runtime roles, 6 weapons |
| animation-check | PASS — 27 clips, 16 non-missing statuses |
| art-qa-check | PASS package gate=ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES (audit JSON tip `0a2a627`, not HEAD) |

## Systems in scope (code presence)

| System | On main | Notes |
| --- | --- | --- |
| UrbanDress builder + projector layers | yes | roads/sidewalks/buildings/props |
| Satellite camera 1.38 | yes | `GameScene.satelliteCameraScale` |
| Terrain carpet 256 / full / nearest | yes | prompted ground readability |
| Pale asphalt for entity contrast | yes | WorldProjector district tints |
| Multi-frame VFX / animation banks | yes | probeLimit 16; 163 multi-frame families at integration |
| Reduced-flash / reduced-motion | **required in manifests** | doctrine + manifest flags; full device matrix not re-run this audit |

## Operator checklist

| Item | Device | Simulator | Result | Notes |
| --- | --- | --- | --- | --- |
| Player readable at combat range | blocked_no_device | not_run | blocked_no_device | Needs operator eyes on HEAD |
| Guards/boss distinct | blocked_no_device | not_run | blocked_no_device | Prompted set replaced stills |
| LPR cones / suspicion readable | blocked_no_device | not_run | blocked_no_device | |
| Projectiles / VFX multi-frame visible | blocked_no_device | not_run | blocked_no_device | Frames catalog-addressable |
| Blind Spot extract readable | blocked_no_device | not_run | blocked_no_device | Prior live extracts on older tips |
| UrbanDress streets/buildings legible | blocked_no_device | not_run | blocked_no_device | Prior smoke on urban tips pre-merge |
| Satellite zoom 1.38 combat OK | blocked_no_device | not_run | blocked_no_device | Operator pass recorded on older branch tip |
| Terrain carpet not featureless / not noisy | blocked_no_device | not_run | blocked_no_device | Machine wire-in complete |
| Pale ground entity contrast | blocked_no_device | not_run | blocked_no_device | Intent of #159 ground lift |
| Flash safety (telegraph/pulse) | blocked_no_device | not_run | blocked_no_device | Manifest requires reduced-flash |
| Reduced-motion / reduced-flash coverage gaps | blocked_no_device | not_run | not_run | Doctrine present; device matrix open |

**City sample:** not played this audit — operator should sample at least Wichita, Louisville, Tulsa + two dense cities (or full 10).

## ART approval tip match

- prior ship_gate: **ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES** (operator 2026-08-01)
- approval lineage tip in audit JSON: `0a2a627` / reason cites `7c400e7`–`d87be47` era
- freeze tip vs approval tip: **STALE** for HEAD after #156/#159
- recommendation: **re-attest on HEAD** before residual `art_ship` READY

## Presentation/art verdict

- Machine assets: **PASS**
- Isolation precondition (Audit D): **PASS**
- Ready for operator ART re-attest on freeze tip: **YES** (no machine asset defect blocking re-attest; device checklist still owed)

## Findings

| Severity | Claim | Evidence | Disposition |
| --- | --- | --- | --- |
| Medium | ART ship approval not tip-matched to HEAD | art_qa_audit.json commit `0a2a627` vs main after #156/#159 | Operator re-attest |
| Medium | No device checklist filled on HEAD this audit | blocked_no_device rows | Operator session |
| Info | Machine 341 parity + VFX/animation validators green | make assets/weapon-vfx/animation-check | Accept |
| Info | Prior urban device-smoke / live extracts on older tips | device_evidence, urban docs | Useful context; not HEAD freeze |

## Non-claims

- No art_ship READY promotion  
- No device pass invented  
- No combat balance change  
- No claim that reduced-flash variants were re-verified on device this session  
