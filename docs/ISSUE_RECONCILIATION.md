# GitHub issue reconciliation

**Updated:** 2026-07-24 (post #37 ten-city foundation packs + #38 README; roadmap docs).  
**Live board:** [`REPO_STATUS.md`](REPO_STATUS.md) · **Roadmap:** [`ROADMAP.md`](ROADMAP.md)

Open issues: **#2** (WP1 playable foundation), **#3** (ART production exports).  
Closed: **#4** (WP2A), **#6** (WP2B).  
Open PRs: **none** (city art sequence complete on `main`).

---

## Issue #2 — WP1 Complete playable iPhone foundation

### Original acceptance (summary)

Virtual stick + handedness · entity projection · camera/world bounds · collision · pooling · pause on interruption · resume without duplicates · **physical iPhone** responsiveness · deterministic vs render rate · core + simulator pass.

### Recommendation: **keep open**

| Item | Status |
| --- | --- |
| Stick + handedness | **Done** |
| Entity projection / camera / bounds | **Done** |
| Collision / pooling | **Done** |
| Pause / interruption freeze | **Done** |
| Campaign / extraction / ten-city sim | **Done** |
| Package + simulator / CI | **Done** |
| Physical iPhone full acceptance | **Open** |
| Device background/reopen evidence | **Open** |
| Device frame budget evidence | **Open** |

**Close when:** protocol in [`RELEASE_READINESS.md`](RELEASE_READINESS.md) completed with dated [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) entries for the release SHA.

---

## Issue #3 — ART Convert visual pack v0.1 into production iOS exports

### Original acceptance (summary)

App icon 1024² · player 8-way · LPR 3 states · native suspicion meter · no labels · alpha · names · nearest-neighbor on **device**.

### Recommendation: **keep open** (repo inventory largely complete)

| Item | Status |
| --- | --- |
| App icon | **Attached** |
| Player 8 frames | **Attached** |
| LPR 3 states | **Attached** |
| Blind Spot / tiers / guard / boss | **Attached** |
| Visual role map | **Done** |
| Global env + **10 city foundation packs** | **On `main`** |
| Projectile / deployable textures | **Shape fallback** — owner decision |
| Physical-device readability | **Open** |
| Owner ship approval | **Open** |

Full matrix: [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md).

**Close when:** device ART QA filed + projectile/deployable decision recorded + owner ship note. City packs alone do **not** close #3.

---

## Cross-cutting

- Simulator/CI green **never** closes device language on #2 or #3.  
- Audio is **out of scope** for #2/#3; tracked under audio roadmap (manifest 62 missing).  
- Store listing is **not** a GitHub issue; use [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md).  
- Prefer updating REPO_STATUS / ROADMAP over new issues per city pack.  
