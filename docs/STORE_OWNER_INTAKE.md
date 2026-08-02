# Store owner intake — Surveillance Survivor

**Purpose:** finish App Store **OWNER** fields for launch gate `store_metadata`.  
**Worksheet:** [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md)  
**Gate:** `make launch-gate-check` → `store_metadata` must be **READY** with real evidence before TestFlight.

Agents **must not invent** live privacy/support URLs. Fill the blanks below; an agent can then update the worksheet and promote the gate when URLs are live HTTPS.

---

## Required (blocks store READY)

| Field | Proposed / default | Your final value |
| --- | --- | --- |
| Privacy policy URL | *(none — must be live HTTPS)* | `https://________________` |
| Support URL | *(none — must be live HTTPS)* | `https://________________` |
| SKU (immutable once used) | **`SS-IOS-001`** | **Locked** 2026-08-01 |
| Copyright | **`© 2026 Zero State`** (confirm legal name) | `________________` |
| Content rights holder | **Zero State** (confirm) | `________________` |
| Game subcategory | **Action** | **Locked** 2026-08-01 |

Paste answers as:

```text
privacy: https://...
support: https://...
copyright: © 2026 Zero State   # or corrected legal string
rights_holder: Zero State
# already locked: sku=SS-IOS-001 subcategory=Action
```

**Pass 1 done (2026-08-01):** SKU + Action subcategory.  
**Pass 2 needed:** live privacy + support HTTPS (blocks `store_metadata` READY).

---

## Strongly recommended (listing quality)

| Field | Status in repo |
| --- | --- |
| Subtitle | Draft: *Break the surveillance grid* |
| Description / keywords | Draft in `APP_STORE_METADATA.md` |
| Screenshots | Plan ready; capture on **release SHA** from physical iPhone (landscape) |
| Age rating questionnaire | Guidance filled; complete in App Store Connect |
| ASC privacy nutrition labels | Offline MVP basis drafted; enter in Connect |

### Screenshot checklist (device)

```text
commit SHA:
1 title / city select:
2 mid-run combat (player primary, cones readable):
3 upgrade draft:
4 city identity shot:
5 boss:
6 Blind Spot / extract summary:
folder path (local):
```

Prefer 6.7" + 6.1" iPhone sizes Apple currently requires. **Not** README hero art.

---

## Already done (not OWNER)

| Item | Evidence |
| --- | --- |
| App name / bundle | `Surveillance Survivor` / `life.zerostate.surveillancesurvivor` |
| Offline privacy manifest | `App/PrivacyInfo.xcprivacy` — tracking false |
| ART ship (nonblocking notes) | `ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES` |
| Live extracts | Louisville + Tulsa receipts under `docs/device_evidence/` |
| Marketing copy drafts | Description, keywords, review notes |

---

## After you fill URLs

1. Agent updates `APP_STORE_METADATA.md` OWNER rows.  
2. Agent verifies URLs respond over HTTPS (HEAD/GET).  
3. Agent sets launch gate `store_metadata` → **READY** with tip-matched evidence path to this worksheet (only if URLs live).  
4. `make launch-gate-check` + `make release-docs-check`.

Until then: **`store_metadata: BLOCKED`** remains correct.
