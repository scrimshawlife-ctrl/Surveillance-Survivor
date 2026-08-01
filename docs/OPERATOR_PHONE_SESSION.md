# Operator phone session — post-#153 tip

**When:** phone attached, unlocked, trusted for development.  
**Candidate tip:** re-pin with `git rev-parse --short HEAD` (expected lineage: playability `e9e1717` + board/rights/`#151` after).  
**Team (this repo’s recent device runs):** `DEVELOPMENT_TEAM=X9M969D8M3` — override if your team differs.

This is the **only** work still required for P2 mechanical + P3 ART start. Agents cannot complete it.

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

## 2. Live play (human hands) — post-#153 focus

Play **without** `-UITesting` force scenarios where possible.

| Check | What to look for after #153 |
| --- | --- |
| Analog stick | Speed scales with travel, not on/off |
| Auto-fire | Leads moving targets; prioritizes contact threats |
| Cameras | Stationary poles; revolving red cones |
| Suspicion | Rises from scan contact + camera destruction |
| Upgrade draft | Spaced offers; optional **Emergency repair** / **Redundant systems** when damaged |
| Boss bar | Authority integrity as progress, not bare number |
| Blind Spot compass | Cyan chevron when exit off-screen; clears when exit on-screen |
| Extract | **Live** reach Blind Spot (not force); COPY RECEIPT JSON |
| Pause | Background 10s+ resume; no duplicate entities/loops |
| Audio | Speaker balance, mute buses, interruption recovery (see log template) |

Fill [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) combat hierarchy lines.

---

## 3. After the session

1. Paste observations + receipt into [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) for **this SHA only**.  
2. Note pass/fail for live extract and ART eyes.  
3. Tell the agent: tip SHA + which steps passed. Agent may then update board/gates **only** with tip-matched evidence paths — never invent READY.

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
