# Gameplay animation work receipt — Batch 1

| Field | Value |
| --- | --- |
| Batch | **1** — Presentation architecture |
| Date (UTC) | 2026-07-25 |
| Art generated | **None** |
| Gameplay sim changed | **No** |
| Physics bodies for hits | **No** |

## Mission

Implement physics-informed **presentation** infrastructure: snapshot pose buffer, animation state machines driven by sim fields, bounded secondary motion, quality tiers wired to reduced-motion/flash.

## Deliverables (code)

| Component | Path |
| --- | --- |
| Quality tiers | `Game/Presentation/PresentationQualityTier.swift` |
| Pose buffer / lerp | `Game/Presentation/PresentationPoseBuffer.swift` |
| Animation SM | `Game/Presentation/EntityAnimationState.swift` |
| Secondary motion | `Game/Presentation/SecondaryMotion.swift` |
| Pipeline | `Game/Presentation/PresentationPipeline.swift` |
| Projector wiring | `Game/Rendering/EntityProjector.swift` |
| Scene wiring | `Game/Scenes/GameScene.swift` |
| Tests | `Tests/SurveillanceSurvivorTests/PresentationPipelineTests.swift` |

## Behavior

- After each fixed sim step: `commitSimulationStep` copies poses (presentation only).
- Each render: sample with blend from quality tier; apply bounded spring offsets for lean/recoil feel.
- Minimal tier (reduced motion): secondary scale 0; camera snaps.
- Reduced flash still damps signalFlood shape colors (existing path).
- Player `zRotation` lean and squash are **visual only**; sim position/heading/collision unchanged.

## Manifest

Architecture clips marked `runtime_integrated`:

- `presentation_snapshot_interpolation`
- `presentation_secondary_motion`
- `presentation_quality_tiers`

## Validation

```bash
make animation-check
# PresentationPipelineTests via xcodebuild -only-testing:SurveillanceSurvivorTests/PresentationPipelineTests
```

## Explicit non-claims

- No multi-frame sprite banks (Batch 2).
- No weapon flight sheets (needs VFX stills).
- No SKPhysics gameplay authority.

## Next

- Batch 2: multi-frame player cycles (reuse 8 stills as identity anchors)
- Or Weapon/VFX Batch 1 P0 silhouette candidates
