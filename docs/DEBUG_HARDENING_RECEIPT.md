# Surveillance Survivor — Debug Hardening Receipt

```yaml
campaign: SURVEILLANCE_SURVIVOR_DEBUG_HARDENING_001
baseline_sha: 03708b0b1c8fca1e0520dcd5af23e7dfb39e8fc2
branch: codex/debug-hardening-presentation-regression
status: PARTIAL
execution_surface: connected GitHub repository interface
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

## Architectural decisions

1. Feature branches may reference an ancestor main baseline; main must exactly match the documented SHA.
2. Status refresh changes only the SHA field and explicitly requires human review of evidence and gate language.
3. Historical device evidence remains SHA-specific and does not prove later rendering revisions.
4. No launch, ART, device, TestFlight, or production gate was changed.

## Not completed in this execution slice

The connected repository interface supports deterministic file mutation but does not provide a Swift/Xcode execution environment or safe patch-based editing of large source files. The following source-level work remains open and must not be claimed complete:

- Projector-level camera node tests.
- Typed node-pool reset implementation and reuse tests.
- Explicit full-plate metadata integrated into `VisualAssetMap` and `WorldProjector`.
- Role-specific texture metrics and animation-bank validation.
- `Simulation.fixedStep` validation and tests.
- Full local `make test`, `make build`, `make validate`, simulator smoke, and physical-device execution.

## Validation state

| Check | State | Evidence |
| --- | --- | --- |
| Repository mutations | PASS | Commits on campaign branch |
| CI workflow syntax/runtime | PENDING | Draft PR workflow run required |
| Status parser tests | PENDING | GitHub Actions run required |
| `make test` | NOT_RUN | No executable Swift checkout available in connector |
| `make build` | NOT_RUN | No Xcode environment available in connector |
| `make validate` | NOT_RUN | No executable checkout available in connector |
| Simulator smoke | NOT_RUN | Awaiting macOS GitHub Actions runner |
| Device test | NOT_RUN | DEVICE_EVIDENCE_NOT_RUN |

## Remaining risks

- Presentation correctness remains dependent on existing implementation until projector and pooling tests are added.
- Asset semantic behavior still uses existing runtime logic until explicit metadata is integrated.
- The draft PR must remain unmerged until CI is green and source-level work is completed or explicitly split into a follow-up campaign.

## Publication state

- Changes committed: yes, on the campaign branch.
- Pushed: yes, through the connected GitHub repository interface.
- Pull request: pending creation at receipt time.
- Merge: not authorized and not performed.
