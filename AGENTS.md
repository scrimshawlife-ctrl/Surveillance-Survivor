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
- `docs/AUDIO_ASSET_PRODUCTION_BIBLE.md` — canonical ElevenLabs creative inventory, prompts, city packages, reuse rules, and integration gates.
- `docs/AUDIO_ASSET_MANIFEST.json` — machine-readable audio work queue and status authority.
- `docs/AUDIO_AGENT_EXECUTION.md` — required remote-agent workflow, receipts, directories, and validation sequence.
- `docs/WEAPON_SYSTEM_DESIGN.md` — canonical six-countermeasure gameplay and upgrade architecture.
- `docs/WEAPON_VFX_ASSET_PRODUCTION.md` — canonical weapon, projectile, deployable, and combat-FX visual production specification.
- `docs/WEAPON_VFX_ASSET_MANIFEST.json` — machine-readable weapon/VFX generation queue and integration status.
- `project.yml` — XcodeGen project authority; do not hand-edit generated project files.

## Audio authority and audit rules

1. Audit `docs/AUDIO_ASSET_PRODUCTION_BIBLE.md`, `docs/AUDIO_ASSET_MANIFEST.json`, and `docs/AUDIO_AGENT_EXECUTION.md` before proposing, generating, renaming, or integrating audio.
2. Run `make audio-check` before and after audio-related work.
3. The 11 stems in `Sources/SurveillanceCore/Resources/Content/audio_events.json` are the only currently runtime-addressable product cues unless code, catalog entries, and tests are extended together.
4. Entries marked production-required, reserved, or `missing` are requirements, not proof that binary assets or runtime hooks exist.
5. Reuse and hash-audit existing audio before generation. Do not create a second file for the same semantic role under a different city or filename.
6. Use approved prior-city audio as explicit callbacks in Atlanta rather than regenerating imitations.
7. Preserve exact logical stems for runtime-required cues. Missing audio must remain silent and must never alter deterministic simulation behavior.
8. ElevenLabs outputs require provenance, license, prompt, format, loudness, hashes, and integration metadata before they are considered intake-ready.
9. Update the manifest status and batch receipt in the same change as any binary intake or runtime integration.
10. Never claim `runtime_integrated` for a reserved asset without a deterministic source event, catalog entry, app projection, and tests.

## Weapon and VFX authority and audit rules

1. Read `docs/WEAPON_SYSTEM_DESIGN.md`, `docs/WEAPON_VFX_ASSET_PRODUCTION.md`, and `docs/WEAPON_VFX_ASSET_MANIFEST.json` before generating or integrating weapon visuals.
2. Do not invent weapons, payloads, synergies, fields, or status mechanics outside the canonical six-countermeasure roster.
3. The only currently registered weapon visual roles are `projectile_default`, `deployable_mirror_array`, and `deployable_signal_flood`. Reserved manifest entries are not runtime-integrated until namespace, visual map, projection, binaries, and tests change together.
4. Inventory and SHA-256 audit existing visual files before generation. Reject exact and semantic duplicates.
5. Base weapon assets are shared across all cities. Do not create city-specific projectile or deployable packs.
6. Collision, damage radius, field radius, targeting, cadence, and status duration remain simulation authority and must never derive from image bounds or animation timing.
7. Preserve shape-node fallbacks until each binary passes intake, simulator, and physical-device readability gates.
8. Reduced-flash variants are mandatory for Signal Flood, reflection, critical impacts, boss pulses, and Blind Spot opening.
9. Update the machine manifest with status, dimensions, anchors, frame count, prompt provenance, license, hash, and integration target whenever an asset is accepted.

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
make audio-check
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
haptics, accessibility, performance, or maximum-density visual readability.

## Handoff format

At the end of a task, state: changed files, validation run and result,
unresolved risks, and whether changes are committed or published. Audio work
must additionally list manifest IDs, ElevenLabs provenance, reused or rejected
duplicates, master/delivery hashes, and device evidence status. Weapon/VFX work
must list manifest IDs, source prompts, frame/canvas/anchor metadata, reuse or
rejection decisions, binary hashes, reduced-flash status, runtime-role changes,
and maximum-density device evidence status.
