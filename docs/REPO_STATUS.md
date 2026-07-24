# Repository status audit

**As of:** 2026-07-24  
**`main` tip:** `0e621ce` — README hero + atlas badges (#38)  
**Prior art tip:** `61f69c8` — final trilogy city packs (#37)  
**Purpose:** single-page PR / issue / task board. Re-run `gh pr list` / `gh issue list` before acting if this may be stale.

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | **None open** |

## Recently merged

| PR | Title |
| ---: | --- |
| [#38](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/38) | docs: beautify README with game-art hero and atlas badges |
| [#37](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/37) | feat(art): final trilogy — NYC, LA, Atlanta |
| [#36](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/36) | Columbus foundation pack |
| [#35](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/35) | San Francisco foundation pack |
| [#34](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/34)–[#28](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/28) | Docs audit + city packs through Wichita |

## Open issues (tasks)

| Issue | Title | Can close? | Blocking work |
| ---: | --- | --- | --- |
| [#2](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/2) | WP1 — Complete playable iPhone foundation | **No** | Physical-device acceptance per [`RELEASE_READINESS.md`](RELEASE_READINESS.md) |
| [#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3) | ART — production iOS exports | **No** | Device art QA; reserved projectile/deployable families; owner art sign-off. Foundation packs alone do **not** close this. |

Closed: #4 WP2A, #6 WP2B.

## Task board (priority)

### Operator-required (cannot finish without human/device)

| # | Task | Issue / doc | Status |
| ---: | --- | --- | --- |
| 1 | Full physical-device acceptance run + receipts | #2 · RELEASE_READINESS | **Pending** |
| 2 | Device frame budget / thermal / haptic / audio-route notes | #2 · RELEASE_READINESS | **Pending** |
| 3 | Approve ElevenLabs candidates + licenses | #3 / audio bible | **Pending** |
| 4 | Device audio acceptance (speakers, BT, silent mode, ducking) | audio docs | **Pending** |
| 5 | App Store owner fields (URLs, SKU, rights, screenshots) | APP_STORE_METADATA | **Pending** |
| 6 | Final art review / optional mega-atlases | #3 · cities/ | **Optional** |

### Autonomous / offline-capable

| # | Task | Status | Notes |
| ---: | --- | --- | --- |
| A | Ten-city foundation art sequence | **Done** | 10×13 packs on `main`; 160 runtime PNGs |
| B | README hero + linked atlas badges | **Done** | #38 |
| C | Audio Batch 0: inventory / dedup / receipts | **Open** | `AUDIO_AGENT_EXECUTION.md` — audit only first |
| D | Audio Batch 1: generate 11 `runtime_required` stems | **Open** | All 11 currently `missing` in manifest |
| E | Wire product audio playback after masters approved | **Open** | Silent fallback until intake |
| F | Reserved entity art (projectile / deployable) | **Open** | Shape-first today |
| G | Doc hygiene: refresh CONTINUATION_PLAN / ISSUE_RECONCILIATION | **Open** | Still mention open Tulsa/Oakland PRs |
| H | Optional: Wichita/Louisville QA reports | **Open** | Cosmetics |
| I | Optional: Atlanta boss-phase environment overlays | **Open** | Beyond foundation |
| J | Optional: five-district modular atlases per city | **Open** | Beyond foundation |

## City foundation packs

| Level | City | Runtime on `main` |
| ---: | --- | --- |
| 1–10 | All ten cities | **13 each** (`wichita_*` … `atlanta_*`) |

`make assets-check` → **160** PNGs green.  
`make audio-check` → manifest valid, **62 assets all `missing`**, 11 runtime-required stems listed.

## Simulation / CI gates

| Gate | Status |
| --- | --- |
| Package tests + content graph | Green on CI |
| Emulator / simulator suite | Green on CI |
| Physical-device acceptance | **Pending** |
| Audio product binaries | **Missing** (queue ready) |
| App Store owner fields | **Pending** |

## Suggested next action

1. **If device online:** run full acceptance for #2 ([`RELEASE_READINESS.md`](RELEASE_READINESS.md)).  
2. **If offline / agent-capable:** Audio Batch 0 inventory + receipts (`make audio-check`, [`AUDIO_AGENT_EXECUTION.md`](AUDIO_AGENT_EXECUTION.md)).  
3. **Do not** generate ElevenLabs production audio before Batch 0 dedup + owner review of candidates.  
4. Keep #2 / #3 open until evidence exists.  
5. No city 11 — foundation art sequence complete.

## Authority pointers

| Doc | Role |
| --- | --- |
| [`cities/README.md`](cities/README.md) | City art workflow |
| [`ENVIRONMENT_ART_MAP.md`](ENVIRONMENT_ART_MAP.md) | Environment atlas |
| [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) | Engineering priorities (**partially stale** vs this board) |
| [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Device evidence protocol |
| [`AUDIO_ASSET_MANIFEST.json`](AUDIO_ASSET_MANIFEST.json) | Audio work queue |
| [`AUDIO_AGENT_EXECUTION.md`](AUDIO_AGENT_EXECUTION.md) | Audio agent procedure |
| Root [`README.md`](../README.md) | Product surface + badges |
