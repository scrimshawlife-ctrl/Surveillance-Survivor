<div align="center">

<img src="docs/readme-hero.svg" alt="Surveillance Survivor — Stay Untrackable. Break the Grid." width="100%" />

# Surveillance Survivor

**An iPhone-first satirical survivor roguelite about staying untrackable long enough to break an absurd privatized surveillance grid.**

[![CI](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/actions/workflows/ci.yml)
![Status](https://img.shields.io/badge/status-pre--alpha-7c3aed)
![Platform](https://img.shields.io/badge/platform-iPhone-111827?logo=apple)
![iOS](https://img.shields.io/badge/iOS-18%2B-0A84FF?logo=ios)
![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
![SpriteKit](https://img.shields.io/badge/rendering-SpriteKit-00c7be)
![SwiftUI](https://img.shields.io/badge/shell-SwiftUI-0D96F6)
![Offline](https://img.shields.io/badge/MVP-offline--first-14b8a6)
![Campaign](https://img.shields.io/badge/campaign-10%20American%20cities-c026d3)

[Vision](#vision) · [Gameplay](#gameplay-pillars) · [Campaign](#ten-city-campaign) · [Architecture](#architecture) · [Build](#local-development) · [Roadmap](#roadmap) · [Docs](#documentation)

</div>

> **Development status:** active pre-alpha / testable prototype. The deterministic core, native iPhone shell, touch controls, entity projection, Suspicion HUD, production asset contracts, and ten-city campaign authority are being established before content expansion.

## Vision

**Surveillance Survivor** turns suburban surveillance infrastructure, privatized authority, automated suspicion, and bureaucratic theater into a fast, readable, replayable action roguelite.

You enter a procedurally assembled district, evade escalating observation systems, destroy or confuse LPR camera poles, assemble an anti-surveillance build, defeat the district authority, and escape through a temporary **Blind Spot**.

The tonal target is **paranoid slapstick**, not horror realism: tactical golf carts, overconfident guards, fluorescent parking lots, contradictory radio chatter, procurement absurdity, and systems that mistake visibility for guilt.

## Gameplay pillars

| Pillar | Player-facing result |
|---|---|
| **Stay untrackable** | Break line of sight, redirect attention, spoof identity, and exploit environmental cover. |
| **Weaponize suspicion** | Ride higher Suspicion tiers for greater danger, denser rewards, and stronger escalation. |
| **Break the grid** | Destroy, hack, rotate, spoof, or bureaucratically confuse surveillance infrastructure. |
| **Build strange synergies** | Combine signal disruption, social camouflage, physical disruption, and procedural warfare. |
| **Extract through a Blind Spot** | Defeat the district authority and escape before the surveillance system reasserts control. |

## Ten-city campaign

The full campaign escalates from local camera installations to regional sharing, interagency networks, public-private ambiguity, and finally the commercial surveillance platform itself.

| Level | City | District title | Boss |
|---:|---|---|---|
| 1 | Wichita | **The Panopticon of the Plains** | The Aviation Security Commissioner |
| 2 | Louisville | **Derby Day Data Dragnet** | The Keeper of Confidential Coordinates |
| 3 | Tulsa | **The Petroleum Panopticon** | The Golden Watchman |
| 4 | Dayton | **Gateway City: Every Camera Counts** | The Director of Gateway Optimization |
| 5 | Oakland | **The Sanctuary Scanner** | The Contract Renewal Hydra |
| 6 | San Francisco | **Fog of Probable Cause** | The Algorithmic Moderate |
| 7 | Columbus | **The Six-Hundred-Eye Statehouse** | The Mayor of Meaningful Review |
| 8 | New York City | **The Five-Borough Omnigaze** | The Five-Borough Data Baron |
| 9 | Los Angeles | **Thirty-Five Hundred Eyes, No One in Charge** | The Decentralized Accountability Producer |
| 10 | Atlanta | **Flock's Nest** | The Safety Evangelist |

Each city receives its own landmark vocabulary, environment palette, traversal rhythm, surveillance mechanic, standard enemies, elite enemy, and multi-phase boss. The final trilogy is fixed as **New York City → Los Angeles → Atlanta**.

> The campaign roster is evidence-weighted and gameplay-ordered. It must not be represented as a definitive national ranking of Flock camera deployments because no complete authoritative city-level dataset exists.

See [`docs/TEN_CITY_CAMPAIGN_ROSTER.md`](docs/TEN_CITY_CAMPAIGN_ROSTER.md) for the complete landmark, enemy, elite, boss, likeness, and asset-generation specification.

## Canonical MVP

```yaml
platform: iPhone
orientation: landscape
minimum_os: iOS 18
language: Swift 6
renderer: SpriteKit
application_shell: SwiftUI
simulation: deterministic_fixed_step
networking: none
accounts: none
analytics: local_receipts_only
business_model: premium_single_purchase
```

The first vertical slice must prove:

- responsive virtual-stick movement;
- deterministic simulation independent of render frame rate;
- readable enemy pressure and automatic attacks;
- Suspicion tiers `0...5`;
- destructible LPR camera poles;
- deterministic three-choice upgrades;
- the **Shift Manager** boss;
- **Blind Spot** extraction;
- interruption-safe pause and resume;
- reproducible build, test, and gameplay receipts.

## Architecture

The simulation is authoritative. SpriteKit projects state; it does not own game truth.

```text
Player Input
    ↓
Fixed-Step Simulation (1/60)
    ↓
Authoritative RunState
    ├── entities
    ├── suspicion
    ├── progression
    ├── boss state
    └── extraction state
    ↓
SpriteKit Projection + SwiftUI HUD
```

### Technology stack

| Layer | Technology | Responsibility |
|---|---|---|
| App shell | SwiftUI | lifecycle, menus, overlays, accessibility |
| Gameplay rendering | SpriteKit | world projection, particles, animation, camera |
| Gameplay core | Swift Package | deterministic state transitions and contracts |
| Audio | AVAudioEngine | adaptive buses and interruption-safe playback |
| Haptics | Core Haptics | tier, damage, upgrade, and extraction feedback |
| Persistence | SwiftData / bounded local receipts | settings, unlocks, run summaries |
| Project generation | XcodeGen | reproducible Xcode project generation |
| CI | GitHub Actions | core tests, project generation, simulator build |

## Repository layout

```text
App/                         SwiftUI application shell and HUD
Game/                        SpriteKit scenes, input, and rendering adapters
Sources/SurveillanceCore/    Deterministic gameplay authority
Tests/                       Core and app-facing tests
Platform/                    Audio, haptics, persistence, accessibility
Resources/                   Runtime asset catalogs and data
Docs/                        Canonical engineering and execution references
.github/workflows/           Continuous integration
project.yml                  XcodeGen project authority
Package.swift                Swift package authority
Makefile                     Local build and validation commands
```

## Local development

### Requirements

- macOS with Xcode 26 or newer;
- Swift 6 toolchain;
- [XcodeGen](https://github.com/yonaskolb/XcodeGen);
- an iPhone or iOS Simulator for app validation.

### Bootstrap

```bash
git clone https://github.com/scrimshawlife-ctrl/Surveillance-Survivor.git
cd Surveillance-Survivor
git switch agent/iphone-bootstrap
brew install xcodegen
make generate
open SurveillanceSurvivor.xcodeproj
```

### Validation

```bash
# Deterministic Swift package tests
make test

# Generate the Xcode project and build the simulator target
make build

# Run the complete local gate, including the iOS Simulator tests
make validate
```

A successful package test is necessary but not sufficient. Changes affecting rendering, input, lifecycle, audio, haptics, performance, or accessibility require simulator and physical-device evidence.

## Current implementation status

| Surface | State |
|---|---|
| Deterministic fixed-step core | Implemented |
| Seeded randomness | Implemented |
| Authoritative run state | Implemented |
| Suspicion tiers | Implemented |
| SwiftUI shell | Implemented |
| SpriteKit projection | Implemented baseline |
| Virtual-stick input | Implemented baseline |
| Pause/resume lifecycle | Implemented baseline |
| Native Suspicion meter | Implemented baseline |
| Ten-city campaign authority | Implemented in docs |
| Production texture ingestion | In progress |
| Contract Security roster | Implemented and deterministic |
| Automated surveillance roster | Implemented and deterministic |
| Six countermeasures, 12 base upgrades, and four evolutions | Implemented and deterministic |
| Shift Manager and Blind Spot extraction | Implemented |
| Completed run receipt and summary persistence | Implemented |
| Physical-iPhone acceptance run | Pending — protocol tracked in release readiness |

## Roadmap

The canonical plan is organized as six evidence-gated packages. Current local work is hardening the headless deterministic runtime; campaign production follows only after the vertical slice is proven.

| Package | Outcome |
|---|---|
| **WP0 — Foundation** | Repository, XcodeGen project, package boundaries, CI, conventions, and canonical documentation. |
| **WP1 — Headless runtime** | Fixed-step clock, seeded RNG, entities, movement, events, and reproducible receipts. |
| **WP2 — Playable scene** | SpriteKit projection, touch movement, camera, collision, auto-attack, and placeholder visuals. |
| **WP3 — Signature loop** | Visibility, Suspicion tiers, LPR poles, three-choice upgrades, and escalating waves. |
| **WP4 — Vertical slice content** | The Ghost, required enemies, Shift Manager, Blind Spot extraction, audio, and haptics. |
| **WP5–6 — Shell and hardening** | Settings, accessibility, persistence, interruption recovery, performance, device protocol, and release evidence. |

See the open [issues](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues) and [draft bootstrap PR](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/1) for active engineering scope.

## Visual asset policy

Reference boards and marketing compositions are preserved separately from runtime exports. Runtime textures are accepted only when they satisfy the production contract:

- deterministic names;
- verified dimensions and sRGB encoding;
- real alpha transparency where required;
- common canvases and documented anchors;
- no labels, grids, captions, or presentation borders;
- nearest-neighbor readability on physical iPhone hardware;
- collision geometry defined by simulation data, never by image bounds.

City content adds these requirements:

- landmarks must establish place without requiring labels;
- silhouettes must remain readable at landscape-iPhone scale;
- every city needs a distinct palette and traversal rhythm;
- political and industry bosses default to original fictional composites;
- direct likenesses require separate approval and legal review.

Shape-node fallbacks remain authoritative until each binary asset passes validation.

## Documentation

| Reference | Purpose |
|---|---|
| [`docs/ONE_SHOT_EXECUTION.md`](docs/ONE_SHOT_EXECUTION.md) | bounded implementation sequence and acceptance gates |
| [`docs/CONTINUATION_PLAN.md`](docs/CONTINUATION_PLAN.md) | current production continuation sequence |
| [`docs/RELEASE_READINESS.md`](docs/RELEASE_READINESS.md) | reproducible simulator gates and physical-device evidence protocol |
| [`docs/TEN_CITY_CAMPAIGN_ROSTER.md`](docs/TEN_CITY_CAMPAIGN_ROSTER.md) | city landmarks, enemies, elites, bosses, and asset order |
| [`docs/VISUAL_ASSETS_V0_1.md`](docs/VISUAL_ASSETS_V0_1.md) | original visual-pack audit and art-direction authority |
| [`docs/VISUAL_ASSETS_V0_2_INTAKE.md`](docs/VISUAL_ASSETS_V0_2_INTAKE.md) | production texture intake and naming contract |
| [`Game/Rendering/GameAssetName.swift`](Game/Rendering/GameAssetName.swift) | canonical runtime asset namespace |
| [Notion concept packet](https://app.notion.com/p/3a43e8ba2f5c81a099bfc757aa9dcea4) | product vision and satire boundaries |
| [Ten-city campaign roster](https://app.notion.com/p/3a53e8ba2f5c81b892c0f15e7860dd67) | synchronized campaign-content authority |
| [iPhone platform decision](https://app.notion.com/p/3a53e8ba2f5c81fe8e68d320efa51b0d) | platform priority and MVP constraints |
| [iOS architecture](https://app.notion.com/p/3a53e8ba2f5c8146b8ecd700e6d56b9c) | system boundaries and dependency direction |
| [Gameplay runtime and data contracts](https://app.notion.com/p/3a53e8ba2f5c812487d7ccc8163b8e4d) | simulation, content, and projection contracts |
| [iPhone UX and accessibility](https://app.notion.com/p/3a53e8ba2f5c81b6990bc65bbfe04cd9) | interaction doctrine, accessibility, audio, and haptics |
| [Verification plan](https://app.notion.com/p/3a53e8ba2f5c813a942eeb17058f9ffd) | CI, simulator, and device evidence requirements |

The hero is the repository's existing local SVG. The reviewed Notion sources did not expose an approved, repository-ready screenshot or image attachment; add one only after it is supplied or explicitly approved in Notion.

## Scope boundaries

The MVP is intentionally offline and self-contained. It does **not** use real surveillance feeds, live location data, external accounts, advertising, multiplayer, user-generated content, or a backend service.

The game is satirical fiction. Its target is surveillance theater, automated suspicion, privatized authority, institutional absurdity, and surveillance-industry ideology—not claims about real-world coordinated stalking.

## Contributing

Development currently follows issue-bounded work packages and draft pull requests. Before changing gameplay authority, asset contracts, lifecycle behavior, campaign content, or scope boundaries:

1. read the relevant canonical document;
2. identify the owning module;
3. preserve deterministic state ownership;
4. add or update validation coverage;
5. record any physical-device requirement that CI cannot prove.

## License

No public license has been declared yet. All rights are reserved unless and until a license file is added to the repository.

---

<div align="center">

**Stay Untrackable. Break the Grid.**

</div>
