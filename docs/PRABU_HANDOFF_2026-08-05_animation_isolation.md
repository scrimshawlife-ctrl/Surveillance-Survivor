# Prabu handoff — combat isolation + remaining animation

**Date:** 2026-08-05  
**Tip base:** `origin/main` (re-read `git rev-parse --short HEAD` after fetch)  
**Owner:** Prabu  
**From:** post-merge audits C–A + isolation Q&A  

Open **one** topic branch off current `main` (see [`COLLABORATION.md`](COLLABORATION.md)).  
Do **not** resume `agent/prabu-openclaw`.

```bash
git fetch origin
git worktree add -b prabu/animation-integration-and-isolation \
  ../Surveillance-Survivor-prabu-animation origin/main
cd ../Surveillance-Survivor-prabu-animation
```

---

## 1. Combat isolation (read first — not a physics bugfix)

### Fact (verified 2026-08-05)

There is **no SKPhysics combat path** on `main`:

- Zero `SKPhysics` / `physicsBody` / `physicsWorld` / contact bitmasks under `Game/` and `App/`.
- Hits, projectile sweeps, contact damage, and obstacle AABBs live in **`Sources/SurveillanceCore`** (e.g. `Simulation.firstIntersectionT`, entity contact damage).
- SpriteKit **projects** snapshots only; secondary motion is bounded and decorative.

Audit D: [`CONTINUATION_REPORT_2026-08-05_architecture_isolation_audit.md`](CONTINUATION_REPORT_2026-08-05_architecture_isolation_audit.md) — isolation **PASS**.

### Law (do not regress)

From `AGENTS.md` / animation doctrine:

| Allowed | Forbidden |
| --- | --- |
| Interpolate sim poses for display | `SKPhysicsWorld` as hit or movement authority |
| Bounded recoil / wobble / debris **cosmetics** | Resolving hits in animation callbacks |
| Multi-frame texture cycles from sim time | Sprite size / frame index as hit radius or damage timing |
| Shape-node fallbacks when art missing | RNG that changes combat truth |

**Prabu task on isolation:** while wiring remaining animation, **preserve** this split. Do not “fix combat feel” by adding physics bodies to projectiles, player, or sensors. If something feels wrong, change **presentation** or file a **Core** change with tests — never mix the two silently.

### Quick regression check (run before PR)

```bash
rg -n "SKPhysics|physicsBody|physicsWorld|contactTestBitMask|collisionBitMask" Game/ App/ --glob '*.swift'
# Expected: no matches (or only comments if any are added — prefer zero)
make animation-check weapon-vfx-check assets-check
```

---

## 2. Remaining animation work (primary delivery)

### Authority (open in this order)

1. [`GAMEPLAY_ANIMATION_PLAN.md`](GAMEPLAY_ANIMATION_PLAN.md) — start here  
2. [`GAMEPLAY_ANIMATION_PHYSICS_PRODUCTION.md`](GAMEPLAY_ANIMATION_PHYSICS_PRODUCTION.md)  
3. [`GAMEPLAY_ANIMATION_AGENT_EXECUTION.md`](GAMEPLAY_ANIMATION_AGENT_EXECUTION.md) — batches 3–10  
4. [`GAMEPLAY_ANIMATION_MANIFEST.json`](GAMEPLAY_ANIMATION_MANIFEST.json) — status authority  
5. [`WEAPON_VFX_ASSET_MANIFEST.json`](WEAPON_VFX_ASSET_MANIFEST.json) + [`WEAPON_VFX_AGENT_EXECUTION.md`](WEAPON_VFX_AGENT_EXECUTION.md)  
6. [`docs/VISUAL_ASSET_PRODUCTION_PROMPTS.md`](VISUAL_ASSET_PRODUCTION_PROMPTS.md) (prompts; do not fork art direction)  

Gates before/after:

```bash
make animation-check
make weapon-vfx-check
make assets-check
```

### Important: PNGs may already exist

#159 landed **341** runtime PNGs + matching `Assets.xcassets` (catalog is the ship path via `UIImage(named:)` / `project.yml`).

Many clips the **animation manifest still marks `missing`/`reserved`** already have multi-frame banks on disk, e.g.:

| Manifest-ish role | Runtime stems present (examples) | Count (approx) |
| --- | --- | --- |
| player.damage | `player_damage`, `_2`… | 4 |
| player.defeat | `player_defeat`… | 10 |
| player.extract | `player_extract`… | 10 |
| fx.impact.hardware | `fx_impact_surveillance_hardware`… | 6 |
| lpr.scan | `lpr_scan_loop`… | 6 |
| lpr.destroy | `lpr_destroy_sequence`… | 10 |
| boss.telegraph.primary | `boss_telegraph_primary`… | 8 |
| fx.blind_spot.open | `fx_blind_spot_open`… | 12 |
| weapon stills / deploy | `deploy_identity_transponder`, `projectile_redaction`, `swarm_foia`, pulses… | multi |

**Weapon VFX manifest** still lists many as `missing` while files exist — treat that as **integration / status debt**, not “generate from zero” unless hash/audit says the file is wrong.

### Preferred order of work

1. **Inventory-first (Batch 0-style re-check on HEAD)**  
   - Map each `GAMEPLAY_ANIMATION_MANIFEST` / `WEAPON_VFX` row → catalog stem → `OptionalSpriteFrameCycle` / projector call sites.  
   - Receipt under `docs/animation/` (new batch receipt, e.g. Batch 3 inventory after #159).  
   - Do **not** regenerate art that already matches manifest dimensions/role without owner approval.

2. **Wire runtime integration** (where frames exist but status ≠ `runtime_integrated`)  
   - Ensure `GameAssetName` / `VisualAssetMap` / projectors select the stems.  
   - `OptionalSpriteFrameCycle.probeLimit` is already **16** — do not lower it.  
   - Keep shape fallbacks until owner + device readability evidence.  
   - Update **manifest status**, frame order, hashes, reduced-flash notes, and batch receipt **in the same PR** as code.

3. **Batch ladder (from agent execution)** — resume where art is missing after inventory:  
   - Batch 3: projectile / impact motion  
   - Batch 4: deployable unfold / active / expire  
   - Batch 5: LPR scan / destroy  
   - Batch 6: guards (if not already walk cycles)  
   - Batch 7: boss telegraphs / phases  
   - Batch 8: Blind Spot open / extract  
   - Then device QA / reduced-motion / reduced-flash (Batch 10) — coordinate with operator ART re-attest  

4. **Reduced-flash / reduced-motion**  
   Required for telegraphs, pulses, high-luminance VFX per doctrine. Missing variants = do not claim ship animation complete.

### Explicit non-goals for this handoff

- City 11 / new weapons  
- `SKPhysics` projectiles or ragdolls  
- Mid-run coin shop / scope expansion  
- Claiming ART_SHIP or launch READY  
- Force-pushing `main` or collaborator branches  

---

## 3. Related context (not all Prabu-owned)

| Item | Owner | Note |
| --- | --- | --- |
| ART re-attest on HEAD (UrbanDress + prompted set) | Operator | Audit B: machine PASS; approval **stale** vs HEAD |
| Residual freeze / TestFlight | Owner/operator | Audit A: **LAUNCH_BLOCKED**; list L in ship residual audit |
| Board tip / remotes | Already cleaned | Open PRs none; do not reintroduce bootstrap branches |

Audits index: [`docs/audits/README.md`](audits/README.md).

---

## 4. PR checklist (Prabu)

- [ ] Branch off current `main`; PR against `main`  
- [ ] `make animation-check weapon-vfx-check assets-check` green  
- [ ] No new SKPhysics / physics-body combat  
- [ ] Manifest status + batch receipt updated with any claim of `runtime_integrated`  
- [ ] Shape fallbacks retained unless owner approved removal  
- [ ] Tests for new projector hooks where practical  
- [ ] PR body: changed files, validation, risks, any Notion discrepancy  
- [ ] Reduced-flash notes for any new pulse/telegraph wiring  

### Suggested PR titles (pick one scope per PR if large)

- `feat(animation): integrate post-#159 multi-frame banks into projectors + manifests`  
- `docs(animation): Batch 3 inventory receipt after prompted sprite intake`  
- `feat(animation): Batch 3–5 projectile LPR deployable cycles` (only after inventory)

---

## 5. One-line mission

**Wire and honestly status the remaining animation/VFX using existing #159 frames where present; never put combat on SKPhysics; leave READY claims to residual humans.**
