# Store owner intake — Surveillance Survivor

**Purpose:** App Store **OWNER** fields for launch gate `store_metadata`.  
**Worksheet:** [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md)  
**Brand site:** [scrimshawlife-ctrl/zero-state](https://github.com/scrimshawlife-ctrl/zero-state) → https://scrimshawlife-ctrl.github.io/zero-state/

---

## Locked / live (2026-08-01)

| Field | Value | Status |
| --- | --- | --- |
| SKU | `SS-IOS-001` | Locked |
| Game subcategory | Action | Locked |
| Privacy policy URL | https://scrimshawlife-ctrl.github.io/zero-state/privacy.html | **LIVE** (HTTP 200) |
| Support URL | https://scrimshawlife-ctrl.github.io/zero-state/contact.html | **LIVE** (HTTP 200) |
| Product page (optional) | https://scrimshawlife-ctrl.github.io/zero-state/products/surveillance-survivor.html | **LIVE** |
| Terms (optional) | https://scrimshawlife-ctrl.github.io/zero-state/terms.html | **LIVE** |
| Copyright (proposed) | `© 2026 Zero State LLC` | Confirm legal string |
| Rights holder | Zero State LLC | From site privacy notice |

Support contact on site: `admin@lastreetshits.com` (mailto on contact page).

---

## Screenshots (candidates packed)

| Field | Value |
| --- | --- |
| Pack | [`store_screenshots/`](store_screenshots/) + [`manifest.json`](store_screenshots/manifest.json) |
| Count | 6 landscape PNGs (2622×1206) |
| Capture tip | `08042d1` |
| Source | Simulator Debug via `scripts/capture_store_screenshots.sh` |
| Connect note | Prefer physical iPhone **Release** recapture at frozen ship SHA |

## Residual for `store_metadata` READY (RC cut allowed)

| Field | Status | Notes |
| --- | --- | --- |
| Copyright | **OPEN** until owner confirms | Proposed `© 2026 Zero State LLC` |
| Screenshot accept | **OPEN** until owner accepts sim pack or recaptures | Pack: `docs/store_screenshots/` |
| Age rating (Connect) | Open for public submit | **Does not block** RC-allowed gate |
| ASC privacy labels | Open for public submit | **Does not block** RC-allowed gate |

Owner accept line (fill when true):

```text
copyright confirmed (string):
screenshots accepted for RC listing prep: sim pack / physical pack / not yet
date:
```

**Also open (other gates / public submit):**

| Field | Notes |
| --- | --- |
| Audio rights + freeze-tip listening | Separate gate (`audio_product`) — not `store_metadata` |
| Age rating / ASC privacy in Connect | Required for **public** App Store submit; see residual rows above |

---

## Gate posture

- `store_metadata` is **EVIDENCE_INSUFFICIENT** (not READY): live URLs + locked SKU/Action + simulator screenshot candidates.  
- Promote READY for **RC cut allowed** only when owner confirms copyright string **and** accepts sim candidates for Connect prep **or** tip-matched physical/release stills exist.  
- Age rating questionnaire and ASC privacy labels remain open for public submit; they **do not block** `store_metadata` READY for RC-allowed (see [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md)).  
- URLs are **live** and cited from the Zero State website repo.  
- Privacy page currently scopes to the **website**; app is offline — expand site copy later if required by counsel.

```bash
make launch-gate-check release-docs-check
```
