# Surveillance Survivor documentation index

```yaml
version: 1.0.0
status: approved
last_updated: 2026-07-24
supersedes: null
superseded_by: null
authority_scope: repository documentation discovery and source-of-truth routing
```

This page routes contributors and coding agents to the current repository authorities. It summarizes; it does not override the linked documents.

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
| Run-receipt format | `1` |
| Content catalog | `1` |
| Versioning policy | `1.0.0` |
| Roguelike assimilation program | `1.0.0` |

Run `make version-check` before changing or publishing any versioned authority. The full `make validate` gate includes this check.

## Product and engineering authorities

| Reference | Scope |
| --- | --- |
| [`ROADMAP.md`](ROADMAP.md) | Launch lane P0–P7 and systemic design lane P8–P11 |
| [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) | Suspicion Director, city state, build engine, coordination, landmarks, audio, story receipts, replayability |
| [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) | Engineering execution and continuation style |
| [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Device, TestFlight, and release evidence |
| [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md) | Art inventory and sign-off |
| [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) | App Store worksheet and owner-controlled fields |
| [`TEN_CITY_CAMPAIGN_ROSTER.md`](TEN_CITY_CAMPAIGN_ROSTER.md) | Campaign order, cities, landmarks, enemies, and bosses |

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

## Known documentation drift repaired by this index

The repository root README may lag detailed roadmap phrasing. The canonical roadmap currently extends through **P11**, not P7. This index and [`ROADMAP.md`](ROADMAP.md) are authoritative until the root README summary is synchronized.
