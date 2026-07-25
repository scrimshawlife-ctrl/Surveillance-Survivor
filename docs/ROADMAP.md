# Product roadmap

**Authority:** this file for *sequenced product outcomes*. Live issue/PR board: [`REPO_STATUS.md`](REPO_STATUS.md). Device evidence protocol: [`RELEASE_READINESS.md`](RELEASE_READINESS.md). Store worksheet: [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md). ART inventory: [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md).

**As of:** 2026-07-25 · tip through #55 Build Engine A. P8 Coordination Graph A in progress.

---

## North star

Ship a **premium, offline-first, landscape iPhone** satirical survivor roguelite: deterministic core, ten-city campaign, readable anti-surveillance fantasy, and no real surveillance feeds or accounts.

The long-range product identity is a **living surveillance-city roguelite**: Suspicion directs pressure, infrastructure changes the battlefield, enemies coordinate through interruptible chains, countermeasure builds create systemic effects, and each run produces an authoritative story receipt.

---

## Phase map

```text
P0   Vertical slice + campaign sim      ████████████ DONE
P1   City foundation art (10 cities)    ████████████ DONE (179 runtime PNGs w/ combat + multi-frame)
P2   Device acceptance                  ░░░░░░░░░░░░ OPEN evidence (#2 closed on GH — logs may lag)
P3   ART production sign-off            █████████░░░ MOSTLY DONE (#3; device QA + ship note open)
P4   Product audio (11 runtime stems)   █░░░░░░░░░░░ Batch 0 done; binaries missing
P5   Store listing + legal              ░░░░░░░░░░░░ OPEN (owner)
P6   TestFlight / App Review            ░░░░░░░░░░░░ BLOCKED on P2–P5
P7   Presentation polish                ████░░░░░░░░ Pipeline + player multi-frame done; optional later
P8   Systemic runtime architecture      █████░░░░░░░ Director + City + Build + Coordination A; Story open
P9   One-district systems proof         ░░░░░░░░░░░░ BLOCKED on fuller P8
P10  Ten-city systemic projection       ░░░░░░░░░░░░ BLOCKED on P9
P11  Replayability + mastery program    ░░░░░░░░░░░░ BLOCKED on P9/P10
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
| 10 × 13 city foundation packs | On `main` |
| P0 combat stills + player multi-frame | #49 · `make assets-check` → **179** PNGs |
| Map / projector / presentation | `VisualAssetMap`, `WorldProjector`, `Game/Presentation` |
| Docs receipts | `docs/cities/*`, `weapon_vfx/`, `animation/` |

No city 11. Mega-atlases and further multi-frame families are **P7**, not blockers for TestFlight.

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
| Player idle/walk × 4 dirs + multi-frame | Attached (#49) |
| LPR three states | Attached |
| Blind Spot, guard, boss, tier glyphs | Attached |
| Env + 10 city packs | Attached |
| Projectile / deployable textures | **Attached** (#47/#49) · shape fallback if missing |
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

### P7 — Optional presentation polish · **PARTIAL**

**Done:** presentation pipeline (#46); player multi-frame idle/walk (#49); P0 combat stills.

**Later (optional):**

- Five-district modular atlases per city  
- Atlanta four-phase boss environment overlays  
- Deployable 3-state strips; enemy/boss multi-frame  
- City ambience / music packages from audio manifest  
- Performance / content balance passes  

### P8 — Systemic runtime architecture · **PARTIAL**

Authority: [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) · director packet [`P8_SUSPICION_DIRECTOR_CONTRACT.md`](P8_SUSPICION_DIRECTOR_CONTRACT.md).

| Outcome | Required evidence | Status |
| --- | --- | --- |
| Suspicion Director contract | deterministic budgets, cooldowns, pressure windows, fixtures | **Done** — #53 · `director_rules.json` · `make director-check` |
| Dynamic City State graph | infrastructure node schema + propagation tests | **Done** — #54 · `make city-state-check` |
| Emergent Build Engine | tag/trigger/transform/evolution schema + validators | **Done** — #55 · `make build-engine-check` |
| Enemy Coordination Graph | domain events + interruptible chain fixtures | **Slice A** — lot capture cascade · `make coordination-check` |
| Run Story facts | receipt schema proving no invented narrative events | Partial — director + city-state + build + coordination |
| New content authorities | bundled JSON schemas and validation coverage | Director + infrastructure + build + coordination |

`RunState` includes `suspicionDirector` + `districtState` + `buildEngine` + `coordination`. Still planned: `run_story_facts`.

### P9 — One-district systems proof · **BLOCKED ON P8**

Prove the full stack in **Big-Box Parking Expanse** before projecting it across ten cities.

Minimum proof package:

- three infrastructure node families;
- six deterministic environmental interactables;
- one readable enemy coordination chain with at least two counterplay points;
- one landmark-scale set piece;
- twelve behavioral upgrades and four multi-system evolutions;
- Suspicion Director encounter budgets;
- adaptive audio hooks;
- authoritative end-of-run story summary;
- three strategically distinct clearing builds;
- physical-device performance receipt.

### P10 — Ten-city systemic projection · **BLOCKED ON P9**

Each city must gain rule-level identity, not only texture identity.

Per-city contract:

- traversal and topology grammar;
- infrastructure profile;
- weather and lighting modifiers;
- civilian and reporting behavior;
- enemy and faction weighting;
- upgrade weighting;
- landmark encounter hooks;
- radio language and audio motif;
- satirical policy modifier;
- deterministic validation fixture and device budget.

### P11 — Replayability and mastery program · **BLOCKED ON P9/P10**

Planned surfaces:

- seeded daily challenges;
- weekly city variants;
- policy mutators and challenge contracts;
- unlockable gadgets, archetypes, factions, weather, events, bosses, and radio sets;
- run history, mastery records, cosmetics, and convenience rewards.

Global permanent damage/health inflation is not the primary progression model.

---

## Systemic design acceptance gates

- identical seed and input trace reproduce director choices and city-state outcomes;
- no hidden damage or health scaling;
- every systemic consequence has a readable visual or audio signal;
- a full run generates a valid story receipt without invented events;
- infrastructure interactions create both benefits and costs;
- every coordination chain has at least two player counterplay points;
- city-specific systems remain inside physical-device performance budgets;
- P8–P11 do not invalidate launch evidence requirements.

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

P0 ──► P8 architecture ──► P9 one-district proof ──► P10 city projection
                                  │                       │
                                  └──────────► P11 ◄──────┘

P2 physical-device evidence gates production claims for P9–P11.
```

---

## Recommended order

### Launch lane — immediate

| Order | Focus | Who |
| ---: | --- | --- |
| 1 | Device ART QA + ship note → close #3 | Operator |
| 2 | Device acceptance protocol; fill `DEVICE_TEST_LOG.md` for tip SHA | Operator + device |
| 3 | Audio Batch 1 after owner ElevenLabs approval | Owner + audio agent |
| 4 | Publish privacy/support URLs; complete ASC drafts | Owner |
| 5 | Capture store screenshots; TestFlight internal | Operator + engineering |

### Systemic design lane — parallel planning; code after P8 contracts

| Order | Focus |
| ---: | --- |
| 1 | **P8** Suspicion Director contracts + fixtures |
| 2 | Dynamic City State graph + schema |
| 3 | Emergent Build Engine |
| 4 | Enemy Coordination Graph |
| 5 | Environmental Weaponization |
| 6 | Adaptive Audio Director hooks |
| 7 | Run Story Compiler |
| 8 | Landmark Encounter Framework |
| 9 | **P9** Big-Box one-district proof |
| 10 | **P10–P11** city projection + replayability |

---

## Explicit non-goals (MVP)

- Online multiplayer, accounts, ads, live location, real camera feeds
- Backend services
- Closing #2/#3 from simulator-only evidence
- Generating product audio before Batch 0 dedup + license review
- Treating README hero / concept boards as App Store screenshots
- Making every P8–P11 epic a blocker for the first TestFlight or App Store candidate
- Hidden adaptive difficulty through undocumented stat scaling
- City variation that changes only textures while mechanics remain identical

---

## Related docs

| Doc | Role |
| --- | --- |
| [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) | Approved systemic design program (P8–P11) |
| [`VERSIONING.md`](VERSIONING.md) · [`versions.json`](../versions.json) | App/build/compatibility versions |
| [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Ship evidence matrix |
| [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md) | ART #3 inventory |
| [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) | Store worksheet |
| [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) | Engineering work style + dual lanes |
| [`REPO_STATUS.md`](REPO_STATUS.md) | Live PR/issue board |
| [`TEN_CITY_CAMPAIGN_ROSTER.md`](TEN_CITY_CAMPAIGN_ROSTER.md) | Content authority |
