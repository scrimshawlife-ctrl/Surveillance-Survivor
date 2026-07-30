# Launch Path (Machine-Honest Gates) Implementation Plan

> **Historical implementation plan (2026-07-26).** Literal fixtures and examples below intentionally preserve the then-current catalog-only state. Current reality is 68/68 audio assets integrated; release readiness still requires rights confirmation and physical-device listening/routing/interruption/mix evidence.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land a machine-checkable launch gate system (`docs/launch/launch_gates.json` + `make launch-gate-check`) so agents and boards always report honest blocked/ready state without inventing device, store, audio, or ART approvals.

**Architecture:** A single JSON gate manifest is the source of machine truth. A Python validator (mirroring `scripts/validate_art_qa_package.py`) enforces schema, evidence paths, tip matching, dependencies, and ART consistency. Checker exit 0 means the file is *honest* (overall may still be `LAUNCH_BLOCKED`). Human evidence stays in existing docs; agents promote/demote gates only when the checker would pass. continue-ss and board docs *read* the gates (v1: no auto-edit of JSON in the workflow).

**Tech Stack:** Python 3 (stdlib only: `json`, `pathlib`, `subprocess`, `sys`, `unittest` or plain assert runner), GNU Make, Markdown docs, Rhai workflow prompt strings.

**Spec:** [`docs/superpowers/specs/2026-07-26-launch-path-design.md`](../specs/2026-07-26-launch-path-design.md)

## Global Constraints

- Do **not** invent device receipts, store URLs, ElevenLabs stems, or set `ART_SHIP_APPROVED` without tip-matched evidence paths.
- Checker **PASS** ≠ `LAUNCH_READY`. Honest `LAUNCH_BLOCKED` must exit 0.
- Do **not** require `LAUNCH_READY` for CI merge; only honesty via `validate`.
- Tip for `READY` match = current checkout short SHA (`git rev-parse --short HEAD`). No automatic docs-only tip lag.
- ART ship rules remain owned by `make art-qa-check` / `scripts/validate_art_qa_package.py`.
- No product/game Swift code changes in this plan.
- Prefer small focused commits per task.
- Repo root: `/Users/appliedalchemylabs/Documents/Surveillance-Survivor` (or the worktree in use).

## File map

| Path | Responsibility |
| --- | --- |
| `docs/launch/launch_gates.json` | Machine gate statuses + evidence pointers |
| `docs/launch/AGENT_LAUNCH_PLAYBOOK.md` | Agent promote/demote + board hygiene rules |
| `scripts/validate_launch_gates.py` | Honesty checker CLI |
| `scripts/testdata/launch/` | Fixture JSON for validator unit tests |
| `scripts/test_validate_launch_gates.py` | Runnable unit tests for the checker |
| `Makefile` | `launch-gate-check` target; add to `validate` |
| `docs/LAUNCH_OPERATOR_PACKET.md` | Pointer to machine truth |
| `docs/CONTINUATION_PLAN.md` | Authority map row |
| `docs/CONTINUATION_PROMPT.md` | Prompt authority + commands |
| `docs/REPO_STATUS.md` | Board rows from launch gates |
| `.grok/workflows/continue-ss.rhai` | Inventory/audit read launch gates |

---

### Task 1: Seed `launch_gates.json` (honest blocked)

**Files:**
- Create: `docs/launch/launch_gates.json`

**Interfaces:**
- Produces: gate IDs `device_acceptance`, `art_ship`, `store_metadata`, `audio_product`, `testflight_rc`; statuses never `READY` at seed
- Consumes: none

- [ ] **Step 1: Resolve current tip**

```bash
cd /Users/appliedalchemylabs/Documents/Surveillance-Survivor
TIP=$(git rev-parse --short HEAD)
echo "TIP=$TIP"
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Expected: short SHA printed (e.g. `8c5fd9d` or later).

- [ ] **Step 2: Create seed JSON**

Create `docs/launch/launch_gates.json` with this shape (replace `TIP` and `UPDATED` with values from Step 1):

```json
{
  "schema_version": 1,
  "updated_utc": "UPDATED",
  "overall": "LAUNCH_BLOCKED",
  "overall_note": "Derived: any required gate not READY. Checker exit 0 means honest, not ship-ready.",
  "gates": {
    "device_acceptance": {
      "status": "EVIDENCE_INSUFFICIENT",
      "tip_sha_short": "TIP",
      "evidence_paths": ["docs/DEVICE_TEST_LOG.md"],
      "reason": "No tip-matched full device acceptance + extract receipt; historical smokes are deployment-only or older SHAs",
      "owner": "operator",
      "depends_on": []
    },
    "art_ship": {
      "status": "EVIDENCE_INSUFFICIENT",
      "tip_sha_short": "TIP",
      "evidence_paths": [],
      "reason": "Align with art_qa ship_gate ART_EVIDENCE_INSUFFICIENT until tip-matched ART device checklist",
      "owner": "operator",
      "depends_on": ["device_acceptance"]
    },
    "store_metadata": {
      "status": "BLOCKED",
      "tip_sha_short": null,
      "evidence_paths": ["docs/APP_STORE_METADATA.md"],
      "reason": "OWNER privacy/support URLs, SKU, screenshots open",
      "owner": "owner",
      "depends_on": []
    },
    "audio_product": {
      "status": "BLOCKED",
      "tip_sha_short": null,
      "evidence_paths": ["docs/AUDIO_ASSET_MANIFEST.json"],
      "reason": "No licensed product stems; catalog only; never system-sound placeholders",
      "owner": "owner",
      "depends_on": []
    },
    "testflight_rc": {
      "status": "BLOCKED",
      "tip_sha_short": null,
      "evidence_paths": [],
      "reason": "RC cut blocked until device_acceptance, art_ship, store_metadata, audio_product are READY",
      "owner": "shared",
      "depends_on": [
        "device_acceptance",
        "art_ship",
        "store_metadata",
        "audio_product"
      ]
    }
  }
}
```

Notes:
- `evidence_paths` on non-READY gates may point at worksheets (paths must exist). Empty arrays are OK for blocked gates without a file yet.
- `docs/AUDIO_ASSET_MANIFEST.json` must exist; if it does not, use `docs/AUDIO_PLAN.md` instead after verifying with `ls`.

- [ ] **Step 3: Verify required evidence files exist**

```bash
test -f docs/DEVICE_TEST_LOG.md
test -f docs/APP_STORE_METADATA.md
ls docs/AUDIO_ASSET_MANIFEST.json docs/AUDIO_PLAN.md 2>/dev/null
python3 -m json.tool docs/launch/launch_gates.json > /dev/null
```

Expected: all tests succeed; JSON parses.

- [ ] **Step 4: Commit**

```bash
git add docs/launch/launch_gates.json
git commit -m "$(cat <<'EOF'
docs(launch): seed honest-blocked launch_gates.json

Machine source of truth for launch blockers. No READY gates.
EOF
)"
```

---

### Task 2: Validator unit tests (fail first)

**Files:**
- Create: `scripts/testdata/launch/honest_blocked.json` (copy of seed shape; tip field `"deadbeef"` so tests inject tip)
- Create: `scripts/testdata/launch/ready_all.json`
- Create: `scripts/testdata/launch/ready_without_evidence.json`
- Create: `scripts/testdata/launch/stale_tip.json`
- Create: `scripts/testdata/launch/missing_path.json`
- Create: `scripts/testdata/launch/dependency_break.json`
- Create: `scripts/test_validate_launch_gates.py`
- Create: `scripts/validate_launch_gates.py` (minimal stub that always fails until Task 3)

**Interfaces:**
- Produces: `validate_launch_gates.validate_data(data, root, tip_short) -> list[str]` error codes/messages; `main() -> int`
- Consumes: seed schema from Task 1

- [ ] **Step 1: Write fixture files**

Create directory `scripts/testdata/launch/`.

`honest_blocked.json` — same structure as seed; all gates non-READY; `device_acceptance.evidence_paths` = `["docs/DEVICE_TEST_LOG.md"]` if that path will exist under test root (tests use repo root).

`ready_without_evidence.json` — one gate `device_acceptance` with `"status": "READY"`, `"tip_sha_short": "WILL_INJECT"`, `"evidence_paths": []`.

`stale_tip.json` — `device_acceptance` READY with evidence path that exists (`docs/DEVICE_TEST_LOG.md`), `tip_sha_short` = `"0000000"`.

`missing_path.json` — READY with `evidence_paths: ["docs/launch/DOES_NOT_EXIST.md"]` and tip will match.

`dependency_break.json` — `art_ship` READY with existing evidence + matching tip, but `device_acceptance` still `EVIDENCE_INSUFFICIENT`.

`ready_all.json` — all five gates READY, tip `WILL_INJECT`, evidence paths pointing only at real repo files:

```text
docs/DEVICE_TEST_LOG.md
docs/ART_DEVICE_QA_CHECKLIST.md
docs/APP_STORE_METADATA.md
docs/AUDIO_ASSET_MANIFEST.json   # or AUDIO_PLAN.md
docs/LAUNCH_OPERATOR_PACKET.md   # for testflight_rc optional path
```

Also set `depends_on` correctly. For tests, ART consistency: either set `art_ship` READY only when art_qa would allow — for fixture simplicity, Task 3 implementation should treat ART inconsistency as: if `art_ship` is READY and `docs/art_qa/art_qa_audit.json` has `ship_gate` of `ART_EVIDENCE_INSUFFICIENT` **and** no usable device evidence on the art package, emit `ART_INCONSISTENT`. For `ready_all` fixture used with a **temp art audit override** or skip ART file by testing `ART_INCONSISTENT` in a dedicated fixture `art_inconsistent.json` where launch `art_ship` is READY but art_qa is still `ART_EVIDENCE_INSUFFICIENT` without device_evidence_paths.

Create `art_inconsistent.json`: art_ship READY + good paths + matching tip; device_acceptance READY; others BLOCKED is fine for dependency — wait, art depends on device so device must be READY too. store/audio can stay BLOCKED. testflight not READY. art_qa on disk remains insufficient → ART_INCONSISTENT.

- [ ] **Step 2: Write `scripts/test_validate_launch_gates.py`**

```python
#!/usr/bin/env python3
"""Unit tests for validate_launch_gates.py (stdlib unittest)."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))

import validate_launch_gates as v  # noqa: E402

FIXTURES = Path(__file__).resolve().parent / "testdata" / "launch"


def load(name: str) -> dict:
    return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


def current_tip() -> str:
    return subprocess.check_output(
        ["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True
    ).strip()


class ValidateLaunchGatesTests(unittest.TestCase):
    def test_honest_blocked_no_errors(self) -> None:
        data = load("honest_blocked.json")
        errors = v.validate_data(data, ROOT, current_tip())
        self.assertEqual(errors, [], errors)

    def test_ready_without_evidence(self) -> None:
        data = load("ready_without_evidence.json")
        tip = current_tip()
        data["gates"]["device_acceptance"]["tip_sha_short"] = tip
        errors = v.validate_data(data, ROOT, tip)
        self.assertTrue(any("READY_WITHOUT_EVIDENCE" in e for e in errors), errors)

    def test_stale_tip(self) -> None:
        data = load("stale_tip.json")
        errors = v.validate_data(data, ROOT, current_tip())
        self.assertTrue(any("STALE_TIP" in e for e in errors), errors)

    def test_missing_path(self) -> None:
        data = load("missing_path.json")
        tip = current_tip()
        data["gates"]["device_acceptance"]["tip_sha_short"] = tip
        errors = v.validate_data(data, ROOT, tip)
        self.assertTrue(any("MISSING_PATH" in e for e in errors), errors)

    def test_dependency_break(self) -> None:
        data = load("dependency_break.json")
        tip = current_tip()
        for g in data["gates"].values():
            if g.get("status") == "READY":
                g["tip_sha_short"] = tip
        errors = v.validate_data(data, ROOT, tip)
        self.assertTrue(any("DEPENDENCY" in e for e in errors), errors)

    def test_art_inconsistent(self) -> None:
        data = load("art_inconsistent.json")
        tip = current_tip()
        for g in data["gates"].values():
            if g.get("status") == "READY":
                g["tip_sha_short"] = tip
        errors = v.validate_data(data, ROOT, tip)
        self.assertTrue(any("ART_INCONSISTENT" in e for e in errors), errors)

    def test_overall_blocked_derived(self) -> None:
        data = load("honest_blocked.json")
        overall = v.derive_overall(data)
        self.assertEqual(overall, "LAUNCH_BLOCKED")


if __name__ == "__main__":
    raise SystemExit(unittest.main())
```

Adjust fixture gate keys so each fixture is valid schema-wise except the intended fault.

- [ ] **Step 3: Stub validator so imports work but tests fail**

Create `scripts/validate_launch_gates.py`:

```python
#!/usr/bin/env python3
"""Validate docs/launch/launch_gates.json honesty. See design 2026-07-26."""

from __future__ import annotations

from pathlib import Path
from typing import Any


def derive_overall(data: dict[str, Any]) -> str:
    raise NotImplementedError


def validate_data(
    data: dict[str, Any], root: Path, tip_short: str
) -> list[str]:
    raise NotImplementedError


def main() -> int:
    print("launch-gate-check: not implemented", flush=True)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: Run tests — expect FAIL**

```bash
cd /Users/appliedalchemylabs/Documents/Surveillance-Survivor
python3 scripts/test_validate_launch_gates.py -v
```

Expected: FAIL with `NotImplementedError` or assertion failures.

- [ ] **Step 5: Commit tests + stub + fixtures**

```bash
git add scripts/validate_launch_gates.py scripts/test_validate_launch_gates.py scripts/testdata/launch
git commit -m "$(cat <<'EOF'
test(launch): fail-first fixtures for launch-gate-check

Stub validator; unit tests for honesty error classes.
EOF
)"
```

---

### Task 3: Implement `validate_launch_gates.py`

**Files:**
- Modify: `scripts/validate_launch_gates.py` (full implementation)

**Interfaces:**
- Consumes: schema from Task 1; ART file at `docs/art_qa/art_qa_audit.json`
- Produces:
  - `REQUIRED_GATES: list[str]`
  - `STATUSES = {"BLOCKED", "EVIDENCE_INSUFFICIENT", "READY", "N_A"}`
  - `derive_overall(data) -> "LAUNCH_BLOCKED" | "LAUNCH_READY"`
  - `validate_data(data, root, tip_short) -> list[str]` each error prefixed with code e.g. `STALE_TIP: ...`
  - `main() -> int` reads `docs/launch/launch_gates.json`, resolves tip via git, prints PASS/FAIL

- [ ] **Step 1: Implement validation logic**

Full implementation requirements:

```python
REQUIRED_GATE_IDS = [
    "device_acceptance",
    "art_ship",
    "store_metadata",
    "audio_product",
    "testflight_rc",
]
STATUSES = {"BLOCKED", "EVIDENCE_INSUFFICIENT", "READY", "N_A"}
OWNERS = {"operator", "owner", "shared"}
```

`derive_overall`: if every gate in REQUIRED_GATE_IDS has `status == "READY"` (treat `N_A` as satisfied for overall only if present), return `LAUNCH_READY`; else `LAUNCH_BLOCKED`. Spec seed has no N_A; for v1: only `READY` counts as ready; `N_A` counts as satisfied for overall (optional skip).

`validate_data` checks:

1. `schema_version` present (int >= 1)
2. `gates` is object with all REQUIRED_GATE_IDS
3. Each gate: status in STATUSES, owner in OWNERS, depends_on is list of strings, evidence_paths is list of strings, reason is string
4. For each path in `evidence_paths` (any status): if list non-empty, each path must exist under `root` → else `MISSING_PATH: gate=… path=…`
5. If status == READY:
   - evidence_paths non-empty else `READY_WITHOUT_EVIDENCE: gate=…`
   - tip_sha_short == tip_short else `STALE_TIP: gate=… tip=… current=…`
6. If status == READY: for each dep in depends_on, dep gate status must be READY (or N_A) else `DEPENDENCY: gate=… needs=…`
7. ART_INCONSISTENT: if `art_ship` status is READY:
   - Load `root / "docs/art_qa/art_qa_audit.json"` if present
   - If `ship_gate` is `ART_EVIDENCE_INSUFFICIENT` OR (`ship_gate` in approved set and missing `device_evidence_paths`), emit `ART_INCONSISTENT: …`
   - Approved set: `ART_SHIP_APPROVED`, `ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES` — only allow art_ship READY if art package is approved **and** has non-empty existing device_evidence_paths, **or** launch art_ship evidence_paths alone is insufficient when ship_gate is still insufficient
   - Spec: launch may claim READY only if art-qa would pass for approved. Practical rule:
     - If art `ship_gate` is `ART_EVIDENCE_INSUFFICIENT` or `ART_SHIP_BLOCKED` → cannot have launch `art_ship` READY → `ART_INCONSISTENT`
     - If art `ship_gate` is approved family → require art `device_evidence_paths` non-empty and existing (same as art-qa-check)

`main()`:

```python
def current_tip(root: Path) -> str:
    return subprocess.check_output(
        ["git", "rev-parse", "--short", "HEAD"], cwd=root, text=True
    ).strip()

def main() -> int:
    root = Path(__file__).resolve().parents[1]
    path = root / "docs" / "launch" / "launch_gates.json"
    if not path.is_file():
        print(f"launch-gate-check: FAIL missing {path.relative_to(root)}", file=sys.stderr)
        return 1
    data = json.loads(path.read_text(encoding="utf-8"))
    tip = current_tip(root)
    errors = validate_data(data, root, tip)
    overall = derive_overall(data)
    if errors:
        print("launch-gate-check: FAIL", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        print(f"launch-gate-check: overall={overall} tip={tip}", file=sys.stderr)
        return 1
    # print per-gate one-liners
    gates = data.get("gates") or {}
    for gid in REQUIRED_GATE_IDS:
        g = gates.get(gid) or {}
        print(f"  {gid}: {g.get('status')} tip={g.get('tip_sha_short')}")
    print(f"launch-gate-check: PASS overall={overall} tip={tip}")
    return 0
```

Do **not** fail solely because overall is `LAUNCH_BLOCKED`.

- [ ] **Step 2: Run unit tests — expect PASS**

```bash
python3 scripts/test_validate_launch_gates.py -v
```

Expected: all tests OK. Fix fixtures if tip injection or path assumptions fail.

- [ ] **Step 3: Run checker on real seed — expect PASS + LAUNCH_BLOCKED**

```bash
python3 scripts/validate_launch_gates.py
```

Expected: `launch-gate-check: PASS overall=LAUNCH_BLOCKED tip=<current>`.

If FAIL: fix seed tip_sha_short to current tip or demote fields per honesty rules (seed should already be non-READY so tip mismatch on non-READY must not fail — **only READY gates require tip match**). Confirm implementation does not STALE_TIP non-READY gates.

- [ ] **Step 4: Commit**

```bash
git add scripts/validate_launch_gates.py scripts/testdata/launch scripts/test_validate_launch_gates.py
git commit -m "$(cat <<'EOF'
feat(launch): implement launch-gate-check honesty validator

Enforces evidence paths, tip match, dependencies, ART consistency.
Honest LAUNCH_BLOCKED exits 0.
EOF
)"
```

---

### Task 4: Makefile wiring

**Files:**
- Modify: `Makefile` (`.PHONY` line, new target, `validate` recipe)

**Interfaces:**
- Produces: `make launch-gate-check`
- Consumes: `scripts/validate_launch_gates.py`

- [ ] **Step 1: Edit Makefile**

1. Add `launch-gate-check` to the `.PHONY` list (line 1).
2. After `art-qa-check` target, add:

```makefile
launch-gate-check:
	python3 scripts/validate_launch_gates.py
```

3. Append `launch-gate-check` to the `validate` dependency list **after** `art-qa-check` (and before `test` is fine):

```makefile
validate: version-check privacy-check assets-check sprite-chroma-check audio-check weapon-vfx-check animation-check director-check city-state-check build-engine-check coordination-check story-check interactables-check landmark-check clearing-builds-check city-rules-check challenge-contracts-check unlockables-check art-qa-check launch-gate-check test simulator-test
```

- [ ] **Step 2: Run make target**

```bash
make launch-gate-check
```

Expected: PASS overall=LAUNCH_BLOCKED.

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "$(cat <<'EOF'
build: wire make launch-gate-check into validate

Honesty gate only; does not require LAUNCH_READY.
EOF
)"
```

---

### Task 5: Agent launch playbook

**Files:**
- Create: `docs/launch/AGENT_LAUNCH_PLAYBOOK.md`

**Interfaces:**
- Consumes: gate IDs and checker behavior from Tasks 1–3
- Produces: agent procedure for promote/demote/board update

- [ ] **Step 1: Write playbook**

Create `docs/launch/AGENT_LAUNCH_PLAYBOOK.md` with at least these sections (full prose, not stubs):

1. **Purpose** — agents + board; humans fill evidence  
2. **Machine truth** — `docs/launch/launch_gates.json`, `make launch-gate-check`  
3. **Human evidence surfaces** — table linking each gate to DEVICE_TEST_LOG, ART checklist, APP_STORE_METADATA, audio docs, ART audit  
4. **May / must not** — copy from design §4.3  
5. **After tip moves** — demote READY → EVIDENCE_INSUFFICIENT; run checker until PASS  
6. **After human evidence** — set READY only if checker would pass; for art_ship also update art_qa only under existing art-qa rules  
7. **Board hygiene** — update REPO_STATUS overall + per-gate from checker stdout  
8. **Commands**

```bash
make launch-gate-check
python3 scripts/test_validate_launch_gates.py -v
make art-qa-check
```

- [ ] **Step 2: Commit**

```bash
git add docs/launch/AGENT_LAUNCH_PLAYBOOK.md
git commit -m "$(cat <<'EOF'
docs(launch): agent playbook for gate promote/demote honesty
EOF
)"
```

---

### Task 6: Point human packet + continuation docs

**Files:**
- Modify: `docs/LAUNCH_OPERATOR_PACKET.md`
- Modify: `docs/CONTINUATION_PLAN.md`
- Modify: `docs/CONTINUATION_PROMPT.md`

**Interfaces:**
- Consumes: paths from Tasks 1–5
- Produces: authority links for humans/agents

- [ ] **Step 1: LAUNCH_OPERATOR_PACKET**

Near the top (after Purpose / Authority table), add:

```markdown
## Machine truth (agents)

| Artifact | Role |
| --- | --- |
| [`launch/launch_gates.json`](launch/launch_gates.json) | Per-gate status + evidence pointers |
| [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) | How agents promote/demote without inventing green |
| `make launch-gate-check` | Honesty check (PASS + `LAUNCH_BLOCKED` is normal) |

Human ordered steps below are unchanged. Agents must not mark gates READY without tip-matched evidence paths.
```

Also add `launch-gate-check` to the “Quick repo gates” code block:

```bash
make launch-gate-check art-qa-check assets-check animation-check weapon-vfx-check test
```

- [ ] **Step 2: CONTINUATION_PLAN authority map**

Insert a row after LAUNCH_OPERATOR_PACKET (renumber as needed):

```markdown
| 1b | [`launch/launch_gates.json`](launch/launch_gates.json) · [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) | Machine launch gates + agent promote rules |
```

In dual-lane agent section, add bullet:

```markdown
- `make launch-gate-check` honesty; demote stale READY after tip moves; never invent READY
```

- [ ] **Step 3: CONTINUATION_PROMPT**

In Authority list and make command block, add:

```text
docs/launch/launch_gates.json
docs/launch/AGENT_LAUNCH_PLAYBOOK.md
make launch-gate-check
```

- [ ] **Step 4: Commit**

```bash
git add docs/LAUNCH_OPERATOR_PACKET.md docs/CONTINUATION_PLAN.md docs/CONTINUATION_PROMPT.md
git commit -m "$(cat <<'EOF'
docs: wire launch gates into operator packet and continuation authority
EOF
)"
```

---

### Task 7: REPO_STATUS board rows

**Files:**
- Modify: `docs/REPO_STATUS.md`

**Interfaces:**
- Consumes: live `make launch-gate-check` output + `launch_gates.json`

- [ ] **Step 1: Run checker and capture status**

```bash
make launch-gate-check
python3 -c "import json; d=json.load(open('docs/launch/launch_gates.json')); print(d.get('overall'));
[print(k, v['status']) for k,v in d['gates'].items()]"
```

- [ ] **Step 2: Add Launch gates section**

After Art ship gate section (or near top board), add:

```markdown
## Launch gates (machine)

| Field | Value |
| --- | --- |
| Overall | **LAUNCH_BLOCKED** |
| Check | `make launch-gate-check` |
| Manifest | [`launch/launch_gates.json`](launch/launch_gates.json) |
| Agent playbook | [`launch/AGENT_LAUNCH_PLAYBOOK.md`](launch/AGENT_LAUNCH_PLAYBOOK.md) |

| Gate | Status | Owner |
| --- | --- | --- |
| device_acceptance | EVIDENCE_INSUFFICIENT | operator |
| art_ship | EVIDENCE_INSUFFICIENT | operator |
| store_metadata | BLOCKED | owner |
| audio_product | BLOCKED | owner |
| testflight_rc | BLOCKED | shared |

*Statuses must match `launch_gates.json`. Agents update this table after gate edits.*
```

Refresh tip line if the branch tip moved.

- [ ] **Step 3: Commit**

```bash
git add docs/REPO_STATUS.md
git commit -m "$(cat <<'EOF'
docs: REPO_STATUS launch gates board from machine manifest
EOF
)"
```

---

### Task 8: continue-ss inventory/audit hooks (read-only)

**Files:**
- Modify: `.grok/workflows/continue-ss.rhai`

**Interfaces:**
- Consumes: `docs/launch/launch_gates.json`, `make launch-gate-check`
- Produces: inventory/audit prompts that *read* gates (no auto-edit JSON)

- [ ] **Step 1: Inventory prompt**

In `inv_prompt` required reads, add after art_qa:

```rhai
inv_prompt += "3b. docs/launch/launch_gates.json (overall + per-gate status)\n";
inv_prompt += "3c. make launch-gate-check if feasible (honesty PASS with LAUNCH_BLOCKED is normal)\n";
```

Optionally extend inventory schema with:

```rhai
"launch_overall": #{ "type": "string" },
```

If schema is extended, add `launch_overall` to `required` **or** keep optional (prefer optional to avoid breaking resume). Prefer **optional** property only:

```rhai
"launch_overall": #{ "type": "string" },
```

And instruct: `Return launch_overall from launch_gates.json overall field when present.`

- [ ] **Step 2: Launch audit prompt**

In `p_launch`, add:

```rhai
p_launch += "Also read docs/launch/launch_gates.json and docs/launch/AGENT_LAUNCH_PLAYBOOK.md.\n";
p_launch += "List which machine gates are not READY and their owners. Do not invent READY.\n";
```

- [ ] **Step 3: Gate honesty audit prompt**

Where `p_gate` mentions art-qa, also:

```rhai
p_gate += "Run or reason about make launch-gate-check: PASS+LAUNCH_BLOCKED is healthy; FAIL means lying gates.\n";
```

- [ ] **Step 4: Meta phase detail**

Update inventory phase detail string to mention launch gates:

```rhai
#{ title: "Inventory", detail: "tip SHA, boards, open PRs, art ship_gate, launch_gates" },
```

- [ ] **Step 5: Commit**

```bash
git add .grok/workflows/continue-ss.rhai
git commit -m "$(cat <<'EOF'
workflow: continue-ss reads launch_gates machine truth

Inventory/audit only; no auto-edit of launch_gates.json.
EOF
)"
```

---

### Task 9: End-to-end verification

**Files:**
- None new (maybe touch seed tip if branch tip moved and you store tip on non-READY for clarity only)

- [ ] **Step 1: Unit tests**

```bash
python3 scripts/test_validate_launch_gates.py -v
```

Expected: all pass.

- [ ] **Step 2: make launch-gate-check**

```bash
make launch-gate-check
```

Expected: PASS overall=LAUNCH_BLOCKED.

- [ ] **Step 3: art-qa-check still green**

```bash
make art-qa-check
```

Expected: PASS (unchanged honesty).

- [ ] **Step 4: Prove READY without evidence fails**

```bash
# do not commit this experiment
cp docs/launch/launch_gates.json /tmp/launch_gates.json.bak
python3 - <<'PY'
import json
from pathlib import Path
p = Path("docs/launch/launch_gates.json")
d = json.loads(p.read_text())
d["gates"]["store_metadata"]["status"] = "READY"
d["gates"]["store_metadata"]["evidence_paths"] = []
d["gates"]["store_metadata"]["tip_sha_short"] = "fake"
p.write_text(json.dumps(d, indent=2) + "\n")
PY
make launch-gate-check; echo exit=$?
mv /tmp/launch_gates.json.bak docs/launch/launch_gates.json
make launch-gate-check
```

Expected: first run exit 1 with READY_WITHOUT_EVIDENCE and/or STALE_TIP; after restore exit 0.

- [ ] **Step 5: Confirm no game code**

```bash
git log --oneline origin/main..HEAD 2>/dev/null || git log --oneline -15
git diff origin/main --stat 2>/dev/null | head -40
```

Expected: only docs/scripts/Makefile/workflow paths (plus design/plan if on same branch).

- [ ] **Step 6: Final commit only if tip refresh needed**

If seed tip fields should match HEAD for clarity:

```bash
# update tip_sha_short on non-READY gates to current short SHA if desired
make launch-gate-check
git add docs/launch/launch_gates.json
git commit -m "docs(launch): refresh gate tip fields to current HEAD"
```

Only if you actually changed the file.

---

## Spec coverage checklist (plan self-review)

| Spec requirement | Task |
| --- | --- |
| `docs/launch/launch_gates.json` seed honest blocked | Task 1 |
| Gate model + dependencies | Tasks 1, 3 |
| `scripts/validate_launch_gates.py` honesty rules | Tasks 2–3 |
| PASS ≠ LAUNCH_READY | Tasks 3, 9 |
| STALE_TIP / READY_WITHOUT_EVIDENCE / MISSING_PATH / DEPENDENCY / ART_INCONSISTENT | Tasks 2–3 |
| `make launch-gate-check` + validate | Task 4 |
| Agent playbook | Task 5 |
| LAUNCH_OPERATOR_PACKET pointer | Task 6 |
| CONTINUATION_PLAN / PROMPT | Task 6 |
| REPO_STATUS | Task 7 |
| continue-ss read + report | Task 8 |
| Validator fixtures / tests | Tasks 2, 9 |
| No product code / no fake ART | Global + Task 9 |
| No require LAUNCH_READY in CI | Task 4 |

**Placeholders:** none intentional.  
**Type consistency:** `validate_data` / `derive_overall` / gate IDs stable across tasks.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-26-launch-path.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — execute tasks in this session with executing-plans checkpoints  

Which approach?
