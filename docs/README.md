# Surveillance Survivor documentation index

```yaml
version: 1.0.2
status: approved
last_updated: 2026-08-07
supersedes: 1.0.1
superseded_by: null
authority_scope: repository documentation discovery and source-of-truth routing
```

This page routes contributors and coding agents to the current repository authorities. It summarizes; it does not override the linked documents.

**Full project map** (code + Notion twin): [`PROJECT_INDEX.md`](PROJECT_INDEX.md) · [Notion Index / Map / Organization](https://app.notion.com/p/3a93e8ba2f5c81fab93de28035c31d94)

## Authority order

1. [`../versions.json`](../versions.json) — machine-readable product, build, protocol, persistence, receipt, content, and document-version registry.
2. [`VERSIONING.md`](VERSIONING.md) — version increment, compatibility, migration, tagging, and documentation-supersession policy.
3. [`ROADMAP.md`](ROADMAP.md) — sequenced product outcomes through P11.
4. [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) — approved P8–P11 systemic roguelike design program.
5. [`RELEASE_READINESS.md`](RELEASE_READINESS.md) — production and device evidence gates.
6. [`REPO_STATUS.md`](REPO_STATUS.md) — live issue, pull-request, and task state.

Where duplicated values disagree, follow the source-of-truth order defined in [`VERSIONING.md`](VERSIONING.md), then repair the lower-authority surface.

## Current version baseline

| Domain | Version |
| --- | --- |
| App release | `0.1.0` |
| Apple build | `1` |
| Simulation protocol | `1` |
| Save-data format | `1` |
| Run-receipt **compatibility** | `1` (`compatibility.run_receipt.compatibility_version`) |
| Run-receipt **schema** / envelope | `11` (`compatibility.run_receipt.schema_version` = `RunReceipt.schemaVersion`) |
| Campaign / mastery persistence | `1` / `1` |
| Content catalog generation | `1` |
| Districts / waves family schema | `2` |
| Versioning policy | `1.1.0` |
| Roguelike assimilation program | `1.0.0` |

Do not confuse receipt compatibility with schema — see [`VERSIONING.md`](VERSIONING.md) §8. Run `make version-check` before changing or publishing any versioned authority. The full `make validate` gate includes this check; Linux CI `core-tests` runs it first.

## Product and engineering authorities

| Reference | Scope |
| --- | --- |
| [`ROADMAP.md`](ROADMAP.md) | Launch lane P0–P7 and systemic design lane P8–P11 |
| [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) | Suspicion Director, city state, build engine, coordination, landmarks, audio, story receipts, replayability |
| [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) | Engineering execution and continuation style |
| [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Device, TestFlight, and release evidence |
| [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md) | Physical-iPhone smoke / suite commands and pitfalls |
| [`EMULATOR_AUTOMATION.md`](EMULATOR_AUTOMATION.md) | Simulator gates, `-UITesting`, launch smoke |
| [`CAMPAIGN_PERSISTENCE.md`](CAMPAIGN_PERSISTENCE.md) | Offline unlocks + next-district cold launch |
| [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md) | Art inventory and sign-off |
| [`art/VISUAL_P0_REMEDIATION_2026-08-07.md`](art/VISUAL_P0_REMEDIATION_2026-08-07.md) | Level-audit P0 landmark / LPR / empty-gate remediation |
| [`art/VISUAL_P2_REMEDIATION_2026-08-07.md`](art/VISUAL_P2_REMEDIATION_2026-08-07.md) | Plate hygiene + combat pixel + crane pass |
| [`REPO_STATUS.md`](REPO_STATUS.md) | Live engineering board / open PR todo |
| [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) | App Store worksheet and owner-controlled fields |
| [`TEN_CITY_CAMPAIGN_ROSTER.md`](TEN_CITY_CAMPAIGN_ROSTER.md) | Campaign order, cities, landmarks, enemies, and bosses |

## Systemic phase contracts (P8–P11)

| Reference | Scope |
| --- | --- |
| [`P8_SUSPICION_DIRECTOR_CONTRACT.md`](P8_SUSPICION_DIRECTOR_CONTRACT.md) | Director budgets / spawn levers |
| [`P8_CITY_STATE_CONTRACT.md`](P8_CITY_STATE_CONTRACT.md) | Infrastructure graph + propagation |
| [`P8_BUILD_ENGINE_CONTRACT.md`](P8_BUILD_ENGINE_CONTRACT.md) | Upgrade tags / synergies |
| [`P8_COORDINATION_GRAPH_CONTRACT.md`](P8_COORDINATION_GRAPH_CONTRACT.md) | Interruptible enemy chains |
| [`P8_RUN_STORY_CONTRACT.md`](P8_RUN_STORY_CONTRACT.md) | Receipt-grounded story facts |
| [`P9_BIG_BOX_PROOF.md`](P9_BIG_BOX_PROOF.md) | Wichita systems proof (interactables, landmark, clearing builds) |
| [`P10_CITY_PROJECTION.md`](P10_CITY_PROJECTION.md) | Ten-city rule projection board |
| [`P11_REPLAYABILITY.md`](P11_REPLAYABILITY.md) | Challenges, mastery, presentation unlocks |

## Runtime, content, and presentation authorities

| Reference | Scope |
| --- | --- |
| [`AUDIO_PLAN.md`](AUDIO_PLAN.md) | Audio production status and batch order |
| [`AUDIO_AGENT_EXECUTION.md`](AUDIO_AGENT_EXECUTION.md) | Audio-agent workflow |
| [`AUDIO_ASSET_MANIFEST.json`](AUDIO_ASSET_MANIFEST.json) | Machine-readable audio queue |
| [`AUDIO_EVENT_MAP.md`](AUDIO_EVENT_MAP.md) | Runtime audio event contract |
| [`GAMEPLAY_ANIMATION_PLAN.md`](GAMEPLAY_ANIMATION_PLAN.md) | Physics-informed animation plan |
| [`ENVIRONMENT_ART_MAP.md`](ENVIRONMENT_ART_MAP.md) | Global environment atlas |
| [`VISUAL_ASSET_MAP.md`](VISUAL_ASSET_MAP.md) | Simulation role to visual asset mapping |
| [`cities/`](cities/) | Per-city inventories, manifests, and receipts |

## Versioning requirements for agents

Before modifying a canonical surface:

1. Read [`VERSIONING.md`](VERSIONING.md).
2. Identify the affected version domain.
3. Increment only that domain.
4. Add deterministic migrations for incompatible runtime, save, receipt, or content changes.
5. Update document metadata when obligations or authority change.
6. Preserve supersession links rather than silently rewriting historical authority.
7. Run `make version-check` and `make validate`.

Root [`README.md`](../README.md) documents the P0–P11 roadmap label and links this index, [`VERSIONING.md`](VERSIONING.md), [`versions.json`](../versions.json), and the roguelike assimilation authority.
