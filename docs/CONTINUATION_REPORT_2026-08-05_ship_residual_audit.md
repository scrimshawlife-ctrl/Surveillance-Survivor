# Ship residual audit — 2026-08-05

**Audit:** A (post-merge ship residual)  
**Program:** post-merge audit program C→D→B→A  
**Authority:** `docs/launch/TESTFLIGHT_RC_RESIDUAL.md`, `docs/launch/launch_gates.json`, `docs/launch/AGENT_LAUNCH_PLAYBOOK.md`

## Tip freeze

- product art tip parent: `bdf78cc` (#159 merge)
- program docs tip: re-read HEAD after A commit
- branch: `main`

## Machine honesty (launch)

```text
device_acceptance: EVIDENCE_INSUFFICIENT tip=f2406fc
art_ship: EVIDENCE_INSUFFICIENT tip=d87be47
store_metadata: EVIDENCE_INSUFFICIENT tip=08042d1
audio_product: BLOCKED tip=None
testflight_rc: BLOCKED tip=None
launch-gate-check: PASS overall=LAUNCH_BLOCKED
```

## Import prior audits

### C — Hygiene
- Open PRs/issues: **none**
- Merged remotes: **clean** (prior deletes held)
- Board open-PR claims: **honest**
- Tip field lags HEAD (ancestor check still PASS)
- Worktrees for merged #156/#159 still present (optional remove)
- 20 unmerged historical remotes remain

### D — Architecture isolation
- Core owns combat truth: **PASS**
- No SKPhysics combat path
- UrbanDress pure; frames presentation-only
- #156 scale/perimeter is **sim content** (intentional)

### B — Presentation / art
- Machine assets **PASS** (341 parity; weapon-vfx; animation)
- ART approval **STALE** vs HEAD → re-attest owed
- Device checklist **blocked_no_device** this session
- Ready for operator re-attest: **YES** (no machine blocker)

## Gate scoreboard

| Gate | Machine status | Tip / note | Blocker | Owner |
| --- | --- | --- | --- | --- |
| device_acceptance | EVIDENCE_INSUFFICIENT | f2406fc mechanical + live extracts | Not tip-matched to HEAD; residual re-freeze + suite policy | Operator / residual playbook |
| art_ship | EVIDENCE_INSUFFICIENT | d87be47 / package approved older tip | Re-attest on HEAD after #156/#159; tip-match READY rules | Operator |
| store_metadata | EVIDENCE_INSUFFICIENT | 08042d1 sim screenshots + live URLs/SKU | Copyright confirm; physical/release accept or recapture | Owner |
| audio_product | BLOCKED | ledger scaffold pending_evidence | Private verified rights + listening notes | Owner |
| testflight_rc | BLOCKED | shared | All priors READY | Shared |
| **Overall** | **LAUNCH_BLOCKED** | HEAD | List L below | Shared |

## Evidence vs HEAD

| Evidence | Tip | Valid for HEAD freeze? |
| --- | --- | --- |
| Mechanical suite PASS | f2406fc / 7c400e7 | **No** for tip-matched READY without re-suite or residual policy exception |
| Live Louisville extract | f2406fc / 7c400e7 | Historical; re-validate if freeze ≠ those tips |
| Live Tulsa extract | 44a204f | Historical stick path |
| Urban device-smoke / live notes | pre-merge urban tips | Context only until HEAD device glance |
| Prompted sprites + UrbanDress on main | bdf78cc+ | **Yes** as product content; still needs ART re-attest |
| Sim store screenshots | 08042d1 pack | Partial; owner accept / physical prefer |
| Audio rights ledger | scaffold | **No** until verified private evidence |

## Go / no-go

- **Freeze ship SHA at HEAD now for READY path?** **NO** (default) — residual list L open  
- **RC cut allowed?** only when all gates READY (not claimed)  
- **Upload?** never claimed by this audit  

## List L — blockers before residual freeze READY path

1. Operator: ART re-attest on HEAD (UrbanDress + prompted sprites + terrain carpet + flash)  
2. Operator: device residual policy — re-suite mechanical and/or re-freeze with tip-match rules  
3. Owner: copyright confirm + screenshot accept (or physical recapture)  
4. Owner: private audio rights evidence → `audio-rights-check` PASS + listening notes  
5. Shared: only then tip-match promote device_acceptance / art_ship / store / audio / testflight_rc per playbook  
6. Optional hygiene: remove merged worktrees; prune local `:gone` branches; refresh board tip text  

## Ordered next

1. **Operator:** ART re-attest session on HEAD using ART checklist  
2. **Operator:** decide residual freeze tip + mechanical re-suite if binary presentation moved (it did)  
3. **Owner:** store + rights residual  
4. **Agent:** board tip refresh after this program; promote READY **only** when residual criteria met — never invent  

## Non-claims

- No gate READY invented  
- RC cut allowed ≠ upload  
- Rights scaffold ≠ PASS  
- Pre-#156/#159 ART approval ≠ tip-matched HEAD  
- Isolation PASS ≠ ship-ready  
