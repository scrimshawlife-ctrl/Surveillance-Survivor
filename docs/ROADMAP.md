# Product roadmap

**Authority:** this file for *sequenced product outcomes*. Live issue/PR board: [`REPO_STATUS.md`](REPO_STATUS.md). Device evidence protocol: [`RELEASE_READINESS.md`](RELEASE_READINESS.md). Store worksheet: [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md). ART inventory: [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md).

**As of:** 2026-07-31 · gameplay anchor `0a2219e`; non-device baseline is 268 package / 397 simulator / 14 UI tests. P10/P11 and the 68-asset audio bank are implemented; launch remains blocked on physical-device/ART, store-owner, and audio listening/rights gates.

---

## North star

Ship a **premium, offline-first, landscape iPhone** satirical survivor roguelite: deterministic core, ten-city campaign, readable anti-surveillance fantasy, and no real surveillance feeds or accounts.

The long-range product identity is a **living surveillance-city roguelite**: Suspicion directs pressure, infrastructure changes the battlefield, enemies coordinate through interruptible chains, countermeasure builds create systemic effects, and each run produces an authoritative story receipt.

---

## Phase map

```text
P0   Vertical slice + campaign sim      ████████████ DONE
P1   City foundation art (10 cities)    ████████████ DONE (194 validated runtime PNGs)
P2   Device acceptance                  ░░░░░░░░░░░░ OPEN evidence (#2 closed on GH — logs may lag)
P3   ART production sign-off            █████████░░░ MOSTLY DONE (#3; device QA + ship note open)
P4   Product audio (68 integrated assets)██████████░░ Repo complete; device listening pending
P5   Store listing + legal              ░░░░░░░░░░░░ OPEN (owner)
P6   TestFlight / App Review            ░░░░░░░░░░░░ BLOCKED on P2–P5
P7   Presentation polish                ████████░░░░ Pipeline + multi-frame + floors/HUD + combat hierarchy
P8   Systemic runtime architecture      ████████████ DONE (Director→Story + contracts)
P9   One-district systems proof         ████████░░░░ Interactables + landmarks + builds on main
P10  Ten-city systemic projection       ████████████ DONE (#69–#73 systems + offer bias)
P11  Replayability + mastery program    █████████░░░ A–D + trail/floors/challenges (#74–#80)
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
| Advanced simulator QA | 268 package + 397 simulator + 14 UI tests; `make simulator-visual-stress` · `make launch-smoke` |

### P1 — City environment foundation art · **DONE**

| Outcome | Evidence |
| --- | --- |
| Global env package v1 | `env_*` runtime sprites |
| 10 × 13 city foundation packs | On `main` |
| P0 combat stills + player multi-frame | #49 · `make assets-check` → **194** PNGs |
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

### P4 — Product audio · **REPOSITORY COMPLETE** (device listening pending)

| Batch | Outcome | Gate |
| --- | --- | --- |
| 0 | Inventory / hash / dedup / receipts | **Done** — [`audio/AUDIO_WORK_RECEIPT.md`](audio/AUDIO_WORK_RECEIPT.md) |
| 1 | Generate, master, and deliver the approved runtime bank | **Done** — 68 WAV masters + 68 CAF derivatives |
| 2 | Wire event cues and state-projected ambience/music with silent missing-asset behavior | **Done** — `AudioBank` + `AudioCuePlayer` + tests |
| 3 | Ten-city ambience, run/boss music, shared beds, and Atlanta phase loops | **Done** — state-projected without changing simulation authority |

Manifest: 68 assets, **all `runtime_integrated`**, with 68 masters and 68 CAF delivery derivatives. `make audio-check` enforces provenance, hashes, catalog parity, and runtime coverage. Physical-device listening and mix acceptance remain open.

### P5 — Store listing + legal · **OPEN** (owner)

| Outcome | Source |
| --- | --- |
| Privacy + support URLs live | Owner publish |
| SKU, copyright, age rating, subcategory | Owner / ASC |
| Release-build screenshots | Device + store build |
| ASC privacy questionnaire | Match `PrivacyInfo.xcprivacy` + binary |

Worksheet with drafts: [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md).

### P6 — TestFlight / App Review · **BLOCKED**

Depends on **P2 + P3 device/ART sign-off + P5 URLs/screenshots**. P4 is repository-complete but still needs physical-device listening evidence before audio-ready claims.

### P7 — Optional presentation polish · **PARTIAL**

**Done:** presentation pipeline (#46); player multi-frame idle/walk (#49); P0 combat stills; title screen, analog movement, damage vignette, held-target reticle, predictive interception, threat-priority targeting, and campaign-wide combat tuning (#145).

**Later (optional):**

- Five-district modular atlases per city
- Atlanta four-phase boss environment overlays
- Deployable 3-state strips; enemy/boss multi-frame
- Physical-device mix and route/interruption tuning for the integrated audio bank
- Performance / content balance passes

### P8 — Systemic runtime architecture · **PARTIAL**

Authority: [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) · director packet [`P8_SUSPICION_DIRECTOR_CONTRACT.md`](P8_SUSPICION_DIRECTOR_CONTRACT.md).

| Outcome | Required evidence | Status |
| --- | --- | --- |
| Suspicion Director contract | deterministic budgets, cooldowns, pressure windows, fixtures | **Done** — #53 · `director_rules.json` · `make director-check` |
| Dynamic City State graph | infrastructure node schema + propagation tests | **Done** — #54 · `make city-state-check` |
| Emergent Build Engine | tag/trigger/transform/evolution schema + validators | **Done** — #55 · `make build-engine-check` |
| Enemy Coordination Graph | domain events + interruptible chain fixtures | **Done** — #56 · `make coordination-check` |
| Run Story facts | receipt schema proving no invented narrative events | **Slice A** — #this · `make story-check` · receipt v7 |
| New content authorities | bundled JSON schemas and validation coverage | Director + city + build + coordination + story |

`RunState` / receipt carry director, district, build, coordination, and compiled `storyFacts`.

### P9 — One-district systems proof · **IN PROGRESS**

Prove the full stack in **Big-Box Parking Expanse** before projecting it across ten cities.
Live checklist: [`P9_BIG_BOX_PROOF.md`](P9_BIG_BOX_PROOF.md).

Minimum proof package:

- three infrastructure node families; **met** (Wichita graph)
- six deterministic environmental interactables; **slice A**
- one readable enemy coordination chain with at least two counterplay points; **met**
- one landmark-scale set piece; **slice A** (Wichita big-box anchor + receipt v9)
- twelve behavioral upgrades and four multi-system evolutions; **met** (content)
- Suspicion Director encounter budgets; **met**
- adaptive audio hooks; complete repository integration through event cues and state-projected ambience/music, with physical-device mix acceptance still open
- authoritative end-of-run story summary; **met**
- three strategically distinct clearing builds; **slice A** (quiet_ghost / paper_bureaucracy / flood_risk)
- physical-device performance receipt; operator

### P10 — Ten-city systemic projection · **DONE** (#69–#73)

Live board: [`P10_CITY_PROJECTION.md`](P10_CITY_PROJECTION.md).
All ten cities have rule-level identity + full systems packages; upgrade offer bias wired.

Remaining operator-only: device budget fixtures / #3 evidence.

### P11 — Replayability and mastery program · **IN PROGRESS (A–D live)**

Live board: [`P11_REPLAYABILITY.md`](P11_REPLAYABILITY.md).

Surfaces:

- seeded daily challenges; **done** (resolver + contracts + UI)
- weekly city variants; **done**
- policy mutators and challenge contracts; **done** (combat + label mutators)
- unlockable cosmetics / radio / weather / motifs; **done** (presentation grants + HUD)
- run history + mastery records; **done** (store + streaks)
- remaining: optional multi-frame cosmetics art, launch-lane device evidence

Global permanent damage/health inflation is not the primary progression model.

---

## Simulator visual matrix and regression receipts — **SLICES A–F DONE**

**Delivered:** repeatable, reviewable density evidence across **all ten campaign cities**, with per-city normalized screenshots, per-city smoke receipts, one aggregate fail-closed receipt, and CI artifact upload.

### Scope

1. Add scenario parameters for every `DistrictID`; **done (10/10)**.
2. Capture normalized landscape screenshots for:
   - clean launch;
   - authored city identity under ordinary combat;
   - max-density combat;
   - reduced-motion + reduced-flash presentation.
3. Write one machine-readable matrix receipt containing commit SHA, scenario, district, seed contract, dimensions, artifact paths, and pass/fail checks; **done**.
4. Add fail-closed checks for missing/blank screenshots, wrong orientation, and mismatched scenario/district receipts; **done**. HUD/chrome is covered by XCUITest; city asset contracts are covered by existing visual-asset tests.
5. Upload the matrix directory in CI without treating pixel-perfect diffs as a release gate; **done**.

### Acceptance

- `make simulator-visual-matrix` produces all ten cities in both ordinary-combat and reduced-presentation variants non-interactively; **pass (20/20)**;
- every screenshot is landscape-normalized and tied to the current commit;
- representative city assets and gameplay chrome are asserted by code/UI tests;
- artifacts remain gitignored and CI-retained;
- docs explicitly state that the matrix does not prove thermal, touch, haptic, audio-route, or physical-device ART acceptance.

### Slice B complete

- ordinary-combat and reduced-motion/reduced-flash variants cover all ten cities;
- the matrix emits a generated labeled contact sheet beside its aggregate receipt;
- semantic checks bind every panel to unique catalog city name, title, mechanic, boss, scenario, district, and accessibility metadata without brittle pixel-perfect golden comparisons.

### Slice C complete

- per-panel luminance, contrast, color, blank-frame fractions, and fingerprints support regression triage;
- paired combat/reduced metrics are summarized in machine-readable JSON and reviewer-friendly Markdown;
- compact history entries can be retained across CI runs, while only broad blank/flat capture sanity bounds fail the build.

### Slice D complete

- optional prior history entries produce aggregate luminance-range and paired-fingerprint trend deltas;
- advisory anomaly annotations request human contact-sheet review but never fail CI for visual drift;
- CI retains branch-local history through run-unique caches and handles cold-cache runs as a valid `no-baseline` state.

### Slice E complete

- schema-2 history retains per-city/per-variant metrics while accepting legacy aggregate baselines;
- city-level luminance or contrast shifts generate linked JSON, Markdown, and HTML reviewer bundles;
- anomaly bundles identify exact combat/reduced panels for human review and remain advisory-only.

### Slice F complete

- `qa/non-device-baseline.json` is the fail-closed authority for validated package, simulator, and UI counts;
- JSON, Markdown, and HTML QA indexes unify test baselines, receipts, contact sheet, trends, and reviewer bundles;
- index generation rejects commit mismatches, missing linked evidence, and structurally invalid baseline registries.

### Slice G complete

- CI extracts package, simulator-hosted, and UI counts from the completed test logs in a dependent baseline job;
- exact registry drift fails closed while increases have a deterministic refresh command;
- count decreases require an explicit review reason and retain previous/new counts plus the reviewed commit.

### Slice H complete

- the 20-panel matrix now builds once and installs once per worker instead of installing for every capture;
- a visually inspected one-second deterministic settle reduced the measured matrix from roughly 140 seconds to 69.9 seconds;
- identical clean simulator replicas support bounded opt-in parallelism, with deterministic task partitioning and cleanup, while the measured single-worker path remains the default because extra simulators increased host contention.

### Non-goals

- brittle pixel-for-pixel golden tests across Xcode/iOS runtime versions;
- replacing the physical-device combat-readability checklist;
- generating new enemy/boss animation art in this slice.

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
| 3 | Confirm audio rights and complete physical-device listening, routing, interruption, and dense-mix acceptance | Owner + operator |
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
