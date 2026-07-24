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
- `docs/AUDIO_EVENT_MAP.md` — currently implemented simulation-event → audio-cue contract.
- `docs/AUDIO_ASSET_PRODUCTION_BIBLE.md` — canonical ElevenLabs production inventory, prompts, city packages, reuse rules, and integration gates.
- `project.yml` — XcodeGen project authority; do not hand-edit generated project files.

## Audio authority and audit rules

1. Audit `docs/AUDIO_ASSET_PRODUCTION_BIBLE.md` before proposing, generating, renaming, or integrating audio.
2. The 11 stems in `Sources/SurveillanceCore/Resources/Content/audio_events.json` are the only currently runtime-addressable product cues unless code, catalog entries, and tests are extended together.
3. Entries marked production-required or reserved integration are requirements, not proof that binary assets or runtime hooks exist.
4. Reuse and hash-audit existing audio before generation. Do not create a second file for the same semantic role under a different city or filename.
5. Use approved prior-city audio as explicit callbacks in Atlanta rather than regenerating imitations.
6. Preserve exact logical stems for runtime-required cues. Missing audio must remain silent and must never alter deterministic simulation behavior.
7. ElevenLabs outputs require provenance, license, prompt, format, loudness, and integration metadata before they are considered intake-ready.

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
