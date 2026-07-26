# Launch operator packet

**Purpose:** single entry for human/device work that **agents cannot complete**.  
**Tip at write:** `8a84315` (pause meter #96 on chrome #95 + device automation #94) — re-record SHA when the binary changes.  
**Device-smoke:** 2026-07-25 19:17 PDT dual-launch pass on tip `8a84315` (see `DEVICE_TEST_LOG` Deployment).  
**Repo art gate:** `ART_EVIDENCE_INSUFFICIENT` until step 2 is filled for this tip.

---

## Authority

| Doc | Role |
| --- | --- |
| [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Full acceptance protocol |
| [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) | Paste physical observations + receipt JSON |
| [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) | Combat + city readability on device |
| [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md) | Issue #3 inventory + ship note |
| [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) | Store OWNER fields |
| [`art_qa/art_qa_audit.json`](art_qa/art_qa_audit.json) | Machine `ship_gate` (repo honesty) |

---

## Ordered steps

### 1. Deploy proof (not acceptance)

```bash
# Auto-select connected iPhone, or pass DEVICE_UDID=
DEVELOPMENT_TEAM=<team> make device-smoke   # install + launch + process liveness
DEVELOPMENT_TEAM=<team> make device-test    # smoke + XCUITests + .device-smoke/device-receipt.json
```

See [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md). Record SHA, device, iOS, date in `DEVICE_TEST_LOG` deployment section. Automated suite ≠ step 2 acceptance.

### 2. Full device acceptance + ART (blocks art ship)

1. Signed Debug play on tip **`8a84315` or newer**.  
2. Complete [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) combat hierarchy lines.  
3. Complete [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) acceptance + combat readability + optional P11.  
4. One full extract; paste **COPY RECEIPT JSON**.  
5. Max density / p95 if possible.  
6. Owner: ship approval yes/no on GitHub #3.

When step 2 is green for a tip, an agent may update `art_qa_audit.json` → `ART_SHIP_APPROVED` **only** with `device_evidence_paths` pointing at those log entries. `make art-qa-check` enforces that honesty.

### 3. Store (OWNER)

Complete OWNER rows in [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md):

- Privacy policy URL (live HTTPS)  
- Support URL (live HTTPS)  
- SKU, copyright, age rating, game subcategory  
- Screenshots from **release** iPhone build (not README hero)  

Screenshot plan includes combat-readable mid-run (player primary, projectiles readable).

### 4. Audio (OWNER)

ElevenLabs license → Audio Batch 1. **Never** system-sound placeholders. Catalog is already in-repo.

### 5. TestFlight

Only after 2–4 are not blockers for the intended RC.

---

## Agent / operator boundary

| Agent may | Operator/owner must |
| --- | --- |
| Keep boards + checklists accurate | Physical iPhone pass |
| Code presentation remediations | Tip-matched log SHA |
| `make art-qa-check` gate honesty | Store URLs + screenshots |
| Inventory-first art wiring | Audio license + stems |

---

## Quick repo gates (not ship approval)

```bash
make art-qa-check assets-check animation-check weapon-vfx-check test
```
