# Surveillance Survivor — Debug Hardening Receipt

```yaml
campaign: SURVEILLANCE_SURVIVOR_DEBUG_HARDENING_001
baseline_sha: 03708b0b1c8fca1e0520dcd5af23e7dfb39e8fc2
validated_sha: 3301e6317fff
branch: codex/debug-hardening-validation
status: PARTIAL
execution_surface: local macOS/Xcode simulator checkout
physical_device_evidence: DEVICE_EVIDENCE_NOT_RUN
```

## Objective

Close false-green CI paths and establish machine-enforced continuity before deeper SpriteKit presentation refactoring.

## Implemented

- Expanded pull-request workflow coverage to `Game/**`, `App/**`, `Resources/**`, `docs/**`, and all workflow files.
- Added Linux and Apple toolchain receipts containing the exact commit and available compiler/runtime versions.
- Added asset, sprite-chroma, animation, and weapon/VFX validators to the macOS simulator contract.
- Preserved `.xcresult`, unit-test logs, smoke logs, asset-validation logs, simulator selection, and toolchain output as workflow artifacts.
- Added a branch-aware repository-status baseline guard.
- Added `make repo-status-check` and `make repo-status-refresh`.
- Added parser-level unit coverage for canonical, full-length, malformed, missing, and too-short status SHAs.
- Added the status guard to `make validate` and to GitHub Actions.
- Enforced finite, positive, bounded simulation fixed steps, with deterministic unit coverage.
- Added SpriteKit regression coverage for upright camera bodies, LOS-cone heading, disabled-cone recovery, and typed node-pool reuse.
- Replaced texture-dimension full-plate inference with `VisualAssetMap` rendering semantics.
- Applied the selected player role's display metrics when animation frames swap.
- Strengthened the animation validator to enforce all presentation rules, runtime/scope consistency, normalized anchors, priorities, and actual player multi-frame atlas availability.

## Architectural decisions

1. Feature branches may reference an ancestor main baseline; main must exactly match the documented SHA.
2. Status refresh changes only the SHA field and explicitly requires human review of evidence and gate language.
3. Historical device evidence remains SHA-specific and does not prove later rendering revisions.
4. No launch, ART, device, TestFlight, or production gate was changed.

## Not completed in this execution slice

- Physical-device acceptance: no connected, unlocked iPhone was available on 2026-07-26.
- GitHub Actions evidence for the unpushed local commits: pending publication authorization.

## Validation state

| Check | State | Evidence |
| --- | --- | --- |
| Repository mutations | PASS | `f045552`, `7c9fcfe`, `3301e63` on `codex/debug-hardening-validation` |
| Animation gate | PASS | 27 clips; player multi-frame atlas claims verified |
| `make validate` | PASS | 329 deterministic tests; 4 simulator UI tests; gates remain honest |
| `make build` | PASS | iPhone Simulator build at `3301e63` |
| Simulator smoke | PASS | `CACB3927-A76E-43A5-9ACA-C389EB38C0C3`; `.simulator-smoke/receipt.txt` |
| Device test | NOT_RUN | DEVICE_EVIDENCE_NOT_RUN — no connected physical iPhone |

## Remaining risks

- Hardware/device acceptance remains SHA-specific and cannot be emulated by simulator results.
- Launch stays blocked by existing device acceptance, art evidence, store metadata, audio product, and TestFlight evidence gates.
- The draft PR must remain unmerged until CI is green after publication and owner-gated evidence is supplied.

## Publication state

- Changes committed: yes, on the local validation branch.
- Pushed: no; publication was not authorized in this execution slice.
- Pull request: draft #133 exists, but does not yet contain `3301e63`.
- Merge: not authorized and not performed.
