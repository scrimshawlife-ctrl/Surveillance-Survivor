# Collaboration workflow

Use one branch and one worktree for every person or agent working at the same
time. This prevents unstaged edits, build products, and generated files from
colliding.

## Start a change

From the primary checkout on current `main`:

```bash
git fetch origin
git worktree add -b <owner>/<topic> ../Surveillance-Survivor-<owner>-<topic> origin/main
cd ../Surveillance-Survivor-<owner>-<topic>
```

Use a short owner name such as `prabu`, and one focused topic per branch.
Open pull requests against **`main`** (not the retired bootstrap branch).

Historical bootstrap base `agent/iphone-bootstrap` is **retired** — do not open
new work from it.

## While working

- Keep a branch to one issue or work package.
- Do not modify generated Xcode project files; update `project.yml` instead.
- Before editing, check `git status --short` and read `AGENTS.md`.
- Run the narrowest relevant test before handing off.
- Do not rebase, force-push, or merge another contributor's branch without
  explicit approval.

## Handoff and integration

1. Commit the focused change with its tests.
2. Push the branch and open a pull request against `main`.
3. Include changed files, validation evidence, known risks, and any Notion
   discrepancy in the pull-request description.
4. Merge only after review and CI evidence. Remove the worktree only after the
   branch is merged or explicitly abandoned.

## Current workspace assignments

| Collaborator | Agent / identity | Active pattern | Notes |
|---|---|---|---|
| Primary (Daniel) | local / Cursor | `main` + topic branches (e.g. `feat/…`, `docs/…`) | Default integration tip |
| Prabu | topic branches off `main` (e.g. `prabu/animation-…`) | **Active handoff:** remaining animation + isolation law | See [`PRABU_HANDOFF_2026-08-05_animation_isolation.md`](PRABU_HANDOFF_2026-08-05_animation_isolation.md); do not resume `agent/prabu-openclaw` |

Worktrees may read the same repository history but must never share uncommitted
changes.

## Legacy (do not resume)

| Branch | Why retired |
|---|---|
| `agent/iphone-bootstrap` | Early bootstrap lane; hundreds of commits behind `main` |
| `agent/prabu-openclaw` | Abandoned collaborator bootstrap (~461 behind `main` as of 2026-08-04) |

After a topic branch merges, delete the remote branch when convenient so the
assignment table stays honest. Stale merged remotes from the playability stack
are listed in [`CONTINUATION_REPORT_2026-08-04_prabu_hygiene.md`](CONTINUATION_REPORT_2026-08-04_prabu_hygiene.md).
