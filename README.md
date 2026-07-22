# Surveillance Survivor

**Surveillance Survivor** is an iPhone-first satirical top-down survivor roguelite about remaining untrackable long enough to break an absurd privatized surveillance grid.

## Canonical platform

- iPhone first
- Swift 6
- SpriteKit gameplay projection
- SwiftUI application shell
- Offline MVP
- No backend, accounts, ads, multiplayer, live-location data, or real surveillance feeds
- Landscape presentation
- Premium single-purchase direction

## MVP proof

The first vertical slice must prove:

1. responsive touch movement;
2. deterministic simulation;
3. automatic attacks and readable enemy pressure;
4. Suspicion tiers 0–5;
5. destructible LPR camera poles;
6. deterministic three-choice upgrades;
7. the Shift Manager boss;
8. Blind Spot extraction;
9. interruption-safe pause and resume;
10. reproducible build, test, and gameplay receipts.

## Local setup

```bash
brew install xcodegen
make generate
open SurveillanceSurvivor.xcodeproj
```

Run the deterministic core tests without Xcode:

```bash
make test-core
```

## Documentation

- `docs/ONE_SHOT_EXECUTION.md` — implementation sequence, gates, and scope boundaries
- Canonical product and engineering specifications are maintained in the linked Notion concept packet.

## Status

Bootstrap in progress. The deterministic core and native iPhone shell are being established before gameplay expansion.
