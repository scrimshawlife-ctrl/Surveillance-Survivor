# One-Shot Execution Contract

## Authority

The Notion iPhone platform decision and engineering references are canonical. This repository implements them; it does not redefine product scope.

## Build order

1. Establish project generation, app shell, deterministic core, and CI.
2. Complete touch movement, camera, pooling, collision, and pause/resume.
3. Implement the Suspicion visibility graph and tier escalation.
4. Implement the LPR pole transaction and deterministic three-choice upgrades.
5. Add MVP enemies and wave director.
6. Add the Shift Manager and Blind Spot extraction.
7. Add audio, haptics, accessibility, and run receipts.
8. Validate simulator and physical-iPhone evidence.

## Non-negotiable architecture

- Simulation owns authoritative state.
- SpriteKit nodes project state and do not own game truth.
- Fixed timestep is 1/60 second.
- Randomness is seeded and injectable.
- Content is data-driven.
- Backgrounding pauses atomically and cannot duplicate entities.
- No networking, accounts, ads, live location, surveillance feeds, multiplayer, or open world in MVP.

## Completion gate

A physical iPhone must complete a deterministic run from district entry through extraction while maintaining readable controls, correct interruption recovery, no duplicate entities, and acceptable thermal and frame behavior.

## Implementation status vs this contract (reconciled)

This document remains a **historical build-order contract**. Executable truth lives in `main` code and tests. As of the campaign-hardening sprint:

| Build-order step | Code status | Evidence class |
|---|---|---|
| 1 Project, core, CI | Done | CI + `swift test` |
| 2 Touch, camera, pooling, pause | Done | Emulator unit/UI |
| 3 Suspicion tiers | Done | Package tests |
| 4 LPR + upgrades | Done | Package tests |
| 5 Enemies + waves | Done | Package + district profiles |
| 6 Boss + Blind Spot | Done | Emulator extraction smoke |
| 7 Audio + haptics + a11y + receipts | Partial | Haptics live; audio **map only** (no product playback); receipts live |
| 8 Simulator + physical evidence | Partial | Emulator suite green; **physical acceptance still required** |

Do not treat this file as a claim that physical-device acceptance is complete.
