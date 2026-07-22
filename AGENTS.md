# Surveillance Survivor — Agent Guide

## Mission and authority

Build the iPhone-first *Surveillance Survivor* vertical slice without expanding
scope. The authoritative gameplay state lives in `Sources/SurveillanceCore`;
SpriteKit and SwiftUI project that state but do not mutate it.

For product, platform, and roadmap facts, use the linked Notion sources in
`README.md` as the source of truth. If they conflict with the repository,
report the discrepancy before changing gameplay scope or product claims.

## Repository map

- `Sources/SurveillanceCore/` — deterministic, headless gameplay simulation.
- `Game/` — SpriteKit scene, input, and rendering projection.
- `App/` — SwiftUI shell, lifecycle, and HUD.
- `Tests/` — package and app-facing tests.
- `docs/CONTINUATION_PLAN.md` — sequenced implementation work.
- `docs/ONE_SHOT_EXECUTION.md` — acceptance and verification gates.
- `project.yml` — XcodeGen project authority; do not hand-edit generated project files.

## Working rules

1. Start with `git status --short` and preserve unrelated working-tree changes.
2. Keep the simulation deterministic: inject randomness, use fixed simulation
   time, and add tests for state/event behavior.
3. Treat asset files as projection inputs only. Asset availability must not
   change simulation rules, collision, or entity ownership.
4. Keep the MVP offline: no accounts, backend, telemetry, real surveillance
   feeds, live location, ads, or multiplayer unless explicitly approved.
5. Prefer small, focused commits. Do not push, merge, create releases, or make
   other external changes unless the user explicitly requests it.
6. Do not claim an unverified build, simulator run, device test, asset, or
   Notion fact as complete.

## Concurrent work

Never share one working directory with another person or agent. Use one Git
worktree and one branch per active change. Before starting, claim a focused
area in the pull-request or issue description; avoid editing the same source
file in parallel. Commit completed changes before asking another collaborator
to build on them, then integrate through a pull request or a reviewed merge.

See `docs/COLLABORATION.md` for the standard branch, worktree, and handoff
workflow.

## Validation

Run the narrowest relevant check, then use the full gate for cross-cutting work:

```bash
make test
make build
make validate
```

If `swift` is unavailable on `PATH`, use Xcode's toolchain explicitly:

```bash
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test
```

`make build` requires XcodeGen and an iOS Simulator. Physical-iPhone evidence
is required for changes involving touch reachability, lifecycle, audio,
haptics, accessibility, or performance.

## Handoff format

At the end of a task, state: changed files, validation run and result,
unresolved risks, and whether changes are committed or published.
