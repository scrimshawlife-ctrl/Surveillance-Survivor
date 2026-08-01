# Operator phone session — post-#153 tip

**When:** phone attached, unlocked, trusted for development.  
**Candidate tip:** re-pin with `git rev-parse --short HEAD` (device evidence tip **`44a204f`**; mechanical **`7c400e7`**).  
**Team (this repo’s recent device runs):** `DEVELOPMENT_TEAM=X9M969D8M3` — override if your team differs.  
**Plan:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md)

**Status:** mechanical suite + live Louisville/Tulsa extracts **filed**. Remaining phone residual is **ART checklist eyes** (and optional listening notes). Agents cannot complete ART ship call.

---

## 0. Pin + honesty gates (laptop, before cable)

```bash
cd /Users/appliedalchemylabs/Documents/Surveillance-Survivor
git pull origin main
git rev-parse HEAD
git status --short
make version-check privacy-check release-docs-check launch-gate-check art-qa-check repo-status-check audio-check
# Expected: launch-gate-check PASS overall=LAUNCH_BLOCKED
# Expected: art-qa-check PASS gate=ART_EVIDENCE_INSUFFICIENT
# Optional: make audio-rights-check  → expect BLOCKED (68 assets, no private evidence yet)
```

Paste SHA + `git status` into a new section of [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md).

---

## 1. Mechanical device suite

**Status 2026-08-01:** **PASS** on tip **`7c400e7`** (iPhone 17 Pro). Skip re-run unless binary tip moves. Receipts in `.device-smoke/` + `.launch-smoke/`; log entry in [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md).

```bash
# Phone unlocked, cable attached, Developer Mode on if prompted
DEVELOPMENT_TEAM=X9M969D8M3 make device-smoke
DEVELOPMENT_TEAM=X9M969D8M3 make device-test
DEVELOPMENT_TEAM=X9M969D8M3 make device-accept
DEVELOPMENT_TEAM=X9M969D8M3 make launch-smoke
```

| Command | Proves | Does **not** prove |
| --- | --- | --- |
| `device-smoke` | Install + process alive | Playability / ART |
| `device-test` | Chrome XCUITests on device | Live extract / eyes |
| `device-accept` | Force-extract summary path | Real Blind Spot find |
| `launch-smoke` | Splash → menu → BEGIN RUN | Combat readability |

Record receipts under `.device-smoke/` / automation paths per [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md).

---

## 2. Live play (human hands)

**Status:** live extracts **PASS** (Louisville + Tulsa). Re-run only if binary tip moved or validating ART.

Play **without** `-UITesting` force scenarios.

| Check | What to look for |
| --- | --- |
| Dynamic stick | Appears **where pressed**; drag to move; lift to clear |
| Auto-fire | Leads moving targets; prioritizes contact threats |
| Cameras | Stationary poles; revolving red cones |
| Suspicion | Rises from scan contact + camera destruction |
| Upgrade draft | Spaced offers; optional **Emergency repair** / **Redundant systems** when damaged |
| Boss bar | Authority integrity as progress, not bare number |
| Blind Spot compass | Cyan chevron when exit off-screen; clears when exit on-screen |
| Extract | Live Blind Spot (prior receipts already in `device_evidence/`) |
| Pause | Background 10s+ resume; no duplicate entities/loops |
| Audio | Speaker balance, mute buses, interruption recovery |

**Primary residual:** fill [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) combat hierarchy + city + ship call.

---

## 3. After the session

1. Complete ART checklist pass/fail (or paste notes for agent to file).  
2. Optional: new extract receipt if tip moved — agent can pull from device prefs.  
3. Tell the agent: tip SHA + ART outcomes. Agent updates board/gates **only** with tip-matched evidence — never invent READY.

---

## Owner (parallel, no phone required)

See [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) OWNER rows and [`audio/rights/EVIDENCE_CHECKLIST.md`](audio/rights/EVIDENCE_CHECKLIST.md):

- Live privacy policy + support HTTPS URLs  
- SKU, copyright, age rating, subcategory  
- Screenshots from **this** release build after phone session  
- Private audio evidence IDs → ledger (public repo stays opaque)  

---

## Authority

| Doc | Role |
| --- | --- |
| [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) | Ordered launch path |
| [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) | Paste template |
| [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) | ART eyes |
| [`launch/launch_gates.json`](launch/launch_gates.json) | Machine gates (stay honest) |
