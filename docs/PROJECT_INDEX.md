# Surveillance Survivor — Project Index

```yaml
version: 1.0.0
status: active
last_updated: 2026-07-26
supersedes: null
superseded_by: null
authority_scope: repository + Notion navigation map for Surveillance Survivor
notion_mirror: https://app.notion.com/p/3a93e8ba2f5c81fab93de28035c31d94
```

This page indexes the **live repository** and routes to product authorities.
It summarizes; it does not override linked Notion design pages or `versions.json`.

**Notion twin:** [Surveillance Survivor — Index, Map, and Organization](https://app.notion.com/p/3a93e8ba2f5c81fab93de28035c31d94)

---

## Authority split

| Surface | Governs |
| --- | --- |
| Notion product pages | Platform, architecture contracts, campaign, weapons, UX, verification design |
| GitHub (`main`) | Implementation, tests, merge evidence, manifests, operator receipts |
| [`versions.json`](../versions.json) | App/build/protocol/save/receipt/content version numbers |
| [`AGENTS.md`](../AGENTS.md) | Engineering law for agents |

If Notion and the repository conflict, **report the discrepancy** before changing gameplay scope or product claims.

---

## Top-level layout

| Path | Role | Owns combat truth? |
| --- | --- | --- |
| [`Sources/SurveillanceCore/`](../Sources/SurveillanceCore/) | Deterministic headless simulation + content JSON | **Yes** |
| [`Game/`](../Game/) | SpriteKit scene, input, rendering, presentation, persistence adapters | No |
| [`App/`](../App/) | SwiftUI shell, HUD, lifecycle | No |
| [`Tests/`](../Tests/) | Core / app / UI tests | N/A |
| [`Resources/`](../Resources/) | RuntimeSprites, Audio, WeaponVFX, Animation, Assets | No (projection only) |
| [`docs/`](./) | Roadmap, manifests, city packs, operator packets | N/A |
| [`scripts/`](../scripts/) · [`Makefile`](../Makefile) | Validation + device/emulator automation | N/A |
| [`project.yml`](../project.yml) | XcodeGen project authority | N/A |
| [`Package.swift`](../Package.swift) | SwiftPM library for `SurveillanceCore` | N/A |

---

## Simulation core (`Sources/SurveillanceCore/`)

Entry: [`Simulation.swift`](../Sources/SurveillanceCore/Simulation.swift) — fixed-step `step(input:)` over `RunState`.

| Cluster | Files |
| --- | --- |
| Loop / world | `Simulation`, `RunState`, `Entity`, `WorldLayout`, `Vector2`, `DeterministicRNG` |
| Suspicion | `SuspicionDirector`, `SuspicionTier`, `SuspicionCatalog` |
| Combat / build | `WeaponSystem`, `BuildEngine`, `UpgradeCatalog`, `UpgradeOfferBias`, `ClearingBuilds` |
| City systems | `CityState`, `CitySystemicRules`, `CoordinationGraph`, `Interactables`, `LandmarkEncounter` |
| Campaign / meta | `DistrictCatalog`, `DistrictGenerator`, `CampaignProgress`, `ChallengeContracts`, `MasteryProgress`, `UnlockCatalog`, `UnlockPresentation` |
| Story / evidence | `RunStory`, `RunReceipt`, `AudioEventCatalog` |
| Content load | `ContentCatalog`, `ContentGraphValidator`, `EnemyCatalog`, `BossCatalog`, `WaveCatalog` |

### Bundled content catalogs (`Resources/Content/`)

19 JSON authorities: `audio_events`, `bosses`, `build_synergies`, `challenge_contracts`, `city_systemic_rules`, `clearing_builds`, `coordination_graphs`, `director_rules`, `districts`, `enemies`, `infrastructure_nodes`, `interactables`, `landmark_encounters`, `story_fact_rules`, `suspicion`, `unlockables`, `upgrades`, `waves`, `weapons`.

---

## Game projection (`Game/`)

| Module | Role |
| --- | --- |
| `Scenes/GameScene.swift` | SpriteKit host; projects sim snapshots |
| `Rendering/` | Entity/world projectors, `VisualAssetMap`, textures, combat layers, optional frame cycle |
| `Presentation/` | Pose buffer, secondary motion, quality tiers — **physics-informed presentation only** |
| `Input/` | Virtual stick |
| `Feedback/` | Audio cue player, haptics |
| `Persistence/` | Campaign / mastery / run-receipt stores |
| `Diagnostics/` | Frame-time diagnostics |

Secondary motion must never move canonical entity positions or resolve hits.

---

## App shell (`App/`)

`SurveillanceSurvivorApp` → `RootView` + `SuspicionMeter` + `MovementStickOverlay` + design tokens / privacy manifest.

---

## Resources

| Tree | Notes |
| --- | --- |
| `Resources/RuntimeSprites/` | ~194 PNGs including ten city foundation packs |
| `Resources/Assets.xcassets` | App asset catalog |
| `Resources/Audio/{Masters,Delivery}` | Empty until Batch 1 intake |
| `Resources/WeaponVFX/{Masters,Delivery}` | Weapon/VFX delivery trees |
| `Resources/Animation/Masters` | Animation masters |

Asset availability must not change simulation rules.

---

## Documentation map

Prefer [`README.md`](README.md) for authority-order discovery. Quick routes:

| Need | Start |
| --- | --- |
| Live tip / PR board | [`REPO_STATUS.md`](REPO_STATUS.md) |
| What to do next | [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) · [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) |
| Phases P0–P11 | [`ROADMAP.md`](ROADMAP.md) |
| Systemic design program | [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) |
| Six countermeasures | [`WEAPON_SYSTEM_DESIGN.md`](WEAPON_SYSTEM_DESIGN.md) |
| Audio work | [`AUDIO_PLAN.md`](AUDIO_PLAN.md) |
| Weapon VFX work | [`WEAPON_VFX_ASSET_PRODUCTION.md`](WEAPON_VFX_ASSET_PRODUCTION.md) |
| Animation work | [`GAMEPLAY_ANIMATION_PLAN.md`](GAMEPLAY_ANIMATION_PLAN.md) |
| Campaign roster | [`TEN_CITY_CAMPAIGN_ROSTER.md`](TEN_CITY_CAMPAIGN_ROSTER.md) · [`cities/`](cities/) |
| Versions | [`VERSIONING.md`](VERSIONING.md) · [`../versions.json`](../versions.json) |
| Validation philosophy | [`ONE_SHOT_EXECUTION.md`](ONE_SHOT_EXECUTION.md) |

---

## Notion product authorities

Authority order (platform → architecture → runtime → UX → verification → campaign → weapons → assimilation → concept):

1. [iPhone Platform Decision](https://app.notion.com/p/3a53e8ba2f5c81fe8e68d320efa51b0d)
2. [iOS System Architecture](https://app.notion.com/p/3a53e8ba2f5c8146b8ecd700e6d56b9c)
3. [Gameplay Runtime & Content Pipeline](https://app.notion.com/p/3a53e8ba2f5c812487d7ccc8163b8e4d)
4. [iPhone UX / Audio / Haptics](https://app.notion.com/p/3a53e8ba2f5c81b6990bc65bbfe04cd9)
5. [Verification & One-Shot Execution](https://app.notion.com/p/3a53e8ba2f5c813a942eeb17058f9ffd)
6. [Ten-City Campaign Roster](https://app.notion.com/p/3a53e8ba2f5c81b892c0f15e7860dd67)
7. [Countermeasure Weapon System](https://app.notion.com/p/3a53e8ba2f5c811e849dcfa7d95aa5ff)
8. [Roguelike Benchmark Assimilation](https://app.notion.com/p/3a83e8ba2f5c817f8348fe357aaa3cf4)
9. [Concept Packet v0.1](https://app.notion.com/p/3a43e8ba2f5c81a099bfc757aa9dcea4) (historical; iPhone-first override applies)

Parent: [Neon Genie](https://app.notion.com/p/8dd67fccc665416bbbced57c1d0a5ef7).

---

## Validation targets

```bash
make version-check
make assets-check sprite-chroma-check
make audio-check weapon-vfx-check animation-check
make director-check city-state-check build-engine-check coordination-check
make story-check interactables-check landmark-check clearing-builds-check city-rules-check
make test
make build
make validate
```

Physical-iPhone evidence is required for touch reachability, lifecycle, audio, haptics, accessibility, visual density, flash safety, or performance changes.

---

## Working player loop (implementation-aligned)

```text
ENTER DISTRICT
→ EVADE LPR SCAN CONES / LOS
→ DESTROY CAMERAS → DATA SHARDS → 3-CHOICE UPGRADE DRAFT
→ SURVIVE DIRECTOR / CITY-STATE ESCALATION
→ DEFEAT AUTHORITY → OPEN BLIND SPOT → EXTRACT
```

No mid-run coin shop. Offline MVP: no accounts, backend, telemetry, live location, ads, or multiplayer.

---

## Status snapshot (index date)

| Field | Value |
| --- | --- |
| App | `0.1.0` build `1` · pre-alpha |
| Systems | P8–P11 systemic lanes on `main`; ten-city foundation art |
| Art ship gate | `ART_EVIDENCE_INSUFFICIENT` |
| Audio | Dry-run until owner-approved binaries |
| Open human gates | Device acceptance · ART · ElevenLabs · store URLs · TestFlight |
| Agent lane | Idle until operator acceptance or new inventory residual |

Live board: [`REPO_STATUS.md`](REPO_STATUS.md).
