# Surveillance Survivor — Gameplay Animation Agent Execution

> **Entry plan:** [`GAMEPLAY_ANIMATION_PLAN.md`](GAMEPLAY_ANIMATION_PLAN.md)  
> **Production doctrine:** [`GAMEPLAY_ANIMATION_PHYSICS_PRODUCTION.md`](GAMEPLAY_ANIMATION_PHYSICS_PRODUCTION.md)  
> **Machine queue:** [`GAMEPLAY_ANIMATION_MANIFEST.json`](GAMEPLAY_ANIMATION_MANIFEST.json)  
> **Related still art:** [`WEAPON_VFX_AGENT_EXECUTION.md`](WEAPON_VFX_AGENT_EXECUTION.md)

## Authority read order

1. This packet  
2. `GAMEPLAY_ANIMATION_PHYSICS_PRODUCTION.md`  
3. `GAMEPLAY_ANIMATION_MANIFEST.json`  
4. `WEAPON_SYSTEM_DESIGN.md` + weapon VFX docs (for countermeasure identities)  
5. `Game/Rendering/*` (current projectors, `PlayerAtlasManifest`, `VisualAssetMap`)  
6. `Sources/SurveillanceCore` event/entity surfaces (read-only for presentation contracts)

Run `make animation-check` before and after related changes.

## Hard boundary

- Simulation owns all combat/movement truth.  
- Presentation may interpolate and add **bounded** secondary motion only.  
- No `SKPhysicsWorld` as hit/movement authority.  
- Physics bodies only for disposable cosmetic debris if used at all.  
- Do not expand runtime stems without `GameAssetName` + `VisualAssetMap` + tests together.  
- Shape fallbacks remain until approved multi-frame banks exist.  
- Weapon still silhouettes stay under weapon VFX Batch 0/1; **do not** re-generate still art under animation filenames.

## Batch ladder

### Batch 0 — Inventory and presentation audit (docs only)

1. `git status --short`  
2. Inventory existing player/entity frames, atlases, projectors  
3. Record what is single-frame vs multi-frame  
4. Map sim states → current presentation behavior  
5. Classify each manifest row: present / missing / reserved  
6. **Do not generate art or rewrite gameplay**

Deliver:

- `docs/animation/ANIMATION_INVENTORY.json`  
- `docs/animation/ANIMATION_DEDUP_REPORT.md`  
- `docs/animation/ANIMATION_BATCH_0_RECEIPT.md`

### Batch 1 — Presentation architecture (code, no new art)

- Snapshot prev/current interpolation  
- Explicit animation state machines driven by sim state  
- Secondary-motion component (recoil, spring settle, bounded wobble)  
- Quality tier hooks (full / reduced / minimal)  
- Reduced-motion / reduced-flash switches  
- Tests: interpolation does not change sim; missing assets still fallback  

### Batch 2 — Player multi-frame cycles

- Expand idle/walk to multi-frame targets in manifest  
- Keep anchors and sim foot position locked  
- Contact sheets at iPhone scale  

### Batch 3 — Projectile / impact motion

- Depends on weapon VFX P0 stills where applicable  
- Flight alignment, trails, impact responses  
- Density pooling  

### Batch 4 — Deployable unfold / active / expire

Mirror Array hinge sequence · Signal Flood charge/pulse · other deployables as reserved until stems exist  

### Batch 5 — Camera / LPR states

Idle · scan · damage · disable · destroy sequences (debris visual-only)  

### Batch 6 — Guards  

### Batch 7 — Boss telegraphs / phases  

### Batch 8 — Blind Spot / extraction  

### Batch 9 — Environmental secondary motion  

### Batch 10 — Device QA + max-density + a11y

Physical iPhone · reduced-motion · reduced-flash · frame budget evidence  

## Directory contract

```text
Resources/Animation/
  Masters/
    Player/
    Weapons/
    Enemies/
    Bosses/
    Cameras/
    FX/
    Environment/
  Delivery/
    ...

docs/animation/
  ANIMATION_INVENTORY.json
  ANIMATION_DEDUP_REPORT.md
  ANIMATION_BATCH_<n>_RECEIPT.md
  ANIMATION_DEVICE_QA.md
```

Do not fill trees with unapproved binaries to imply completion.

## Receipt requirements

Every batch receipt lists: manifest IDs · clips · generator settings · paths · SHA-256 · frame counts/durations/anchors · reuse decisions · namespace/role changes · tests · simulator evidence · device evidence status · risks · commit/PR.

## Prohibited shortcuts

- Animation-driven hits or damage windows  
- Sprite-size collision  
- Random projectile drift  
- Unbounded flocking for FOIA swarm  
- Reflection visuals that disagree with sim vectors  
- Full-screen white flashes as primary telegraph  
- City-exclusive weapon animation engines  
- Claiming multi-frame complete when only single stills exist  
