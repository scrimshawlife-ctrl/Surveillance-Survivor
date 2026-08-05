# Hygiene audit — 2026-08-05

**Audit:** C (repo / agent hygiene)  
**Program:** post-merge audit program C→D→B→A  

## Tip freeze

- full: `5e769906d384b66983d6c25bb181b07d2f23bb22`
- short: `5e76990`
- branch: `main`
- status: (clean)
- frozen_at_utc: `2026-08-05T02:36:42Z`

## Machine pack summary

| Check | Result |
| --- | --- |
| version-check | OK app=0.1.0+1 |
| repo-status-check | PASS documented=`12b8c5a` head=`5e76990` (ancestor mode) |
| launch-gate-check | PASS overall=**LAUNCH_BLOCKED** tip=`5e76990` |
| art-qa-check | PASS gate=ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES (audit package commit `0a2a627`) |
| assets-check | Validated **341** RuntimeSprites PNGs |

Launch gates (honest, not READY):

| Gate | Status | Tip |
| --- | --- | --- |
| device_acceptance | EVIDENCE_INSUFFICIENT | f2406fc |
| art_ship | EVIDENCE_INSUFFICIENT | d87be47 |
| store_metadata | EVIDENCE_INSUFFICIENT | 08042d1 |
| audio_product | BLOCKED | None |
| testflight_rc | BLOCKED | None |

## Collaboration inventory

### Open PRs

*(none via `gh pr list`)*

### Open issues

*(none via `gh issue list`)*

### Merged remotes still present

*(none — prior hygiene delete of 17 merged remotes held)*

### Unmerged remotes (count 20; sample)

Historical / unmerged topic remotes remain (not open PRs):  
`agent/fix-landscape-stick-hit`, `agent/new-york-city-environment-pack`, `agent/wp2b-redaction-spoofer`, `codex/debug-regression-hardening`, `cursor/*`, `docs/*`, `feat/art-qa-combat-readability`, `feat/p10-*`, `feat/p8-*`, `fix/*`, `jcode/*` (20 total). Review before delete — may hold unique history.

### Worktrees

| Path | Branch | Note |
| --- | --- | --- |
| primary | `main` @ `5e76990` | ship tip |
| `.worktrees/feat/urban-arena-presentation` | `feat/urban-arena-presentation` | **merged #156**; remote gone; removable |
| `.worktrees/art/prompted-sprite-refresh` | `art/prompted-sprite-refresh` | **merged #159**; remote gone; removable |
| ~15 `~/.jcode/scratch/*` | various | stale side worktrees |
| `Surveillance-Survivor-art`, `-sim-auto` | old agent branches | stale |

### Local branches with gone upstream

**Many** (40+ sample lines): merged topic branches still local with `[gone]` tracking, including worktree-linked `feat/urban-arena-presentation` and `art/prompted-sprite-refresh`. Optional prune; do not delete worktree branches until worktree removed.

## Board vs truth

| Doc | Claim | Actual | Match? |
| --- | --- | --- | --- |
| REPO_STATUS open PRs | none | none | **Y** |
| CONTINUATION_PLAN open PRs | none | none | **Y** |
| CONTINUATION_PROMPT open PRs | none | none | **Y** |
| REPO_STATUS tip field | `12b8c5a` | HEAD `5e76990` | **Partial** (ancestor PASS; tip lag) |
| CONTINUATION board tip | `12b8c5a` | HEAD `5e76990` | **Partial** |
| Hygiene snapshot “main bdf78cc” | art merge tip | HEAD has design/plan/index commits after | **Partial** |
| Safe remote delete list | listed as candidates | already deleted | **Stale list** (cleanup text lag) |
| Worktrees “may remove” | urban/sprite | still present locally | **Y** (honest optional) |

## Findings

| Severity | Claim | Evidence | Disposition |
| --- | --- | --- | --- |
| Medium | Board tip lags HEAD (docs after #156/#159 board pin) | repo-status PASS ancestor; tip `12b8c5a` vs head `5e76990` | refresh tip in Task 2b / end of program |
| Low | REPO_STATUS still lists safe remote deletes already performed | section “Safe remote deletes”; `git branch -r --merged` empty of those | update board text when tip refreshed |
| Low | Merged urban/sprite worktrees still registered | `git worktree list` | owner may `git worktree remove` when convenient |
| Info | 20 unmerged historical remotes remain | `git branch -r --no-merged` | optional archive review; not open PRs |
| Info | Dozens of local `:gone` branches | `git branch -vv` | optional local prune |

## Recommended actions

1. Refresh board tip fields to current HEAD after this audit program’s commits (or at program end).  
2. Optionally remove merged worktrees: urban-arena-presentation, prompted-sprite-refresh.  
3. Optionally prune local `:gone` branches and review 20 unmerged remotes.  
4. Proceed to Audit D (architecture isolation) on freeze tip `5e76990` (or re-freeze if tip moves).

## Non-claims

- No product READY  
- No art quality judgment (Audit B)  
- No isolation judgment (Audit D)  
- No ship freeze decision (Audit A)  
- No invention of gate READY  
