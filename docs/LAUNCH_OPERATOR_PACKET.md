# Launch operator packet

**Purpose:** single entry for human/device work that **agents cannot complete**.
**Candidate at write:** merged `main` release-preparation candidate — record the final merge SHA before device execution.
**Historical device automation:** 2026-07-26 14:22 PDT `make device-accept` passed on `47b1f5b` (smoke + force-extract; see `DEVICE_TEST_LOG`); this must be rerun for the merged candidate.
**Repo art gate:** `ART_EVIDENCE_INSUFFICIENT` until the live ART checklist + extract are complete for the final merge SHA.

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

## Machine truth (agents)

| Artifact | Role |
| --- | --- |
| [`launch/launch_gates.json`](launch/launch_gates.json) | Per-gate status + evidence pointers |
| [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) | How agents promote/demote without inventing green |
| `make launch-gate-check` | Honesty check (PASS + `LAUNCH_BLOCKED` is normal) |

Human ordered steps below are unchanged. Agents must not mark gates READY without tip-matched evidence paths.

---

## Ordered steps

### 1. Deploy proof (not acceptance)

```bash
# Auto-select connected iPhone, or pass DEVICE_UDID=
DEVELOPMENT_TEAM=<team> make device-smoke    # install + launch + process liveness
DEVELOPMENT_TEAM=<team> make device-test     # smoke + chrome XCUITests + receipt
DEVELOPMENT_TEAM=<team> make device-accept   # smoke + mechanical force-extract UI (not ART ship)
```

See [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md). Record SHA, device, iOS, date in `DEVICE_TEST_LOG` deployment section.
`device-accept` proves Blind Spot summary UI on device; **it does not** complete ART eyes / owner #3.

### 2. Full device acceptance + ART (blocks art ship)

1. Signed Debug play on the candidate release tip.
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

Confirm audio rights, then perform physical-device listening for speaker/headphone balance, silent mode, interruptions, route changes, and dense-combat clipping. The 68-asset bank is integrated. **Never** add system-sound placeholders.

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
make launch-gate-check art-qa-check assets-check animation-check weapon-vfx-check test
```
