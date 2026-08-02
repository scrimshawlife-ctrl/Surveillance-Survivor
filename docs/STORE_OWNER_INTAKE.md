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

## Still open (blocks full Connect ship / gate READY)

| Field | Notes |
| --- | --- |
| Physical/release screenshots | Sim candidates exist; ship-SHA device recapture preferred for Connect |
| Age rating questionnaire | Complete in App Store Connect |
| ASC privacy labels | Offline MVP basis in worksheet |
| Copyright confirm | If legal name ≠ Zero State LLC |
| Audio rights | Separate gate (`audio_product`) |

---

## Gate posture

- `store_metadata` is **EVIDENCE_INSUFFICIENT** (not READY): live URLs + locked SKU/Action + simulator screenshot candidates.  
- Promote READY only when owner accepts candidates for Connect **or** physical/release stills are tip-matched, and copyright string is confirmed.  
- URLs are **live** and cited from the Zero State website repo.  
- Privacy page currently scopes to the **website**; app is offline — expand site copy later if required by counsel.

```bash
make launch-gate-check release-docs-check
```
