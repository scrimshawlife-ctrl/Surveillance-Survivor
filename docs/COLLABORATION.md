# Collaboration workflow

Use one branch and one worktree for every person or agent working at the same
time. This prevents unstaged edits, build products, and generated files from
colliding.

## Start a change

From the primary checkout:

```bash
git fetch origin
git worktree add -b agent/<owner>/<topic> ../Surveillance-Survivor-<owner>-<topic> origin/agent/iphone-bootstrap
cd ../Surveillance-Survivor-<owner>-<topic>
```

Use a short owner name such as `prabu`, and one focused topic per branch.

## While working

- Keep a branch to one issue or work package.
- Do not modify generated Xcode project files; update `project.yml` instead.
- Before editing, check `git status --short` and read `AGENTS.md`.
- Run the narrowest relevant test before handing off.
- Do not rebase, force-push, or merge another contributor's branch without
  explicit approval.

## Handoff and integration

1. Commit the focused change with its tests.
2. Push the branch and open a pull request against `agent/iphone-bootstrap`.
3. Include changed files, validation evidence, known risks, and any Notion
   discrepancy in the pull-request description.
4. Merge only after review and CI evidence. Remove the worktree only after the
   branch is merged or explicitly abandoned.

## Current workspace assignments

| Collaborator | Agent | Worktree | Branch |
|---|---|---|---|
| Primary collaborator | local checkout | `work/Surveillance-Survivor` | `agent/iphone-bootstrap` |
| Prabu | `prabu-openclaw` | `work/Surveillance-Survivor-prabu-openclaw` | `agent/prabu-openclaw` |

The two worktrees may read the same repository history but must never share
uncommitted changes.
