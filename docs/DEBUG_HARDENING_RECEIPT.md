# Surveillance Survivor — Debug Hardening Receipt

```yaml
campaign: SURVEILLANCE_SURVIVOR_DEBUG_HARDENING_001
baseline_sha: 03708b0b1c8fca1e0520dcd5af23e7dfb39e8fc2
validated_sha: 589bda3bd6f52fdfcd061b067e984aaca12ba168
branch: codex/debug-hardening-presentation-regression
pull_request: 133
status: PARTIAL
execution_surface: connected GitHub repository interface + GitHub-hosted Linux/macOS runners
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
- Added the status guard to `make validate` and GitHub Actions.
- Corrected the PR checkout to `fetch-depth: 0` so ancestry validation runs against complete history rather than a depth-1 synthetic merge checkout.

## Architectural decisions

1. Feature branches may reference an ancestor main baseline; main must exactly match the documented SHA.
2. Status refresh changes only the SHA field and explicitly requires human review of evidence and gate language.
3. Historical device evidence remains SHA-specific and does not prove later rendering revisions.
4. Repository history is part of the status-guard input contract; CI must not weaken the guard to accommodate shallow clones.
5. No launch, ART, device, TestFlight, or production gate was changed.

## GitHub validation evidence

Validation completed against branch SHA `589bda3bd6f52fdfcd061b067e984aaca12ba168`.

- Automation Test Suite run **15**: PASS.
- CI run **824**: PASS.
- Deterministic core and contracts: PASS.
- Repository-status parser tests: PASS.
- Automation-focused deterministic suite: PASS.
- Repository baseline ancestry guard: PASS.
- Asset and presentation validators: PASS.
- XcodeGen project generation: PASS.
- Application unit tests on iPhone Simulator: PASS.
- Simulator launch smoke: PASS.
- Toolchain, logs, `.xcresult`, and smoke evidence uploaded by GitHub Actions.

## Not completed in this execution slice

The connected repository interface supports deterministic file mutation and repository-native CI, but it does not provide a safe interactive macOS checkout for large source refactors. The following source-level work remains open and must not be claimed complete:

- Projector-level camera node tests.
- Typed node-pool reset implementation and reuse tests.
- Explicit full-plate metadata integrated into `VisualAssetMap` and `WorldProjector`.
- Role-specific texture metrics and animation-bank validation.
- `Simulation.fixedStep` validation and tests.
- Physical-device execution and operator visual acceptance.

## Validation state

| Check | State | Evidence |
| --- | --- | --- |
| Repository mutations | PASS | Commits on campaign branch |
| CI workflow syntax/runtime | PASS | Automation Test Suite run 15 |
| Status parser tests | PASS | Deterministic core job |
| Automation suite | PASS | Deterministic core job |
| Repository status guard | PASS | Full-history CI checkout |
| Asset/presentation validators | PASS | macOS simulator contract |
| Application unit tests | PASS | `SurveillanceSurvivorTests` `.xcresult` |
| Simulator smoke | PASS | macOS launch-smoke evidence |
| General CI | PASS | CI run 824 |
| Local `make test` | NOT_RUN | No interactive local checkout in connector |
| Local `make build` | NOT_RUN | No interactive local Xcode environment in connector |
| Local `make validate` | NOT_RUN | Repository-native checks used instead |
| Device test | NOT_RUN | DEVICE_EVIDENCE_NOT_RUN |

## Remaining risks

- Presentation correctness remains dependent on existing implementation until projector and pooling tests are added.
- Asset semantic behavior still uses the existing runtime dimension heuristic until explicit metadata is integrated.
- Invalid `fixedStep` values remain accepted until the core timing guard is implemented.
- Simulator success does not establish physical-device readability, touch, haptics, performance, ART approval, or live extraction acceptance.
- The draft PR must remain unmerged until the remaining source-level work is completed or explicitly split into a reviewed follow-up campaign.

## Publication state

- Changes committed: yes, on the campaign branch.
- Pushed: yes, through the connected GitHub repository interface.
- Pull request: draft PR #133.
- Required GitHub workflows: green at validated SHA.
- Merge: not authorized and not performed.
