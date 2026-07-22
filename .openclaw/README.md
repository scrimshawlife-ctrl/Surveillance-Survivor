# OpenClaw project handoff

This repository is ready to be used as an OpenClaw agent workspace: the
repository-root `AGENTS.md` contains the durable operating instructions.

## Register this project in OpenClaw

On the machine that hosts OpenClaw, create or configure an agent whose
`workspace` is the absolute path to this repository:

```text
/Users/appliedalchemylabs/Documents/Codex/2026-07-22/scrimshawlife-ctrl-surveillance-survivor-https-github/work/Surveillance-Survivor
```

OpenClaw loads workspace-level `AGENTS.md` as project instructions. Give the
agent least-privilege access to this workspace and require confirmation for
network, GitHub writes, and destructive Git operations.

## First task checklist

1. Read `AGENTS.md`, `README.md`, and the relevant document under `docs/`.
2. Inspect `git status --short` before editing.
3. Make a narrowly scoped change in the owning module.
4. Run the appropriate validation command.
5. Report changed files, evidence, risks, and commit/publish status.

No credential, token, channel, or machine-specific OpenClaw configuration is
stored in this repository.
