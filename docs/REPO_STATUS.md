# Repository status audit

**As of:** 2026-07-24  
**Local `main` tip:** `c9fdeed` — Atlanta Flock's Nest integrated with NYC + LA packs  
**Remote `origin/main` tip:** `6841f2f` — ElevenLabs audio continuation docs/tooling (no city packs beyond Columbus)  
**Purpose:** single-page PR / issue / city-art board for continuation agents. Re-run `gh pr list` / `gh issue list` and `git fetch` before acting if this file may be stale.

> **Critical divergence:** local `main` is **ahead 7 / behind 6** relative to `origin/main`. Local holds NYC + LA + Atlanta foundation packs; remote holds newer audio docs/validators only. **Rebase or merge is required before any push.** No open PRs for the final trilogy (GitHub PR create was 500ing earlier; API now responds again).

## Open pull requests

| PR | Title | Notes |
| ---: | --- | --- |
| — | *(none open)* | Last city art PR: **#36 Columbus** (merged) |

## Recently merged (art / campaign track)

| PR | Title | Merged |
| ---: | --- | --- |
| [#36](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/36) | Columbus Six-Hundred-Eye Statehouse foundation pack | 2026-07-24 |
| [#35](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/35) | San Francisco Fog of Probable Cause foundation pack | 2026-07-24 |
| [#34](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/34) | docs: repo audit — PR/issue/city pack status | 2026-07-24 |
| [#33](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/33) | Tulsa Petroleum Panopticon foundation pack | 2026-07-24 |
| [#32](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/32) | Oakland Sanctuary Scanner foundation pack | 2026-07-24 |
| [#31](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/31) | Dayton Gateway City foundation pack | 2026-07-24 |
| [#30](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/30) | docs: city environment status (Wichita + Louisville) | 2026-07-24 |
| [#29](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/29) | Louisville Derby Day Data Dragnet city pack | 2026-07-24 |
| [#28](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/28) | Wichita city foundation pack | 2026-07-24 |
| [#27](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/27) | Environment package v1 | 2026-07-24 |

Earlier: visual asset map (#21), audio event-map (#20), campaign unlocks (#18), simulator CI (#17), emulator smokes (#19/#23/#24).

## Open issues

| Issue | Title | Recommendation |
| ---: | --- | --- |
| [#2](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/2) | WP1 — Complete playable iPhone foundation | **Keep open.** Code + emulator complete; needs physical-device acceptance receipts ([`RELEASE_READINESS.md`](RELEASE_READINESS.md)). |
| [#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3) | ART — Convert visual pack v0.1 into production exports | **Keep open.** All ten city **foundation** packs exist on **local** `main`; device art QA, reserved projectile/deployable families, and owner sign-off remain. Do not close on foundation packs alone. |

Closed work packages: #4 (WP2A countermeasures), #6 (WP2B Redaction/Identity).

Detail: [`ISSUE_RECONCILIATION.md`](ISSUE_RECONCILIATION.md) (may lag this file).

## City foundation packs

| Level | City | Local `main` runtime | Local docs | On `origin/main` | Open PR |
| ---: | --- | --- | --- | --- | --- |
| 1 | Wichita | 13 × `wichita_*` | yes | yes (#28) | — |
| 2 | Louisville | 13 × `louisville_*` | yes (no separate QA file) | yes (#29) | — |
| 3 | Tulsa | 13 × `tulsa_*` | yes | yes (#33) | — |
| 4 | Dayton | 13 × `dayton_*` | yes | yes (#31) | — |
| 5 | Oakland | 13 × `oakland_*` | yes | yes (#32) | — |
| 6 | San Francisco | 13 × `san_francisco_*` | yes | yes (#35) | — |
| 7 | Columbus | 13 × `columbus_*` | yes | yes (#36) | — |
| 8 | New York City | 13 × `new_york_*` | yes | **no** | none (local only) |
| 9 | Los Angeles | 13 × `los_angeles_*` | yes | **no** | none (local only) |
| 10 | Atlanta | 13 × `atlanta_*` | yes | **no** | none (local only) |

Also: global env package v1, player/LPR/guard/boss/Blind Spot/suspicion tiers.  
**Local runtime sprite count:** **160** PNGs under `Resources/RuntimeSprites/` (`make assets-check` green).  
**Remote** still ends city art at Columbus (sprite count lower).

All ten cities have **simulation profiles** in `districts.json` regardless of remote art status.

## Wiring integrity (local)

| Check | Status |
| --- | --- |
| `GameAssetName` city enums | Wichita…Atlanta (incl. NewYork, LosAngeles, Atlanta) |
| `VisualAssetMap.terrainRole` / `skylineRole` | All ten districts city-specific |
| `WorldProjector` | Per-city landmarks/overlays/obstacles |
| `validate_visual_assets.sh` | All ten city prefixes allow-listed |
| `VisualAssetMapTests` | Terrain/skyline roles for all ten |

## Simulation / product gates

| Gate | Status |
| --- | --- |
| Package tests / content graph | Green (local) |
| Emulator suite (`make emulator-test`) | Implemented; CI `core-tests` + `simulator` |
| Physical-device acceptance | **Pending** — deferred historically |
| Audio product playback | **In progress on remote** — ElevenLabs queue/bible/validators (origin ahead) |
| App Store owner fields | **Pending** |

## Suggested continuation

1. **Integrate divergence:** rebase local city tip onto `origin/main` (or merge origin into local) so audio docs + NYC/LA/Atlanta coexist, then open one PR (or three) for final-trilogy art.  
2. Do **not** force-push over remote audio commits.  
3. Issues **#2** / **#3** stay open until device evidence + ART sign-off.  
4. Optional hygiene: Louisville/Wichita `*_QA_REPORT.md`; optional Columbus hearing-reschedule chroma cleanup; full mega-atlases / Atlanta boss-phase overlays later.  
5. Campaign city-art foundation sequence is **complete locally** — no city 11.

## Authority pointers

| Doc | Role |
| --- | --- |
| [`cities/README.md`](cities/README.md) | City production workflow + status table |
| [`ENVIRONMENT_ART_MAP.md`](ENVIRONMENT_ART_MAP.md) | Global + city projection rules |
| [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) | Engineering priorities |
| [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Device evidence protocol |
| [`AUDIO_ASSET_PRODUCTION_BIBLE.md`](AUDIO_ASSET_PRODUCTION_BIBLE.md) | Audio production (see origin for latest queue docs) |
| Root [`README.md`](../README.md) | Product + implementation status |
