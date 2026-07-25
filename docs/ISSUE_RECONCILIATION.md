# GitHub issue reconciliation

**Updated:** 2026-07-25 (post #49 art intake + multi-frame player).  
**Live board:** [`REPO_STATUS.md`](REPO_STATUS.md) · **Roadmap:** [`ROADMAP.md`](ROADMAP.md)

Open issues: **#3** (ART production exports).  
Closed: **#2** (WP1), **#4** (WP2A), **#6** (WP2B).  
Open PRs: **none** after #49 (update if a docs PR is open).

**#2 note:** Closed on GitHub 2026-07-24, but [`RELEASE_READINESS.md`](RELEASE_READINESS.md) device matrix rows remain **Pending** without a completed [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) for the current tip. Do not treat GitHub close as ship evidence until the log is filed or the matrix is updated.

---

## Issue #2 — WP1 Complete playable iPhone foundation

### GitHub state: **CLOSED** (2026-07-24)

### Original acceptance (summary)

Virtual stick + handedness · entity projection · camera/world bounds · collision · pooling · pause on interruption · resume without duplicates · **physical iPhone** responsiveness · deterministic vs render rate · core + simulator pass.

### Repo evidence reconciliation

| Item | Status |
| --- | --- |
| Stick + handedness | **Done** |
| Entity projection / camera / bounds | **Done** |
| Collision / pooling | **Done** |
| Pause / interruption freeze | **Done** |
| Campaign / extraction / ten-city sim | **Done** |
| Package + simulator / CI | **Done** |
| Physical iPhone full acceptance | **Not evidenced in DEVICE_TEST_LOG for tip** |
| Device background/reopen evidence | **Pending in RELEASE_READINESS** |
| Device frame budget evidence | **Pending in RELEASE_READINESS** |

**Recommendation:** Keep release matrix honest — either attach a dated device log for the ship SHA or track remaining device work under #3 / RELEASE_READINESS without reopening #2 unless product wants it open again.

---

## Issue #3 — ART Convert visual pack v0.1 into production iOS exports

### Original acceptance (summary)

App icon 1024² · player 8-way · LPR 3 states · native suspicion meter · no labels · alpha · names · nearest-neighbor on **device**.

### Recommendation: **keep open** (repo inventory complete; device + ship note remain)

| Item | Status |
| --- | --- |
| App icon | **Attached** |
| Player idle/walk × 4 dirs | **Attached** + multi-frame (#49) |
| LPR 3 states | **Attached** |
| Blind Spot / tiers / guard / boss | **Attached** |
| Visual role map | **Done** |
| Global env + **10 city foundation packs** | **On `main`** |
| Projectile / deployable textures | **Attached** (#47 candidates → #49 intake) |
| Presentation pipeline | **Done** (#46) |
| Physical-device readability | **Open** |
| Owner ship approval | **Open** |

Full matrix: [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md).

**Close when:** device ART QA checklist filed (incl. projectiles + multi-frame player) + owner ship note on #3 or DEVICE_TEST_LOG. Repo inventory alone does **not** close #3.

---

## Cross-cutting

- Simulator/CI green **never** closes device language on #2 or #3.  
- Audio is **out of scope** for #2/#3; tracked under audio roadmap (manifest 62 missing binaries). Batch **0** inventory is done: [`audio/AUDIO_WORK_RECEIPT.md`](audio/AUDIO_WORK_RECEIPT.md).  
- Store listing is **not** a GitHub issue; use [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md).  
- Prefer updating REPO_STATUS / ROADMAP over new issues per city pack.  
