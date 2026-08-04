# GitHub issue reconciliation

**Updated:** 2026-08-04 (Prabu hygiene audit; tip `8aa525d`).  
**Live board:** [`REPO_STATUS.md`](REPO_STATUS.md) · **Roadmap:** [`ROADMAP.md`](ROADMAP.md) · **Phone:** [`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md)

Open issues: **none**.  
Closed: **#2** (WP1), **#3** (ART inventory), **#4** (WP2A), **#6** (WP2B).  
Open PRs: **#155** (Prabu audio suspend — CI green), **#156** (urban arena — baseline FAIL), **#158** (Prabu hygiene boards).  
Landed since prior reconcile: #148 rights, #151 allowlist, #153 playability stack, #154 residual docs, #157 sprite prompts.

**#2 / #3 note:** Closed on GitHub does **not** equal ship evidence. Device matrix and ART gate remain **Pending / ART_EVIDENCE_INSUFFICIENT** until tip-matched [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) and ART checklist are filed.

---

## Issue #2 — WP1 Complete playable iPhone foundation

### GitHub state: **CLOSED** (2026-07-24)

### Repo evidence reconciliation

| Item | Status |
| --- | --- |
| Stick + handedness / entity projection / bounds | **Done** |
| Collision / pooling / pause / interruption | **Done** (pause lifecycle hardened in #153) |
| Campaign / extraction / ten-city sim | **Done** |
| Package + simulator / CI | **Done** (273 / 416 / 14 baseline) |
| Physical iPhone full acceptance for **current tip** | **Not evidenced** — re-run [`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md) |

---

## Issue #3 — ART Convert visual pack v0.1 into production iOS exports

### GitHub state: **CLOSED** (2026-07-25)

| Item | Status |
| --- | --- |
| App icon / player / LPR / Blind Spot / tiers / guard / boss | **Attached** |
| Visual role map + 10 city foundation packs | **On main** |
| Presentation pipeline | **Done** |
| Physical-device readability | **Open** — checklist + eyes on device |
| Owner ship approval / tip-matched evidence | **Open** — gate stays `ART_EVIDENCE_INSUFFICIENT` |

**Close of the GitHub issue does not flip the machine art ship gate.**

---

## Cross-cutting

- Simulator/CI green **never** closes device language.  
- Audio binaries: **68/68 integrated**. Rights: package on main, `make audio-rights-check` **BLOCKED** until private evidence.  
- Store listing: [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) OWNER rows.  
- Prefer updating REPO_STATUS / launch gates over reopening closed issues for ship work.
