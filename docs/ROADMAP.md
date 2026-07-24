# Product roadmap

**Authority:** this file for *sequenced product outcomes*. Live issue/PR board: [`REPO_STATUS.md`](REPO_STATUS.md). Device evidence protocol: [`RELEASE_READINESS.md`](RELEASE_READINESS.md). Store worksheet: [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md). ART inventory: [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md).

**As of:** 2026-07-24 · ten city packs (#37), README/docs (#38–#40), collision/BG fix (#41), Audio Batch 0 receipts.

---

## North star

Ship a **premium, offline-first, landscape iPhone** satirical survivor roguelite: deterministic core, ten-city campaign, readable anti-surveillance fantasy, and no real surveillance feeds or accounts.

---

## Phase map

```text
P0  Vertical slice + campaign sim     ████████████ DONE
P1  City foundation art (10 cities)   ████████████ DONE
P2  Device acceptance                 ░░░░░░░░░░░░ OPEN (#2)
P3  ART production sign-off           ████████░░░░ MOSTLY DONE (#3)
P4  Product audio (11 runtime stems)  ░░░░░░░░░░░░ OPEN
P5  Store listing + legal             ░░░░░░░░░░░░ OPEN (owner)
P6  TestFlight / App Review           ░░░░░░░░░░░░ BLOCKED on P2–P5
P7  Optional content polish           ░░░░░░░░░░░░ LATER
```

---

## Phase details

### P0 — Vertical slice + campaign simulation · **DONE**

| Outcome | Evidence |
| --- | --- |
| Fixed-step deterministic sim | CI `core-tests` |
| Suspicion, LPR, upgrades, boss, Blind Spot | Simulation tests |
| Ten-city `districts.json` + unlocks | Catalog + campaign tests |
| Emulator suite | `make emulator-test` / CI `simulator` |

### P1 — City environment foundation art · **DONE**

| Outcome | Evidence |
| --- | --- |
| Global env package v1 | `env_*` runtime sprites |
| 10 × 13 city foundation packs | `make assets-check` → 160 PNGs |
| Map / projector wiring | `VisualAssetMap`, `WorldProjector` |
| Docs receipts | `docs/cities/*` |

No city 11. Mega-atlases are **P7**, not blockers for TestFlight.

### P2 — Physical-device acceptance · **OPEN** (issue **#2**)

Cannot be closed from the repository alone.

| Outcome | Protocol |
| --- | --- |
| Full extract run on signed Debug | [`RELEASE_READINESS.md`](RELEASE_READINESS.md) + [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) |
| Frame p95 ≤ 16.67 ms at max density | Device receipt + Instruments |
| Background ≥10s resume without duplicates | Device log |
| Accessibility / haptics / thermal notes | Device log |
| Audio route / interruption (once product audio exists) | Device log |

**Repo-available now:** `DEVICE_UDID=… make device-smoke` (deploy only; not acceptance).

### P3 — ART production sign-off · **MOSTLY DONE** (issue **#3**)

| Outcome | Status |
| --- | --- |
| App icon 1024² | Attached |
| Player 8-way idle/walk | Attached |
| LPR three states | Attached |
| Blind Spot, guard, boss, tier glyphs | Attached |
| Env + 10 city packs | Attached |
| Projectile / deployable textures | **Shape fallback** — owner decision |
| Nearest-neighbor readability on device | **Needs device** |
| Owner “ship this art” approval | **Needs owner** |

Full matrix: [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md).

### P4 — Product audio · **OPEN** (Batch 0 done)

| Batch | Outcome | Gate |
| --- | --- | --- |
| 0 | Inventory / hash / dedup / receipts | **Done** — [`audio/AUDIO_WORK_RECEIPT.md`](audio/AUDIO_WORK_RECEIPT.md) |
| 1 | ElevenLabs **11** `runtime_required` stems | Owner license + review |
| 2 | Wire playback (no silent-only path for required stems) | Catalog + tests |
| 3 | Reserved city/ambience/boss music | After deterministic hooks |

Manifest: 62 assets, **all `missing` binaries**, schema valid (`make audio-check`). Repo scan found **0** audio files; nothing to reuse before Batch 1.

### P5 — Store listing + legal · **OPEN** (owner)

| Outcome | Source |
| --- | --- |
| Privacy + support URLs live | Owner publish |
| SKU, copyright, age rating, subcategory | Owner / ASC |
| Release-build screenshots | Device + store build |
| ASC privacy questionnaire | Match `PrivacyInfo.xcprivacy` + binary |

Worksheet with drafts: [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md).

### P6 — TestFlight / App Review · **BLOCKED**

Depends on **P2 + P3 device/ART sign-off + P5 URLs/screenshots**. Product audio (P4) may ship as silent stubs only if review notes say so; prefer Batch 1 before marketing push.

### P7 — Optional polish · **LATER**

- Five-district modular atlases per city  
- Atlanta four-phase boss environment overlays  
- Projectile / deployable art families  
- City ambience / music packages from audio manifest  
- Performance / content balance passes  

---

## Dependency graph

```text
P0 ──► P1 ──► P3 (art inventory complete)
 │              │
 │              ▼
 └──► P2 (device) ──► P6 (TestFlight / Review)
              ▲
 P4 audio ────┤  (can parallel after Batch 0)
 P5 store ────┘  (owner parallel anytime)
```

---

## Recommended order (next 30 days)

| Week | Focus | Who |
| ---: | --- | --- |
| 1 | Device acceptance protocol (#2); fill DEVICE_TEST_LOG | Operator + device |
| 1 | Audio Batch 0 complete; Batch 1 after owner ElevenLabs OK | Owner + audio agent |
| 2 | ART device readability pass; decide projectile shapes forever | Operator |
| 2–3 | Publish privacy + support URLs; complete ASC drafts | Owner |
| 3 | Capture store screenshots from accepted build | Operator |
| 3–4 | TestFlight internal; fix device issues | Engineering |

---

## Explicit non-goals (MVP)

- Online multiplayer, accounts, ads, live location, real camera feeds  
- Backend services  
- Closing #2/#3 from simulator-only evidence  
- Generating product audio before Batch 0 dedup + license review  
- Treating README hero / concept boards as App Store screenshots  

---

## Related docs

| Doc | Role |
| --- | --- |
| [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Ship evidence matrix |
| [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md) | ART #3 inventory |
| [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) | Store worksheet |
| [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) | Engineering work style |
| [`REPO_STATUS.md`](REPO_STATUS.md) | Live PR/issue board |
| [`TEN_CITY_CAMPAIGN_ROSTER.md`](TEN_CITY_CAMPAIGN_ROSTER.md) | Content authority |
