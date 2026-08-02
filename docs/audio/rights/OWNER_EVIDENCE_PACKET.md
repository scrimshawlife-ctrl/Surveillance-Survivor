# Owner evidence packet — audio rights clearance

**Status:** scaffold only — **not cleared**  
**Gate:** `make audio-rights-check` must PASS before `audio_product` may go READY  
**Ledger:** [`AUDIO_RIGHTS_LEDGER.json`](AUDIO_RIGHTS_LEDGER.json)  
**Checklist:** [`EVIDENCE_CHECKLIST.md`](EVIDENCE_CHECKLIST.md)

This packet is the operator/owner fill path for the 68 runtime-integrated audio assets.  
Agents scaffolded **pending** ledger rows and five **unverified** private-archive slots.  
That is **not** commercial clearance.

---

## Do not put in git

Invoices, account IDs, full contracts, personal email, payment screenshots, or raw exports that contain private identifiers. Store those only in the private archive and record opaque fields in the ledger.

---

## Five evidence slots to replace

| Evidence ID | What to file privately | When verified |
| --- | --- | --- |
| `SS-AUD-EV-2026-0001` | Paid-plan invoice / subscription proof active on generation dates (Batch 1/2 ~2026-07-26+) | `verification_status=verified` + real `sha256` + vault locator |
| `SS-AUD-EV-2026-0002` | Applicable ElevenLabs terms / license version (PDF or HTML capture) for Music + Sound Effects | same |
| `SS-AUD-EV-2026-0003` | Written confirmation products used were not Beta **or** separate Beta commercial authorization | same |
| `SS-AUD-EV-2026-0004` | Generation/export/session identifiers for production batches (or batch archive index) | same |
| `SS-AUD-EV-2026-0005` | Owner attestation: no unlicensed reference audio/voice/samples uploaded as inputs | same |

Current ledger digests are **public slot markers** (`private://pending/...`). Replace them after filing.

---

## Per-asset fields the owner must set (batch OK)

After evidence is verified, for each of the 68 shipping `asset_id`s (or once per batch with identical grants):

| Field | Cleared value |
| --- | --- |
| `plan_or_license` | Exact plan or license name (not null) |
| `terms_version` | Version / effective date string |
| `beta_status` | `confirmed_not_beta` or `beta_separately_cleared` |
| `commercial_use` | `allowed` (only if grant covers it) |
| `modification` | match grant (usually `allowed` for game mix) |
| `sublicensing` | match grant (platforms / App Store) |
| `third_party_ip_review` | `passed` after review |
| `rights_status` | `cleared` **only last** |
| `reviewer` / `review_date` | named human + ISO date |

Interactive game + storefront + marketing uses are already declared under `release_intent` in the ledger — confirm the license covers them.

---

## Validate

```bash
make audio-rights-check
# Expect: AUDIO RIGHTS GATE: PASS — 68 shipping asset(s) cleared.
```

Then record tip-matched physical-device listening notes in [`DEVICE_TEST_LOG.md`](../../DEVICE_TEST_LOG.md) (speaker, headphones, silent mode, interruption, route change, dense mix).  
`audio_product` READY requires **rights PASS + listening**, not rights alone.

## Freeze-tip listening (launch residual)

Rights PASS alone does **not** make `audio_product` READY. After rights PASS, complete **Listening (freeze tip)** in [`docs/DEVICE_TEST_LOG.md`](../../DEVICE_TEST_LOG.md) on the frozen ship SHA. Residual path: [`docs/launch/TESTFLIGHT_RC_RESIDUAL.md`](../../launch/TESTFLIGHT_RC_RESIDUAL.md) §B.

---

## Explicit non-claims

- Scaffold ≠ clearance.  
- Manifest `license` strings ≠ proof.  
- Batch receipts ≠ commercial grant archive.  
- Agents must never set `rights_status=cleared` or invent private digests.
