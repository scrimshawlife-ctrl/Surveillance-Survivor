# Launch operator packet

**Purpose:** single entry for human/device work that **agents cannot complete**.  
**Candidate at write:** re-pin with `git rev-parse HEAD`. Device evidence tip **`44a204f`** (dynamic stick) + mechanical **`7c400e7`**.  
**Plan:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) · **Phone script:** [`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md)  
**Mechanical device automation:** 2026-08-01 — `device-smoke` + `device-test` + `device-accept` + `launch-smoke` **PASS** on **`7c400e7`**.  
**Live extracts:** Louisville (`7c400e7`) + Tulsa (`44a204f`) — [`device_evidence/`](device_evidence/).  
**ART residual:** operator approved for now → **`ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES`** ([`art_qa/art_qa_audit.json`](art_qa/art_qa_audit.json)).  
**Next human residual:** store OWNER fields + audio rights/listening.

---

## Authority

| Doc | Role |
| --- | --- |
| [`RELEASE_READINESS.md`](RELEASE_READINESS.md) | Full acceptance protocol |
| [`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md) | Copy-paste device session for current tip |
| [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) | Paste physical observations + receipt JSON |
| [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) | Combat + city readability on device |
| [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md) | Inventory + ship note (GitHub #3 closed; gate still honest) |
| [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) | Store OWNER fields |
| [`audio/rights/README.md`](audio/rights/README.md) | Audio chain-of-title package |
| [`art_qa/art_qa_audit.json`](art_qa/art_qa_audit.json) | Machine `ship_gate` (repo honesty) |

---

## Machine truth (agents)

| Artifact | Role |
| --- | --- |
| [`launch/launch_gates.json`](launch/launch_gates.json) | Per-gate status + evidence pointers |
| [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) | How agents promote/demote without inventing green |
| `make launch-gate-check` | Honesty check (PASS + `LAUNCH_BLOCKED` is normal) |
| `make audio-rights-check` | Fail-closed rights (exit 1 / BLOCKED until private evidence) |

Human ordered steps below are unchanged. Agents must not mark gates READY without tip-matched evidence paths.

---

## Ordered steps

### 0. Pin the candidate

Run from a clean checkout after all intended pull requests are merged:

```bash
git rev-parse HEAD
git status --short
make version-check privacy-check release-docs-check launch-gate-check art-qa-check
```

Copy the SHA and status output into [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md). Do not reuse an earlier device receipt after the candidate SHA changes.

### 1. Deploy proof (not acceptance)

```bash
# Auto-select connected iPhone, or pass DEVICE_UDID=
DEVELOPMENT_TEAM=<team> make device-smoke    # install + launch + process liveness
DEVELOPMENT_TEAM=<team> make device-test     # smoke + chrome XCUITests + receipt
DEVELOPMENT_TEAM=<team> make device-accept   # smoke + mechanical force-extract UI (not ART ship)
DEVELOPMENT_TEAM=<team> make launch-smoke    # splash → start menu → BEGIN RUN (no -UITesting)
```

See [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md) and [`OPERATOR_PHONE_SESSION.md`](OPERATOR_PHONE_SESSION.md). Record SHA, device, iOS, date in `DEVICE_TEST_LOG` deployment section.  
`device-accept` proves Blind Spot summary UI on device; **it does not** complete ART eyes or live extract.

### 2. Full device acceptance + ART (blocks art ship)

1. Signed Debug play on the candidate release tip.
2. Complete [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) combat hierarchy lines.
3. Complete [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) acceptance + combat readability + optional P11.
4. One **live** extract (not force); paste **COPY RECEIPT JSON**. After #153, confirm Blind Spot compass when exit is off-screen.
5. Max density / p95 if possible.
6. Owner ship note: gate remains honest even though GitHub #3 is closed — file evidence in logs / art_qa paths.

When step 2 is green for a tip, an agent may update `art_qa_audit.json` → `ART_SHIP_APPROVED` **only** with `device_evidence_paths` pointing at those log entries. `make art-qa-check` enforces that honesty.

### 3. Store (OWNER)

Complete OWNER rows in [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md):

- Privacy policy URL (live HTTPS)
- Support URL (live HTTPS)
- SKU, copyright, age rating, game subcategory
- Screenshots from **release** iPhone build (not README hero)

Screenshot plan includes combat-readable mid-run (player primary, projectiles readable).

### 4. Audio (OWNER)

1. Populate private evidence archive; commit only opaque IDs/hashes into [`audio/rights/AUDIO_RIGHTS_LEDGER.json`](audio/rights/AUDIO_RIGHTS_LEDGER.json) per [`audio/rights/EVIDENCE_CHECKLIST.md`](audio/rights/EVIDENCE_CHECKLIST.md).
2. Run `make audio-rights-check` until **PASS** (currently **BLOCKED** for all 68 shipping assets — intentional).
3. Physical-device listening: speaker/headphone balance, silent mode, interruptions, route changes, dense-combat clipping. The 68-asset bank is integrated. **Never** add system-sound placeholders.

### 5. TestFlight

Only after 2–4 are not blockers for the intended RC.

---

## Agent / operator boundary

| Agent may | Operator/owner must |
| --- | --- |
| Keep boards + checklists accurate | Physical iPhone pass |
| Code presentation remediations | Tip-matched log SHA |
| `make art-qa-check` gate honesty | Store URLs + screenshots |
| Inventory-first art wiring | Audio license evidence + stems listening |
| `make audio-rights-check` honesty | Private evidence archive |

---

## Quick repo gates (not ship approval)

```bash
make release-docs-check launch-gate-check art-qa-check assets-check animation-check weapon-vfx-check test
make audio-check
# make audio-rights-check   # expect BLOCKED until ledger evidence
```
