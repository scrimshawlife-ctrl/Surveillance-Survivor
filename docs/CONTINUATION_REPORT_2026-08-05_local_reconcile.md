# Local reconcile receipt — 2026-08-05

## Remote sync

- Fetched `origin/main` to `eac0b7c` (Prabu hygiene #158).
- Local had been **ahead 2 / behind 4**.
- Dropped obsolete local board commits (recoverable via reflog / these SHAs):
  - `3f2604c` — docs: reconcile board to main tip 7d5e835 and urban lane
  - `30794bd` — docs: pin board tip after reconcile commit
- Unique content from those commits was **re-applied tip-honestly** on current boards (urban concurrent lane, device evidence table, operator presentation feedback). Stale claims (“no open PRs”, tip `7d5e835`) were **not** restored.

## Untracked work committed (not abandoned)

| Item | Disposition |
| --- | --- |
| `docs/superpowers/plans/2026-08-02-urban-arena-presentation.md` | Committed on main (hash matched urban branch `889ca40`) |
| `.grok/workflows/city-environment-pack.rhai` | Committed on main |
| Root `.device-*.log` / `.launch-smoke-run.log` | Archived → `docs/device_evidence/run_logs/2026-08-01_7c400e7_mechanical_suite/` |
| `.automation-test-results/` (PASS) | Archived → `docs/device_evidence/automation_runs/2026-07-26_ef7d271_passed/` |
| `scripts/__pycache__/*.pyc` | Stopped tracking; gitignored (bytecode, not product work) |

## Still living on other branches (not discarded)

- `feat/urban-arena-presentation` @ `17117b1` / **#156** — full UrbanDress implementation + worktree device-smoke logs
- Satellite plan/spec remain on that branch until #156 merges (also reachable there)
- Open #155 / #159 on their topic branches

## Recovery

```bash
git show 3f2604c
git show 30794bd
# archives
ls docs/device_evidence/run_logs/2026-08-01_7c400e7_mechanical_suite
ls docs/device_evidence/automation_runs/2026-07-26_ef7d271_passed
```
