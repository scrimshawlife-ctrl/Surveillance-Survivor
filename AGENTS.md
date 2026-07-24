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
- **`docs/AUDIO_PLAN.md` — START HERE for all audio work** (status, batch order, 11 stems, links).
- `docs/AUDIO_AGENT_EXECUTION.md` — remote-agent audio workflow, batches 0–14, receipts, directories.
- `docs/AUDIO_ASSET_MANIFEST.json` — machine-readable audio work queue and status authority.
- `docs/AUDIO_ASSET_PRODUCTION_BIBLE.md` — ElevenLabs prompts, city packages, reuse, loudness.
- `docs/AUDIO_EVENT_MAP.md` — simulation-event → audio-cue contract.
- `docs/audio/` — Batch 0+ inventory, dedup reports, work receipts (`docs/audio/README.md`).
- `Resources/Audio/` — masters and delivery trees (empty until Batch 1); never put media in `SurveillanceCore`.
- `docs/WEAPON_SYSTEM_DESIGN.md` — canonical six-countermeasure gameplay and upgrade authority.
- `docs/WEAPON_VFX_ASSET_PRODUCTION.md` — canonical projectile/deployable/FX creative and intake contract.
- `docs/WEAPON_VFX_ASSET_MANIFEST.json` — machine-readable weapon/VFX work queue and status authority.
- `docs/WEAPON_VFX_AGENT_EXECUTION.md` — required remote-agent weapon/VFX workflow and receipts.
- `docs/weapon_vfx/` — Batch 0+ inventory, dedup, and receipts (run Batch 0 before generating P0 art).
- **`docs/GAMEPLAY_ANIMATION_PLAN.md` — START HERE for motion / physics-informed presentation**.
- `docs/GAMEPLAY_ANIMATION_PHYSICS_PRODUCTION.md` — animation physics doctrine (not unrestricted sim).
- `docs/GAMEPLAY_ANIMATION_MANIFEST.json` — animation clip queue and status authority.
- `docs/GAMEPLAY_ANIMATION_AGENT_EXECUTION.md` — remote-agent animation batches and receipts.
- `project.yml` — XcodeGen project authority; do not hand-edit generated project files.

## Audio authority and audit rules

1. Open **`docs/AUDIO_PLAN.md` first**, then audit `docs/AUDIO_ASSET_PRODUCTION_BIBLE.md`, `docs/AUDIO_ASSET_MANIFEST.json`, `docs/AUDIO_AGENT_EXECUTION.md`, and `docs/audio/` before proposing, generating, renaming, or integrating audio.
2. Run `make audio-check` before and after audio-related work.
3. The 11 stems in `Sources/SurveillanceCore/Resources/Content/audio_events.json` are the only currently runtime-addressable product cues unless code, catalog entries, and tests are extended together.
4. Entries marked production-required, reserved, or `missing` are requirements, not proof that binary assets or runtime hooks exist.
5. Reuse and hash-audit existing audio before generation. Do not create a second file for the same semantic role under a different city or filename.
6. Use approved prior-city audio as explicit callbacks in Atlanta rather than regenerating imitations.
7. Preserve exact logical stems for runtime-required cues. Missing audio must remain silent and must never alter deterministic simulation behavior.
8. ElevenLabs outputs require provenance, license, prompt, format, loudness, hashes, and integration metadata before they are considered intake-ready.
9. Update the manifest status and batch receipt in the same change as any binary intake or runtime integration.
10. Never claim `runtime_integrated` for a reserved asset without a deterministic source event, catalog entry, app projection, and tests.

## Weapon / VFX authority and audit rules

1. Audit `docs/WEAPON_SYSTEM_DESIGN.md`, `docs/WEAPON_VFX_ASSET_PRODUCTION.md`, `docs/WEAPON_VFX_ASSET_MANIFEST.json`, and `docs/WEAPON_VFX_AGENT_EXECUTION.md` before projectile, deployable, or combat-FX work.
2. Run `make weapon-vfx-check` before and after related changes.
3. Preserve the canonical six countermeasures. Deferred concepts are not approved scope.
4. Only `projectile_default`, `deployable_mirror_array`, and `deployable_signal_flood` are currently runtime-addressable visual stems.
5. Reserved assets require `GameAssetName`, `VisualAssetMap`, projector integration, binaries, and tests in the same bounded change before they may claim runtime integration.
6. Inventory and hash-audit all candidate PNGs before generation. Do not recolor one silhouette and claim distinct weapon identities.
7. Do not create city-specific bullets or city-exclusive weapons.
8. Preserve shape-node fallbacks until owner approval and physical-iPhone readability evidence.
9. Collision, hit radius, range, cadence, damage, and status logic remain simulation-owned and never derive from sprite pixels.
10. Pulse, reflection, and high-luminance effects require reduced-flash alternatives.
11. Update manifest status, prompts, dimensions, anchors, frame order, hashes, provenance, license, and batch receipt in the same change as intake.

## Gameplay animation / physics-informed presentation

1. Open **`docs/GAMEPLAY_ANIMATION_PLAN.md` first**, then the production doctrine, manifest, and agent execution packet.
2. Run `make animation-check` before and after related work.
3. Use **physics-informed animation**, not unrestricted physics simulation. Simulation owns position, velocity, heading, collision, hit timing, damage, and trajectories.
4. SpriteKit may interpolate snapshots and apply **bounded** secondary motion (recoil, springs, wobble, debris, smoke). It must not resolve hits via `SKPhysicsWorld`, animation callbacks, or sprite dimensions.
5. Secondary motion never moves canonical entity positions or changes projectile paths.
6. Prefer authored clips + procedural presentation over physics bodies; physics bodies only for disposable cosmetic debris if used at all.
7. Inventory existing frames and projectors before generating multi-frame banks (Batch 0).
8. Multi-frame expansion must keep shape fallbacks until approved; player feet stay locked to sim position.
9. Reduced-motion and reduced-flash variants are required for telegraphs, pulses, and shake.
10. Do not invent weapons beyond the six countermeasures; align motion with weapon VFX still stems.
11. Update `GAMEPLAY_ANIMATION_MANIFEST.json` status and batch receipts in the same change as clip intake or architecture code that claims integration.

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
make weapon-vfx-check
make animation-check
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
haptics, accessibility, visual density, flash safety, or performance.

## Handoff format

At the end of a task, state: changed files, validation run and result,
unresolved risks, and whether changes are committed or published. Audio work
must additionally list manifest IDs, ElevenLabs provenance, reused or rejected
duplicates, master/delivery hashes, and device evidence status. Weapon/VFX work
must additionally list manifest IDs, source prompts, generator/settings,
dimensions, alpha/color profile, anchors, frame order, reuse decisions, hashes,
namespace/role changes, reduced-flash coverage, and physical-device evidence status.
