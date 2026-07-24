# Repository status audit

**As of:** 2026-07-24  
**`main` tip:** `c0f6373` — `feat(art): Dayton Gateway City foundation pack (#31)`  
**Purpose:** single-page PR / issue / city-art board for continuation agents. Re-run `gh pr list` / `gh issue list` before acting if this file may be stale.

> **Post-merge note (2026-07-24):** Tulsa #33, Oakland #32, and docs #34 are on `main`. San Francisco foundation pack is the active open PR when this branch lands.

## Open pull requests

| PR | Title | Branch | Base | Notes |
| ---: | --- | --- | --- | --- |
| [#32](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/32) | Oakland Sanctuary Scanner foundation pack | `agent/oakland-city-environment-pack` | `main` | 13 × `oakland_*`; merge when CI green (rebased after Dayton) |
| [#33](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/33) | Tulsa Petroleum Panopticon foundation pack | `agent/tulsa-city-environment-pack` | `main` | 13 × `tulsa_*`; fills L3 gap; independent of #32 |

**Merge order guidance:** either #32 or #33 may land first (independent tips off Dayton `main`). After both merge, update this file and [`cities/README.md`](cities/README.md). Prefer merge-when-green only when `core-tests` + `simulator` are fully green (no pending duplicates).

## Recently merged (art / campaign track)

| PR | Title | Merged |
| ---: | --- | --- |
| [#31](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/31) | Dayton Gateway City foundation pack | 2026-07-24 |
| [#30](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/30) | docs: city environment status (Wichita + Louisville) | 2026-07-24 |
| [#29](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/29) | Louisville Derby Day Data Dragnet city pack | 2026-07-24 |
| [#28](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/28) | Wichita city foundation pack | 2026-07-24 |
| [#27](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/27) | Environment package v1 | 2026-07-24 |
| [#26](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/26) | Long sprint: campaign integrity + emulator evidence | 2026-07-24 |
| [#25](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/25) | Guard and boss runtime sprites | 2026-07-24 |

Earlier: visual asset map (#21), audio event-map (#20), campaign unlocks (#18), simulator CI (#17), emulator smokes (#19/#23/#24).

## Open issues

| Issue | Title | Recommendation |
| ---: | --- | --- |
| [#2](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/2) | WP1 — Complete playable iPhone foundation | **Keep open.** Code + emulator complete; needs physical-device acceptance receipts ([`RELEASE_READINESS.md`](RELEASE_READINESS.md)). |
| [#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3) | ART — Convert visual pack v0.1 into production exports | **Keep open.** Core v0.1 + env v1 + city foundations substantially landed; device art QA + reserved projectile/deployable families + owner sign-off remain. |

Closed work packages: #4 (WP2A countermeasures), #6 (WP2B Redaction/Identity). No other open issues at audit time.

Detail: [`ISSUE_RECONCILIATION.md`](ISSUE_RECONCILIATION.md).

## City foundation packs

| Level | City | Runtime on `main` | Docs on `main` | Open PR |
| ---: | --- | --- | --- | --- |
| 1 | Wichita | 13 × `wichita_*` | yes | — |
| 2 | Louisville | 13 × `louisville_*` | yes | — |
| 3 | Tulsa | **not on main** | not on main | [#33](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/33) |
| 4 | Dayton | 13 × `dayton_*` | yes | — |
| 5 | Oakland | **not on main** | not on main | [#32](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/32) |
| 6–10 | SF → Atlanta | not started | — | — |

Also on `main`: global env package v1 (10 env textures), player/LPR/guard/boss/Blind Spot/suspicion tiers. Runtime sprite count on `main` at audit: **69** PNGs under `Resources/RuntimeSprites/`.

All ten cities have **simulation profiles** in `districts.json` regardless of art pack status.

## Simulation / product gates

| Gate | Status |
| --- | --- |
| Package tests / content graph | Green on `main` |
| Emulator suite (`make emulator-test`) | Implemented; CI `core-tests` + `simulator` |
| Physical-device acceptance | **Pending** — iPhone offline historically |
| Audio product playback | **Blocked** — event map dry-run only |
| App Store owner fields | **Pending** |

## Suggested continuation (for the next operator prompt)

1. Merge **#33 Tulsa** and **#32 Oakland** when green (independent).  
2. Land docs refresh (this audit) on `main`.  
3. Next city art: **San Francisco — Fog of Probable Cause** (after #32/#33).  
4. Or operator path: device acceptance / audio binaries / store metadata.  
5. Do **not** close issues #2/#3 without device evidence.

## Authority pointers

| Doc | Role |
| --- | --- |
| [`cities/README.md`](cities/README.md) | City production workflow + status table |
| [`ENVIRONMENT_ART_MAP.md`](ENVIRONMENT_ART_MAP.md) | Global + city projection rules |
| [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) | Engineering priorities |
| [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Device evidence protocol |
| Root [`README.md`](../README.md) | Product + implementation status |
