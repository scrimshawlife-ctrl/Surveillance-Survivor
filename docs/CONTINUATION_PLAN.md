# Continuation Plan

## Campaign objective

Advance Surveillance Survivor from native bootstrap to a physically testable iPhone vertical-slice foundation without weakening deterministic state ownership or accepting unverified production assets.

## Execution order

### 1. CI stabilization

- keep `swift test`, XcodeGen generation, and simulator build as mandatory gates;
- remove phantom paths and duplicate compilation ownership;
- treat a green package test as necessary but not sufficient;
- record simulator and physical-device gaps explicitly.

### 2. Repository front door

- maintain the README as the public project index;
- badges must report real status rather than aspirational claims;
- hero art is presentation-only and must not be confused with runtime assets;
- roadmap and documentation links must remain synchronized with active work packages.

### 3. Production asset intake

- preserve v0.1 and v0.2 source packages as provenance;
- ingest only dimension-verified, alpha-verified runtime exports;
- retain shape-node fallbacks when a texture is absent or rejected;
- use `GameAssetName` as the only runtime naming authority;
- do not infer player atlas frame rectangles from labeled presentation sheets.

### 4. Texture-backed projection

- resolve validated catalog textures through `TextureAssetLoader`;
- enforce nearest-neighbor filtering;
- keep collision geometry in the simulation, independent of texture bounds;
- use LPR intact, damaged, and destroyed states when verified assets are present.

### 5. WP1 completion

- bounded virtual-stick input;
- camera follow;
- deterministic world bounds;
- obstacle collision resolution;
- interruption-safe pause/resume;
- duplicate-free entity projection;
- object pooling and left-handed controls remain the final WP1 frontier;
- simulator and physical-device receipts remain mandatory before closure.

### 6. WP2 opening slice

- deterministic parking-lot generation;
- parking islands and traversal lanes;
- seeded LPR placement;
- rotating LPR scan cones;
- sensor contact contributes to Suspicion;
- guards move toward the player through deterministic simulation;
- combat and destruction input remain deferred to the next bounded slice.

## Current authority

```text
Swift package core
  owns RunState, WorldLayout, entities, movement, collision, LPR headings, and Suspicion

SpriteKit
  projects world and entity state, camera motion, scan cones, and texture fallbacks

SwiftUI
  owns lifecycle overlays, HUD layout, accessibility, and Suspicion presentation
```

## Acceptance gates

A continuation slice is acceptable only when:

1. deterministic tests pass;
2. XcodeGen produces the project;
3. the simulator target builds without signing;
4. no runtime texture is assumed to exist without validation;
5. state remains reproducible for a fixed seed and input sequence;
6. scope additions map to a documented work package;
7. physical-device-only claims remain labeled pending until observed.

## Next bounded slice

After the current CI gate is green:

1. add node pooling;
2. add left-handed virtual-stick configuration;
3. add automatic player attack targeting;
4. add camera-pole health and destruction interaction;
5. integrate verified binary LPR exports into the Xcode asset catalog;
6. capture the first simulator gameplay receipt.
