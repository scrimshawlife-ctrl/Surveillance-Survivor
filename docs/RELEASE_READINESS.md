# Release readiness evidence

## Authority and status

Implements the verification strategy in Notion and repository gates. Distinguishes **reproducible repository evidence** from **physical iPhone observations**.

| Field | Value |
| --- | --- |
| **Status** | **Simulator-ready · not release-ready** |
| **As of** | 2026-07-25 · tip includes animation Batch 0+1 (#46) |
| **Roadmap** | [`ROADMAP.md`](ROADMAP.md) (phases P0–P7) |
| **ART inventory** | [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md) |
| **Store worksheet** | [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) |
| **Task board** | [`REPO_STATUS.md`](REPO_STATUS.md) |

Do **not** claim release-ready until every **Pending** physical-device row has a dated receipt and store owner fields are complete.

**On `main` (does not replace device rows):** ten-city simulation + unlocks, visual asset map, global env v1, **all ten city foundation packs**, README hero, audio/weapon-vfx/animation **manifests** + Batch 0 receipts, presentation pipeline (`Game/Presentation`), audio dry-run (**no** product WAVs), weapon P0 stills not runtime-integrated (shape fallbacks).
---

## Release readiness scorecard

| Domain | Repo-available | Human / device | Overall |
| --- | --- | --- | --- |
| Gameplay core + campaign | Done | — | **Ready for TestFlight engineering builds** once device acceptance starts |
| City / character art attachment | Done (160 PNGs) | Device readability + owner ART sign-off | **Mostly ready** (#3) |
| Emulator / CI | Green | — | **Ready** |
| Physical-device acceptance | Smoke deploy only | Full protocol | **Blocked** (#2) |
| Product audio binaries | Queue only (62 missing) | License + generation + device audio | **Blocked** |
| App Store listing | Drafts in worksheet | URLs, SKU, screenshots, ASC privacy | **Blocked** |

---

## Reproducible local gate

```bash
make validate
# includes: privacy, assets, audio-check, weapon-vfx-check, animation-check, tests, simulator
```

Also useful:

```bash
make assets-check       # 160 runtime PNGs expected on current main
make audio-check        # manifest schema; binaries still missing is OK
make weapon-vfx-check   # P0 stems registered; binaries optional until intake
make animation-check    # presentation doctrine + clip queue
make emulator-test      # full automated simulator suite
DEVICE_UDID=<udid> make device-smoke   # signed install + launch only
```

A green `make validate` proves compile + core/simulator checks. It does **not** prove thermal, real frame pacing, or store legality.

---

## Evidence matrix

### A. Repository / CI (verified)

| Requirement | Evidence | Status |
| --- | --- | --- |
| Fixed-step deterministic sim + ordered receipts | `swift test` / CI `core-tests` | **Verified** |
| Suspicion, LPR, upgrades, boss, extraction | `SimulationTests.swift` | **Verified** |
| Contact damage, sensor freeze, non-extract defeat | Same | **Verified** |
| Ten-city catalog + campaign unlocks | Core + emulator catalog tests | **Verified** |
| Settings, touch, receipt persistence | `SurveillanceSurvivorTests` / CI `simulator` | **Verified** |
| Visual asset map + city packs attached | `make assets-check` (160 PNGs) | **Verified** |
| Privacy manifest present | `make privacy-check`, `App/PrivacyInfo.xcprivacy` | **Verified** (re-review on SDK changes) |
| Audio **catalog + manifest** | `audio_events.json`, `AUDIO_ASSET_MANIFEST.json` | **Verified** (playback off) |
| App Store **scaffold** | `APP_STORE_METADATA.md` | **Verified** (owner fields open) |

### B. Physical device (pending)

| Requirement | Evidence required | Status |
| --- | --- | --- |
| Signed Debug deploy + launch | `make device-smoke` | **Done historically** (2026-07-22 smoke only) |
| One full accepted extract run | [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) + receipt JSON | **Pending** |
| Frame p50 / p95 / max at max density | Overlay timings + Instruments | **Pending** (instrumented in code) |
| p95 ≤ 16.67 ms (60 fps budget) | Device log | **Pending** |
| Background ≥10s resume, no duplicates | Device log | **Pending** |
| Thermal / touch reachability / haptic clarity | Device notes + optional recording | **Pending** |
| Audio route / interruption recovery | Device notes | **Pending** (meaningful after product audio) |
| ART nearest-neighbor readability | ART checklist in [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md) | **Pending** |

### C. Store / legal (owner)

| Requirement | Status |
| --- | --- |
| Privacy policy URL (live HTTPS) | **Pending owner** |
| Support URL (live HTTPS) | **Pending owner** |
| SKU, copyright, age rating, game subcategory | **Pending owner** |
| Truthful release-build screenshots | **Pending** (device + release config) |
| ASC privacy questionnaire vs shipped binary | **Pending** |
| Rights confirmation | **Pending owner** |

---

## Physical-device protocol

Use a landscape iPhone, signed development build. Record **device model, iOS version, commit SHA, run seed, date** on every receipt.

1. `DEVICE_UDID=<udid> make device-smoke` — prove install/launch only.  
2. Fresh run: movement, auto-fire, LPR contact, tier escalation.  
3. Destroy LPR → pick upgrade → confirm choice in completion receipt.  
4. Defeat Shift Manager → enter Blind Spot → relaunch → summary persists.  
5. On-screen pause freeze/resume; separately background ≥10s; no duplicate ticks/entities/upgrades. Record HUD seed.  
6. Max projectile/deployable loadout; capture p50/p95/max; compare p95 to **16.67 ms**.  
7. Handedness, scale/opacity, reduced motion/flash, haptics reachable.  
8. ART checklist ([`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)).  
9. Audio interruption/route notes (required before claiming audio-ready).  

Completion overlay: p50/p95/max + **COPY RECEIPT JSON**.

Template: [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md).

---

## Release receipt template

```text
date:
device model:
iOS version:
commit SHA:
build configuration:
seed:
run result: extracted / failed
run receipt location:
frame p50 / p95 / max (ms):
background-resume result:
touch/accessibility result:
ART readability result:
thermal observation:
audio interruption / route-change result:
haptic observation:
reviewer:
```

---

## Gate → issue mapping

| Gate | Issue / doc | Close when |
| --- | --- | --- |
| Device acceptance | **#2** | Protocol complete + logs filed |
| ART production | **#3** | Inventory + device ART QA + owner decision on shapes |
| Store listing | APP_STORE_METADATA | Owner URLs + screenshots + ASC |
| Audio product | AUDIO_* docs | Masters + integration (optional for first TestFlight if silent OK) |

---

## Known non-release blockers (summary)

1. Full physical-device acceptance not filed in-repo.  
2. Owner privacy/support URLs, SKU, copyright, age rating, screenshots incomplete.  
3. Product audio binaries all still `missing` in manifest.  
4. Simulator/CI green does not substitute for thermal, real frame pacing, or store legal.  
5. Projectile/deployable remain shape-first until owner decides.  

---

## What “ready for internal TestFlight” means

Minimum bar (engineering recommendation):

- [x] `make validate` green on the tagged SHA  
- [ ] At least one device extract acceptance log for that SHA  
- [ ] ART device readability pass recorded  
- [ ] Privacy + support URLs live (Apple will require for public App Store; TestFlight internal may still want them)  
- [ ] Screenshots optional for **internal** TestFlight; required for App Review  

“Ready for **App Review**” = above + full store worksheet + ASC privacy + marketing screenshots from release build.
